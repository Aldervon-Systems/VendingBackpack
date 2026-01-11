from pathlib import Path
import json
from flask import Flask, jsonify, abort
import importlib._bootstrap_external as _bootstrap_ext
import importlib.util
import threading
import time
import datetime
import random
from warehouse_data import get_item, add_or_update_item, check_in_item, check_out_item
from warehouse_models import WarehouseItem
from flask import request

BASE = Path(__file__).parent
DATA_DIR = BASE.parent / 'src' / 'data'
PYC = BASE / '__pycache__' / 'sales_sim.cpython-313.pyc'

app = Flask('sales_sim_server')


@app.after_request
def _add_cors_headers(response):
    # Allow the local Flutter web dev server (and others) to fetch JSON
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    # Allow Private Network Access requests from browsers (Chrome PNA)
    response.headers['Access-Control-Allow-Private-Network'] = 'true'
    return response


# Handle preflight OPTIONS for any path so browsers performing Private Network
# Access preflight receive the correct headers.
@app.route('/', defaults={'path': ''}, methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def handle_options(path):
    resp = app.make_response('')
    resp.status_code = 200
    # headers are added by after_request
    return resp

# Load static JSON assets
def _load_json(path: Path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        return None

machines = _load_json(DATA_DIR / 'machines.json') or []
locations = _load_json(DATA_DIR / 'locations.json') or {}
history_static = _load_json(DATA_DIR / 'history.json') or []

# Server-side authoritative inventory (in-memory). Keys are normalized machine ids -> list of {sku,name,qty,cap}
# Seeded from a master SKU list and randomized initial stock so frontend can load authoritative data.
MASTER_SKUS = {
    'item_1': 'Coca-Cola Classic',
    'item_2': 'Coca-Cola Zero',
    'item_3': 'Sprite',
    'item_4': 'Diet Coke',
    'item_5': 'Coca-Cola Cherry',
    'item_6': 'Fanta Orange',
    'item_7': 'Minute Maid',
    'item_8': 'Dasani Water',
}
SKU_PRICES = {
    'item_1': 1.50,
    'item_2': 1.50,
    'item_3': 1.25,
    'item_4': 1.50,
    'item_5': 1.75,
    'item_6': 1.25,
    'item_7': 2.00,
    'item_8': 1.00,
}
DEFAULT_CAP = 20

# Normalize helper
def _norm_mid(m):
    try:
        s = m if isinstance(m, str) else str(m)
    except Exception:
        s = str(m)
    return s.strip().lower()

# Initialize in-memory inventory
machines_inventory = {}
def _seed_inventory():
    import random
    for m in machines:
        mid = _norm_mid(m if isinstance(m, str) else (m.get('id') or m.get('machineId') or str(m)))
        rows = []
        for sku, name in MASTER_SKUS.items():
            cap = DEFAULT_CAP
            qty = random.randint(0, cap)
            rows.append({'sku': sku, 'name': name, 'qty': qty, 'cap': cap})
        machines_inventory[mid] = rows


# Load compiled sales_sim module if available
sales_sim = None
if PYC.exists():
    try:
        loader = _bootstrap_ext.SourcelessFileLoader('sales_sim', str(PYC))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        mod = importlib.util.module_from_spec(spec)
        loader.exec_module(mod)
        sales_sim = mod
    except Exception:
        sales_sim = None

# Internal live history used by the server (preferred over static file)
live_sales_history = []
_HISTORY_CAP = 10000

def _now_iso():
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat()

def _make_sale(machine_id):
    # Minimal sale record usable by dashboard repo
    return {
        'machineId': machine_id,
        'sku': 'item_1',
        'qty': 1,
        'amount': round(random.uniform(1.5, 5.0), 2),
        'timestamp': _now_iso(),
    }

def _seed_initial_sales():
    # add one recent sale per machine so they show online immediately
    now = datetime.datetime.utcnow()
    for m in machines:
        try:
            mid = m if isinstance(m, str) else (m.get('id') or m.get('machineId') or str(m))
        except Exception:
            mid = str(m)
        rec = {
            'machineId': mid,
            'sku': 'item_1',
            'qty': 1,
            'amount': round(random.uniform(1.5, 5.0), 2),
            'timestamp': (now - datetime.timedelta(seconds=random.randint(0, 30))).replace(microsecond=0).isoformat(),
        }
        live_sales_history.append(rec)

def _sim_loop(interval_seconds=300):
    # interval_seconds: how often to generate sales (default 300s = 5min)
    while True:
        now = datetime.datetime.utcnow()
        for m in machines:
            try:
                mid = m if isinstance(m, str) else (m.get('id') or m.get('machineId') or str(m))
            except Exception:
                mid = str(m)
            rec = {
                'machineId': mid,
                'sku': 'item_1',
                'qty': 1,
                'amount': round(random.uniform(1.5, 5.0), 2),
                'timestamp': now.replace(microsecond=0).isoformat(),
            }
            live_sales_history.append(rec)
            # cap history
            if len(live_sales_history) > _HISTORY_CAP:
                del live_sales_history[:len(live_sales_history) - _HISTORY_CAP]
        time.sleep(interval_seconds)

@app.route('/machines')
def get_machines():
    return jsonify(machines)

@app.route('/locations')
def get_locations():
    return jsonify(locations)

@app.route('/history')
def get_history():
    # Prefer live history from sales_sim if available
    # Prefer live_sales_history (internal sim), then compiled sales_sim, then static
    if live_sales_history:
        return jsonify(list(live_sales_history))
    if sales_sim is not None:
        try:
            if hasattr(sales_sim, 'init_sales'):
                try:
                    sales_sim.init_sales()
                except Exception:
                    pass
            if hasattr(sales_sim, 'sales_history'):
                try:
                    return jsonify(list(getattr(sales_sim, 'sales_history')))
                except Exception:
                    pass
        except Exception:
            pass
    return jsonify(history_static)


@app.route('/inventory')
def get_inventory():
    # Return authoritative inventory as a map of machineId -> list(rows)
    return jsonify(machines_inventory)


@app.route('/inventory/fill', methods=['POST'])
def post_fill():
    # Accept JSON: {machineId: 'machine_01', sku: 'item_1'} or {machineId: 'machine_01', action: 'row'}
    from flask import request
    try:
        data = request.get_json(force=True)
    except Exception:
        data = None
    if not data or 'machineId' not in data:
        return jsonify({'error': 'missing machineId'}), 400
    mid = _norm_mid(data['machineId'])
    if mid not in machines_inventory:
        return jsonify({'error': 'unknown machineId'}), 404
    # Fill whole row
    if data.get('action') == 'row':
        for r in machines_inventory[mid]:
            r['qty'] = int(r.get('cap', DEFAULT_CAP))
        return jsonify({'ok': True, 'machineId': mid}), 200

    sku = data.get('sku')
    if not sku:
        return jsonify({'error': 'missing sku or action'}), 400
    sku = str(sku).strip().lower()
    for r in machines_inventory[mid]:
        if str(r.get('sku', '')).strip().lower() == sku:
            r['qty'] = int(r.get('cap', DEFAULT_CAP))
            return jsonify({'ok': True, 'machineId': mid, 'sku': sku}), 200
    return jsonify({'error': 'sku not found on machine'}), 404

@app.route('/status')
def get_status():
    # If sales_sim exposes activity info, attempt to use it; otherwise use history window
    online = []
    try:
        # Use live history first, then compiled sales_sim, then static
        hist = []
        if live_sales_history:
            hist = list(live_sales_history)
        else:
            if sales_sim is not None and hasattr(sales_sim, 'sales_history'):
                try:
                    hist = list(getattr(sales_sim, 'sales_history'))
                except Exception:
                    hist = []
        if not hist:
            hist = history_static
        # activity window: last 24 hours
        import datetime
        cutoff = datetime.datetime.utcnow() - datetime.timedelta(hours=24)
        for e in hist:
            if not isinstance(e, dict):
                # try mapping-like objects
                continue
            ts = e.get('timestamp') or e.get('time')
            if not ts:
                continue
            try:
                t = datetime.datetime.fromisoformat(ts)
            except Exception:
                continue
            if t >= cutoff:
                mid = e.get('machineId') or e.get('machine')
                if mid and mid not in online:
                    online.append(mid)
    except Exception:
        pass
    return jsonify({'online': online})

@app.route('/warehouse/item/<barcode>', methods=['GET'])
def warehouse_get_item(barcode):
    item = get_item(barcode)
    if not item:
        return jsonify({'error': 'not found'}), 404
    return jsonify(item.__dict__)

@app.route('/warehouse/item', methods=['POST'])
def warehouse_add_item():
    data = request.get_json(force=True)
    try:
        item = WarehouseItem(**data)
        add_or_update_item(item)
        return jsonify({'ok': True, 'barcode': item.barcode}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/warehouse/checkin', methods=['POST'])
def warehouse_checkin():
    data = request.get_json(force=True)
    barcode = data.get('barcode')
    qty = int(data.get('qty', 0))
    location = data.get('location', '')
    if not barcode or not location or qty <= 0:
        return jsonify({'error': 'missing barcode, location, or qty'}), 400
    ok = check_in_item(barcode, qty, location)
    return jsonify({'ok': ok}), 200 if ok else (jsonify({'error': 'not found'}), 404)

@app.route('/warehouse/checkout', methods=['POST'])
def warehouse_checkout():
    data = request.get_json(force=True)
    barcode = data.get('barcode')
    qty = int(data.get('qty', 0))
    location = data.get('location', '')
    if not barcode or not location or qty <= 0:
        return jsonify({'error': 'missing barcode, location, or qty'}), 400
    ok = check_out_item(barcode, qty, location)
    return jsonify({'ok': ok}), 200 if ok else (jsonify({'error': 'not found or insufficient qty'}), 404)

if __name__ == '__main__':
    # Start internal simulation thread (seed initial sales and then generate per interval)
    try:
        _seed_initial_sales()
        sim_thread = threading.Thread(target=_sim_loop, kwargs={'interval_seconds': 300}, daemon=True)
        sim_thread.start()
    except Exception:
        pass

    # If compiled sales_sim provides its own thread, attempt to start it as well (non-blocking)
    if sales_sim is not None:
        try:
            if hasattr(sales_sim, 'init_sales'):
                try:
                    sales_sim.init_sales()
                except Exception:
                    pass
        except Exception:
            pass
        try:
            if hasattr(sales_sim, 'sales_thread'):
                t = getattr(sales_sim, 'sales_thread')
                try:
                    if hasattr(t, 'start') and not getattr(t, 'is_alive', lambda: False)():
                        t.daemon = True
                        t.start()
                except Exception:
                    pass
        except Exception:
            pass
        try:
            if hasattr(sales_sim, 'simulate_sales'):
                thr = threading.Thread(target=sales_sim.simulate_sales, daemon=True)
                thr.start()
        except Exception:
            pass

    print('Starting Flask server on http://127.0.0.1:5000')
    # Seed server-side inventory
    try:
        _seed_inventory()
    except Exception:
        pass
    app.run(host='0.0.0.0', port=5000)
