import json
import sqlite3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from pathlib import Path
import os
# sim_engine is imported after DB initialization so it can persist into the 'config' table

DATA_DIR = Path(__file__).parent.parent / 'src' / 'data'
DB_PATH = DATA_DIR / 'vending_machine.db'

# Initialize database
def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT
    )''')
    conn.commit()
    conn.close()

# Helper to load JSON from database
def load_json(key, default=None):
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('SELECT value FROM config WHERE key = ?', (key,))
        row = c.fetchone()
        conn.close()
        if row:
            return json.loads(row[0])
        return default
    except Exception:
        return default

# Helper to save JSON to database
def save_json(key, data):
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)',
                 (key, json.dumps(data, indent=2)))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Error saving {key}: {e}")

# Initialize database on import
init_db()

# Import sim_engine after ensuring DB schema exists so sim_engine can write its initial state
from sim_engine import sim_engine

# Persist daily_stats to DB at startup so frontend can read seeded week data
try:
    save_json('daily_stats', sim_engine.get_weekly_stats())
except Exception:
    pass

class SimpleHandler(BaseHTTPRequestHandler):
    def _set_headers(self, code=200, content_type='application/json'):
        self.send_response(code)
        self.send_header('Content-type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        self.send_header('Access-Control-Allow-Private-Network', 'true')
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        if path == '/machines':
            data = load_json('machines', [])
            self._set_headers()
            self.wfile.write(json.dumps(data).encode())
        elif path == '/locations':
            data = load_json('locations', {})
            self._set_headers()
            self.wfile.write(json.dumps(data).encode())
        elif path == '/history':
            data = load_json('history', [])
            self._set_headers()
            self.wfile.write(json.dumps(data).encode())
        elif path == '/inventory':
            # Serve live inventory from simulation engine, but ensure the
            # persisted 'warehouse' (seed stock) is included so employees
            # see initial warehouse levels before any actions.
            try:
                live = dict(sim_engine.inventory) if isinstance(sim_engine.inventory, dict) else {}
            except Exception:
                live = {}
            # Load persisted inventory blob (may include 'warehouse' and per-machine slots)
            persisted = load_json('inventory', {}) or {}
            # Merge persisted warehouse into live view (persisted takes precedence)
            if isinstance(persisted, dict):
                # Persisted per-machine inventories are stored under 'machines' or as top-level map
                machines_inv = {}
                if 'machines' in persisted and isinstance(persisted['machines'], dict):
                    machines_inv = persisted['machines']
                else:
                    # legacy: persisted may be a map of machineId -> slots
                    for k, v in persisted.items():
                        if k not in ('warehouse',):
                            machines_inv[k] = v

                # Previously we filtered warehouse items to only those SKUs
                # present in machines. That hid newly-added warehouse-only
                # items from manager UI. Return the full persisted warehouse
                # so added items (even if not in any machine) are visible.
                filtered_warehouse = list(persisted.get('warehouse', []))

                # Return the persisted machines as the authoritative top-level map
                # so clients receive the exact persisted machine inventories
                if machines_inv:
                    # Normalize keys (strings) and copy values to avoid mutating persisted data
                    authoritative = {}
                    for k, v in machines_inv.items():
                        try:
                            key = str(k)
                        except Exception:
                            key = k
                        authoritative[key] = v
                    # Replace the live response with authoritative machines map
                    live = dict(authoritative)
                    # Include full persisted warehouse for clients
                    live['warehouse'] = filtered_warehouse
                else:
                    # No persisted machines found — expose full warehouse alongside sim inventory
                    live['warehouse'] = filtered_warehouse
            self._set_headers()
            self.wfile.write(json.dumps(live).encode())
        elif path == '/daily_stats':
            # Expose 7-day aggregated stats from sim engine
            try:
                stats = sim_engine.get_weekly_stats()
            except Exception:
                stats = []
            self._set_headers()
            self.wfile.write(json.dumps(stats).encode())
        elif path == '/warehouse/items':
            # Return the full persisted warehouse list (if any)
            inventory = load_json('inventory', {}) or {}
            wh = []
            if isinstance(inventory, dict) and isinstance(inventory.get('warehouse'), list):
                wh = inventory.get('warehouse')
            self._set_headers()
            self.wfile.write(json.dumps(wh).encode())
        elif path == '/employee_routes':
            # Return persisted employee routes (list) if present
            data = load_json('employee_routes', []) or []
            self._set_headers()
            self.wfile.write(json.dumps(data).encode())
        elif path == '/status':
            machines = load_json('machines', [])
            # Always return all machine IDs as online, normalized as in the data file
            online = [str(m) for m in machines]
            self._set_headers()
            self.wfile.write(json.dumps({'online': online}).encode())
        elif path.startswith('/warehouse/item/'):
            barcode = path.split('/')[-1]
            items = load_json('inventory', {})
            found = None
            try:
                # First check explicit warehouse list if present
                if isinstance(items, dict) and 'warehouse' in items and isinstance(items['warehouse'], list):
                    for slot in items['warehouse']:
                        try:
                            if str(slot.get('sku')) == barcode or str(slot.get('barcode')) == barcode:
                                found = slot
                                break
                        except Exception:
                            continue

                # If not found in warehouse, search persisted machines map
                if not found:
                    machines_inv = None
                    if isinstance(items, dict) and 'machines' in items and isinstance(items['machines'], dict):
                        machines_inv = items['machines']
                    elif isinstance(items, dict):
                        # legacy: top-level keys except 'warehouse' could be machines
                        machines_inv = {k: v for k, v in items.items() if k != 'warehouse'}

                    if isinstance(machines_inv, dict):
                        for mid, slots in machines_inv.items():
                            # slots might be a list of slot-maps, or a dict of sku->entry
                            if isinstance(slots, list):
                                for slot in slots:
                                    try:
                                        if str(slot.get('sku')) == barcode or str(slot.get('barcode')) == barcode:
                                            found = slot
                                            break
                                    except Exception:
                                        continue
                            elif isinstance(slots, dict):
                                # values may be maps or simple quantities
                                for k, v in slots.items():
                                    try:
                                        if str(k) == barcode:
                                            # construct a canonical item object
                                            if isinstance(v, dict):
                                                found = dict(v)
                                                found['sku'] = k
                                            else:
                                                found = {'sku': k, 'qty': v}
                                            break
                                        if isinstance(v, dict) and (str(v.get('sku')) == barcode or str(v.get('barcode')) == barcode):
                                            found = v
                                            break
                                    except Exception:
                                        continue
                            if found:
                                break
            except Exception as e:
                # If any unexpected exception occurs, return 500 with error
                self._set_headers(500)
                resp = {'error': 'server error', 'detail': str(e)}
                try:
                    self.wfile.write(json.dumps(resp).encode())
                except Exception:
                    pass
                return

            self._set_headers(200 if found else 404)
            try:
                self.wfile.write(json.dumps(found or {'error': 'not found'}).encode())
            except Exception:
                # swallow any write errors
                pass
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'not found'}).encode())

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length else b''
        try:
            data = json.loads(post_data.decode()) if post_data else {}
        except Exception:
            data = {}
        if path == '/inventory/fill':
            machine_id = data.get('machineId')
            sku = data.get('sku')
            action = data.get('action')
            if not machine_id:
                self._set_headers(400)
                self.wfile.write(json.dumps({'error': 'machineId required'}).encode())
                return
            # Load persisted inventory and ensure structure
            inventory = load_json('inventory', {}) or {}
            machines_inv = inventory.get('machines') if isinstance(inventory, dict) else None
            if machines_inv is None:
                machines_inv = {}
            # Normalize machine keys to support case-insensitive lookups from clients
            norm_machines = {}
            for k, v in machines_inv.items():
                try:
                    norm_key = str(k).strip().lower()
                except Exception:
                    norm_key = str(k)
                norm_machines[norm_key] = v
            machines_inv = norm_machines
            machine_inv = machines_inv.get(str(machine_id).strip().lower(), [])

            # Helper to decrement warehouse stock for a given sku by amount (max available)
            def _decrement_warehouse(inv_obj, sku_key, amount):
                if not isinstance(inv_obj, dict):
                    return 0
                wh = inv_obj.get('warehouse', [])
                remaining = amount
                for w in wh:
                    if str(w.get('sku')) == str(sku_key) and remaining > 0:
                        available = int(w.get('qty', 0))
                        take = min(available, remaining)
                        if take > 0:
                            w['qty'] = available - take
                            remaining -= take
                return amount - remaining  # how many were successfully taken

            if action == 'row':
                # Fill all slots to capacity; attempt to draw stock from warehouse for each SKU
                for item in machine_inv:
                    cap = int(item.get('cap', item.get('qty', 0)))
                    current = int(item.get('qty', 0))
                    need = max(0, cap - current)
                    if need > 0:
                        taken = _decrement_warehouse(inventory, item.get('sku'), need)
                        item['qty'] = current + taken
                print(f'[Backend] Filled row for machine {machine_id} (drew from warehouse)')
            elif sku:
                # Fill specific SKU: bring it up to its capacity only (draw needed qty from warehouse)
                found = False
                for item in machine_inv:
                    if str(item.get('sku')) == str(sku):
                        found = True
                        current_qty = int(item.get('qty', 0))
                        cap = int(item.get('cap', current_qty))
                        need = max(0, cap - current_qty)
                        if need > 0:
                            # Attempt to take the required amount from warehouse
                            taken = _decrement_warehouse(inventory, sku, need)
                            if taken > 0:
                                item['qty'] = current_qty + taken
                                print(f'[Backend] Filled {sku} on {machine_id}: {current_qty} -> {item["qty"]} (took {taken} from warehouse)')
                            else:
                                print(f'[Backend] No stock in warehouse for {sku} to fill {machine_id}')
                        else:
                            print(f'[Backend] {sku} on {machine_id} already at capacity {cap}')
                        break
                if not found:
                    print(f'[Backend] SKU {sku} not found in machine {machine_id}')
            else:
                self._set_headers(400)
                self.wfile.write(json.dumps({'error': 'sku or action required'}).encode())
                return
            # Persist updated machines inventory back into the inventory blob structure
            inventory['machines'] = machines_inv
            save_json('inventory', inventory)
            # Return the updated inventory blob so clients can update their caches immediately
            try:
                self._set_headers(200)
                self.wfile.write(json.dumps({'ok': True, 'inventory': inventory}).encode())
            except Exception:
                # Fall back to a simple OK
                self._set_headers(200)
                self.wfile.write(json.dumps({'ok': True}).encode())
        elif path == '/employee_routes':
            # Persist published employee routes (list of route objects)
            if data is None:
                self._set_headers(400)
                self.wfile.write(json.dumps({'error': 'expected JSON body'}).encode())
                return
            # Accept either a list or a map; store as-is
            save_json('employee_routes', data)
            self._set_headers(200)
            self.wfile.write(json.dumps({'ok': True}).encode())
        elif path == '/warehouse/item':
            # Add new item to warehouse
            inventory = load_json('inventory', {})
            if 'warehouse' not in inventory:
                inventory['warehouse'] = []
            barcode = data.get('barcode')
            name = data.get('name', '')
            qty = data.get('qty', 0)
            # SKU is the barcode
            item = {
                'sku': barcode,
                'barcode': barcode,
                'name': name,
                'qty': qty
            }
            inventory['warehouse'].append(item)
            save_json('inventory', inventory)
            self._set_headers(200)
            self.wfile.write(json.dumps({'ok': True}).encode())
        elif path == '/warehouse/checkin' or path == '/warehouse/checkout':
            # Not implemented: just echo
            self._set_headers(200)
            self.wfile.write(json.dumps({'ok': True, 'echo': data}).encode())
        elif path.startswith('/inventory/machine/'):
            mid = path.split('/')[-1]
            inventory = load_json('inventory', None)
            if inventory is None:
                self._set_headers(500)
                self.wfile.write(json.dumps({'error': 'Failed to load inventory'}).encode())
                return
            inventory[mid] = data if isinstance(data, list) else []
            save_json('inventory', inventory)
            self._set_headers(200)
            self.wfile.write(json.dumps({'ok': True}).encode())
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'not found'}).encode())

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5050))
    server_address = ('', port)
    sim_engine.start()
    print(f'Starting simple HTTP server on port {port}...')
    httpd = HTTPServer(server_address, SimpleHandler)
    httpd.serve_forever()
