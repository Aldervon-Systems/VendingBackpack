from flask import Flask, jsonify, request, send_from_directory, abort
import json
import os
from pathlib import Path
import threading
import time
import random
import atexit

HERE = Path(__file__).resolve().parent
DATA_FILE = HERE / 'demo_db.json'
# Serve the built Flutter web output from the repository build directory
# (the build output is at ../build/web relative to this mock_server folder)
STATIC_DIR = (HERE / '..' / 'build' / 'web').resolve()

app = Flask(__name__, static_folder=str(STATIC_DIR), static_url_path='')


@app.after_request
def add_cors_headers(response):
    # Allow local dev origins (wildcard for convenience during demo)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
    return response

# Simulation control
DB_LOCK = threading.Lock()
SIM_THREAD = None
SIM_STOP = threading.Event()

def safe_read_db():
    with DB_LOCK:
        return read_db()

def safe_write_db(obj):
    with DB_LOCK:
        write_db(obj)


def read_db():
    if not DATA_FILE.exists():
        return {"inventory": [], "routes": [], "status": {"hardware":"simulated"}, "daily_stats": {}}
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def write_db(obj):
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=2)


@app.route('/__demo_api/inventory', methods=['GET'])
def get_inventory():
    db = read_db()
    return jsonify(db.get('inventory', []))


@app.route('/__demo_api/_db', methods=['GET'])
def get_full_db():
    return jsonify(read_db())


@app.route('/__demo_api/inventory/fill', methods=['POST'])
def fill_inventory():
    db = read_db()
    payload = request.get_json(silent=True) or {}
    items = payload.get('items') or ([payload] if payload.get('id') else [])
    if not isinstance(items, list):
        return jsonify({'error': 'invalid payload, expected items array or id payload'}), 400

    inv = db.setdefault('inventory', [])
    for it in items:
        # find by id or sku
        found = None
        for x in inv:
            if ('id' in it and x.get('id') == it.get('id')) or ('sku' in it and x.get('sku') == it.get('sku')):
                found = x
                break
        if found:
            if 'qty' in it and isinstance(it['qty'], (int, float)):
                found['qty'] = it['qty']
            if 'add' in it and isinstance(it['add'], (int, float)):
                found['qty'] = (found.get('qty', 0) or 0) + int(it['add'])
        else:
            new = {
                'id': it.get('id') or int(os.times()[4] * 1000) ,
                'sku': it.get('sku', ''),
                'name': it.get('name', 'Unknown'),
                'qty': int(it.get('qty', it.get('add', 0))) if (it.get('qty') is not None or it.get('add') is not None) else 0,
                'price': it.get('price', 0)
            }
            inv.append(new)

    write_db(db)
    return jsonify({'success': True, 'inventory': inv})


@app.route('/__demo_api/status', methods=['GET'])
def status():
    db = read_db()
    out = {'status': db.get('status', {}), 'mode': 'demo'}
    return jsonify(out)


@app.route('/__demo_api/employee_routes', methods=['GET'])
def routes():
    db = read_db()
    return jsonify(db.get('routes', []))


@app.route('/__demo_api/routes', methods=['GET'])
def routes_alias():
    db = read_db()
    return jsonify(db.get('routes', []))


@app.route('/__demo_api/machines', methods=['GET'])
def machines():
    db = read_db()
    return jsonify(db.get('machines', []))


@app.route('/__demo_api/locations', methods=['GET'])
def locations():
    db = read_db()
    return jsonify(db.get('locations', []))


@app.route('/__demo_api/history', methods=['GET'])
def history():
    db = read_db()
    return jsonify(db.get('history', []))


@app.route('/__demo_api/employees', methods=['GET'])
def employees():
    db = safe_read_db()
    return jsonify(db.get('employees', []))


@app.route('/__demo_api/warehouse', methods=['GET'])
def warehouse():
    db = safe_read_db()
    # expose warehouse inventory if present
    return jsonify(db.get('warehouse', { 'inventory': [] }))


@app.route('/__demo_api/warehouse/item/<sku>', methods=['GET'])
def warehouse_item_get(sku):
    db = safe_read_db()
    wh = db.get('warehouse', {})
    inv = wh.get('inventory', [])
    for it in inv:
        if it.get('sku') == sku or str(it.get('id')) == sku:
            return jsonify(it)
    return jsonify({'error': 'not found'}), 404


@app.route('/__demo_api/warehouse/item', methods=['POST'])
def warehouse_item_post():
    payload = request.get_json(silent=True) or {}
    items = payload.get('items') or ([payload] if payload.get('sku') or payload.get('id') else [])
    if not isinstance(items, list):
        return jsonify({'error': 'invalid payload'}), 400

    db = safe_read_db()
    wh = db.setdefault('warehouse', {})
    inv = wh.setdefault('inventory', [])
    changed = False
    for it in items:
        sku = it.get('sku')
        found = None
        for x in inv:
            if (sku and x.get('sku') == sku) or ('id' in it and x.get('id') == it.get('id')):
                found = x
                break
        if found:
            if 'qty' in it and isinstance(it['qty'], (int, float)):
                found['qty'] = int(it['qty'])
                changed = True
            if 'name' in it:
                found['name'] = it['name']
                changed = True
        else:
            new = {
                'id': it.get('id') or int(time.time() * 1000) % 1000000,
                'sku': sku or '',
                'name': it.get('name', 'Unknown'),
                'qty': int(it.get('qty', 0))
            }
            inv.append(new)
            changed = True

    if changed:
        safe_write_db(db)
    return jsonify({'success': True, 'inventory': inv})


@app.route('/__demo_api/warehouse/checkin', methods=['POST'])
def warehouse_checkin():
    payload = request.get_json(silent=True) or {}
    barcode = payload.get('barcode') or payload.get('sku')
    qty = int(payload.get('qty', 0))
    if not barcode or qty <= 0:
        return jsonify({'error': 'invalid payload'}), 400
    db = safe_read_db()
    wh = db.setdefault('warehouse', {})
    inv = wh.setdefault('inventory', [])
    for it in inv:
        if it.get('sku') == barcode or str(it.get('id')) == str(barcode):
            it['qty'] = int(it.get('qty', 0)) + qty
            safe_write_db(db)
            return jsonify({'success': True, 'item': it})
    # if not found, create it
    new = {'id': int(time.time() * 1000) % 1000000, 'sku': barcode, 'name': payload.get('name', 'Unknown'), 'qty': qty}
    inv.append(new)
    safe_write_db(db)
    return jsonify({'success': True, 'item': new})


@app.route('/__demo_api/warehouse/checkout', methods=['POST'])
def warehouse_checkout():
    payload = request.get_json(silent=True) or {}
    barcode = payload.get('barcode') or payload.get('sku')
    qty = int(payload.get('qty', 0))
    if not barcode or qty <= 0:
        return jsonify({'error': 'invalid payload'}), 400
    db = safe_read_db()
    wh = db.setdefault('warehouse', {})
    inv = wh.setdefault('inventory', [])
    for it in inv:
        if it.get('sku') == barcode or str(it.get('id')) == str(barcode):
            current = int(it.get('qty', 0))
            it['qty'] = max(0, current - qty)
            safe_write_db(db)
            return jsonify({'success': True, 'item': it})
    return jsonify({'error': 'not found'}), 404


@app.route('/__demo_api/daily_stats', methods=['GET'])
def daily_stats():
    db = read_db()
    return jsonify(db.get('daily_stats', {}))


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_frontend(path):
    # Serve files from the built flutter web output copied into web/
    if path == '' or path == 'index.html':
        return send_from_directory(str(STATIC_DIR), 'index.html')
    # If the path exists under static dir, serve it
    target = STATIC_DIR / path
    if target.exists():
        return send_from_directory(str(STATIC_DIR), path)
    # fallback to index.html so frontend routing still works
    return send_from_directory(str(STATIC_DIR), 'index.html')


def simulation_loop():
    # configurable intervals (seconds)
    machine_interval = int(os.environ.get('DEMO_MACHINE_INTERVAL_SEC', '300'))
    warehouse_interval = int(os.environ.get('DEMO_WAREHOUSE_INTERVAL_SEC', '3600'))

    last_machine = time.time()
    last_warehouse = time.time()

    while not SIM_STOP.is_set():
        now = time.time()
        changed = False
        db = safe_read_db()

        # Machine consumption tick
        if now - last_machine >= machine_interval:
            last_machine = now
            # For each machine, decrement one item if available
            machines = db.get('machines', [])
            inv = db.setdefault('inventory', [])
            history = db.setdefault('history', [])
            for m in machines:
                mid = m.get('id')
                # find first inventory item at this machine with qty > 0
                for item in inv:
                    # items may have 'location' == machine id
                    if item.get('location') == mid and int(item.get('qty', 0)) > 0:
                        item['qty'] = int(item.get('qty', 0)) - 1
                        changed = True
                        history.append({
                            'ts': int(time.time()),
                            'type': 'consumption',
                            'machine_id': mid,
                            'sku': item.get('sku'),
                            'qty': 1
                        })
                        break

        # Warehouse replenish tick
        if now - last_warehouse >= warehouse_interval:
            last_warehouse = now
            wh = db.setdefault('warehouse', {})
            wh_inv = wh.setdefault('inventory', [])
            # simple replenish: add 100 to each warehouse SKU, or add from master inventory
            if not wh_inv:
                # initialize warehouse with a copy of inventory SKUs but larger qty
                for it in db.get('inventory', []):
                    # only create one warehouse record per sku
                    if any(x.get('sku') == it.get('sku') for x in wh_inv):
                        continue
                    wh_inv.append({
                        'sku': it.get('sku'),
                        'name': it.get('name'),
                        'qty': 200
                    })
                    changed = True
            else:
                for wit in wh_inv:
                    # add a batch
                    add_amt = int(os.environ.get('DEMO_WAREHOUSE_BATCH', '100'))
                    wit['qty'] = int(wit.get('qty', 0)) + add_amt
                    changed = True
            # record warehouse event
            hist = db.setdefault('history', [])
            hist.append({
                'ts': int(time.time()),
                'type': 'warehouse_replenish',
                'added': True
            })

        if changed:
            safe_write_db(db)

        # sleep a short while to be responsive to stop events
        SIM_STOP.wait(1)


def start_simulation():
    global SIM_THREAD
    if SIM_THREAD is not None and SIM_THREAD.is_alive():
        return
    # initialize DB: populate route stops and ensure machine inventory and warehouse
    try:
        initialize_demo_db()
    except Exception:
        pass
    SIM_THREAD = threading.Thread(target=simulation_loop, daemon=True)
    SIM_THREAD.start()


def initialize_demo_db():
    db = safe_read_db()
    changed = False
    machines = db.get('machines', [])
    routes = db.get('routes', [])
    inv = db.setdefault('inventory', [])

    # Auto-generate routes if missing/empty or if forced by env var
    employees = db.get('employees', [])
    force_routing = os.environ.get('DEMO_FORCE_ROUTING', '')
    need_routing = (not routes) or any(not r.get('stops') for r in routes) or force_routing == '1'
    if machines and employees and need_routing:
        # create up to 5 routes assigned to first 5 employees (or fewer employees available)
        num_routes = 5
        num_employees = min(len(employees), num_routes)
        # build fresh routes list
        new_routes = []
        for i in range(num_routes):
            emp = employees[i % len(employees)]
            new_routes.append({
                'id': i + 1,
                'name': f'Route {i+1}',
                'employee_id': emp.get('id'),
                'assigned_to': emp.get('id'),
                'stops': []
            })

        # distribute machines across routes evenly
        stop_id = 1000
        for idx, m in enumerate(machines):
            route_idx = idx % num_routes
            stop_id += 1
            new_routes[route_idx]['stops'].append({
                'id': stop_id,
                'label': f'Stop {stop_id}',
                'machine_id': m.get('id')
            })

        db['routes'] = new_routes
        routes = db['routes']
        changed = True

    # ensure each machine has at least one inventory item
    for m in machines:
        mid = m.get('id')
        has = any(it.get('location') == mid for it in inv)
        if not has:
            # create a couple of SKUs for this machine
            inv.append({'id': int(time.time() * 1000) % 1000000, 'sku': f'{mid}_S1', 'name': 'Snack', 'qty': random.randint(5, 20), 'price': 1.5, 'location': mid})
            inv.append({'id': int(time.time() * 1000) % 1000000 + 1, 'sku': f'{mid}_S2', 'name': 'Drink', 'qty': random.randint(5, 20), 'price': 2.0, 'location': mid})
            changed = True

    # ensure warehouse inventory exists and home base is Durham
    wh = db.setdefault('warehouse', {})
    wh.setdefault('address', 'Durham, NH')
    wh_inv = wh.setdefault('inventory', [])
    if not wh_inv:
        # seed warehouse with unique SKUs from inventory (larger qty)
        skus = {}
        for it in inv:
            sku = it.get('sku')
            if sku and sku not in skus:
                skus[sku] = it.get('name', sku)
        for sku, name in skus.items():
            wh_inv.append({'sku': sku, 'name': name, 'qty': 500})
        changed = True

    # ensure status home base points to Durham
    status = db.setdefault('status', {})
    if status.get('home_base') != 'Durham, NH':
        status['home_base'] = 'Durham, NH'
        changed = True

    if changed:
        safe_write_db(db)


def stop_simulation():
    SIM_STOP.set()
    if SIM_THREAD is not None:
        SIM_THREAD.join(timeout=2)

atexit.register(stop_simulation)


if __name__ == '__main__':
    # Useful for local development. Honor PORT env var so container can run on different ports.
    import os
    port = int(os.environ.get('PORT', '80'))
    # start background demo simulation (intervals configurable via env vars)
    try:
        start_simulation()
        print('demo: simulation thread started')
    except Exception as e:
        print('demo: failed to start simulation thread', e)

    app.run(host='0.0.0.0', port=port)
