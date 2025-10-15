#!/usr/bin/env python3
"""Seed the backend sqlite DB with machines, locations, inventory (including a populated warehouse)
and employee routes.

Run from the project root like:
  python3 backend/seed_data.py
"""
import json
import sqlite3
import random
from pathlib import Path

ROOT = Path(__file__).parent
DATA_DIR = ROOT.parent / 'src' / 'data'
DB_PATH = DATA_DIR / 'vending_machine.db'

DATA_DIR.mkdir(parents=True, exist_ok=True)

# Seed 20 machines
machines = [f"machine{i+1}" for i in range(20)]
machine_objs = [{"id": m, "name": f"Site {i+1}"} for i, m in enumerate(machines)]

# Seed locations for each machine (Manchester-ish coordinates, distinct)
locations = []

# Real Manchester, NH locations (addresses and coordinates)
real_manchester_locations = [
    {"name": "Manchester City Hall", "lat": 42.9917, "lng": -71.4636},
    {"name": "SNHU Arena", "lat": 42.9891, "lng": -71.4637},
    {"name": "Currier Museum of Art", "lat": 43.0040, "lng": -71.4637},
    {"name": "Veterans Memorial Park", "lat": 42.9907, "lng": -71.4622},
    {"name": "Market Basket", "lat": 42.9762, "lng": -71.4552},
    {"name": "The Foundry Restaurant", "lat": 42.9896, "lng": -71.4612},
    {"name": "Verizon Wireless Arena", "lat": 42.9891, "lng": -71.4637},
    {"name": "Elm Street School", "lat": 42.9952, "lng": -71.4567},
    {"name": "Manchester Public Library", "lat": 42.9912, "lng": -71.4617},
    {"name": "St. Joseph Cathedral", "lat": 42.9918, "lng": -71.4628},
    {"name": "Derryfield Park", "lat": 43.0082, "lng": -71.4482},
    {"name": "Livingston Park", "lat": 43.0122, "lng": -71.4632},
    {"name": "Puritan Backroom Restaurant", "lat": 43.0087, "lng": -71.4487},
    {"name": "Mall of New Hampshire", "lat": 42.9584, "lng": -71.4352},
    {"name": "McIntyre Ski Area", "lat": 43.0086, "lng": -71.4481},
    {"name": "Manchester-Boston Regional Airport", "lat": 42.9326, "lng": -71.4357},
    {"name": "Southern NH University", "lat": 42.9906, "lng": -71.4637},
    {"name": "Northeast Delta Dental Stadium", "lat": 42.9837, "lng": -71.4651},
    {"name": "SEE Science Center", "lat": 42.9932, "lng": -71.4612},
    {"name": "Amoskeag Fishways", "lat": 43.0032, "lng": -71.4742},
]

locations = []
for i, m in enumerate(machines):
    loc = real_manchester_locations[i % len(real_manchester_locations)]
    locations.append({
        "id": m,
        "name": loc["name"],
        "lat": loc["lat"],
        "lng": loc["lng"],
    })

# Seed warehouse SKUs (prefer real product data if present)
warehouse = []
# Build a SKU->name map from any provided src inventory so we can map item_1..item_8 to real names
name_map = {}
try:
    src_inv = json.load(open(ROOT.parent / 'src' / 'data' / 'inventory.json'))
    if isinstance(src_inv, dict):
        # Collect explicit warehouse items
        for it in src_inv.get('warehouse', []) or []:
            try:
                sku = str(it.get('sku') or it.get('barcode') or '')
                name = it.get('name') or sku
                qty = int(it.get('qty', 0))
                cap = int(it.get('cap', 500)) if 'cap' in it else 500
                warehouse.append({'sku': sku, 'name': name, 'qty': qty, 'cap': cap})
                if sku:
                    name_map[sku] = name
            except Exception:
                continue

        # Also inspect persisted per-machine entries to pick up names for item_* SKUs
        for k, v in src_inv.items():
            if k == 'warehouse':
                continue
            # machines entries may be lists of slots
            if isinstance(v, list):
                for slot in v:
                    try:
                        s = str(slot.get('sku') or '')
                        n = slot.get('name')
                        if s and n:
                            name_map[s] = n
                    except Exception:
                        continue
except Exception:
    # no src inventory; name_map stays empty and warehouse remains []
    pass

# Ensure item_1..item_8 are present only when we can give them real names (avoid "Item X" placeholders)
sku_names = [f"item_{i+1}" for i in range(8)]
for sku in sku_names:
    # If src data provides a name for this sku, seed it with a random qty; otherwise skip
    if sku in name_map:
        warehouse.append({
            'sku': sku,
            'name': name_map.get(sku),
            'qty': random.randint(80, 200),
            'cap': 500,
        })

# Seed per-machine inventory (8 slots each) - random low stock so restock UI triggers
inventory_map = {}
# If we have a non-empty warehouse, use its SKUs for machine slots; otherwise fall back to name_map keys or placeholders
if warehouse:
    slot_skus = [w['sku'] for w in warehouse]
elif name_map:
    slot_skus = list(name_map.keys())[:8]
else:
    slot_skus = [f"placeholder_{i+1}" for i in range(8)]
for m in machines:
    slots = []
    for i in range(8):
        sku = slot_skus[i % len(slot_skus)]
        slots.append({
            "sku": sku,
            "name": sku.replace('_', ' ').title(),
            "qty": random.randint(0, 12),
            "cap": 20,
        })
    inventory_map[m] = slots

# Create employee routes: assign all machines to a single employee (manager still must press button to generate in-app)
employee_id = "amanda_jones"
stops = []
for loc in locations:
    stops.append({
        "id": loc['id'],
        "name": loc['name'],
        "lat": loc['lat'],
        "lng": loc['lng'],
    })

employee_routes = [
    {
        "employeeId": employee_id,
        "employeeName": "Amanda Jones",
        "color": "#FFFBBB1D",
        "distanceMeters": 0,
        "durationSeconds": 0,
        "stops": stops,
        "geometry": [],
    }
]


def save_json_to_db(key, obj):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT
    )''')
    c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', (key, json.dumps(obj)))
    conn.commit()
    conn.close()


print(f'Seeding DB at {DB_PATH}')
save_json_to_db('machines', machine_objs)
save_json_to_db('locations', locations)

# Deduplicate warehouse entries by SKU (keep first occurrence)
deduped_wh = []
seen = set()
for it in warehouse:
    try:
        sku = str(it.get('sku') or '')
    except Exception:
        sku = ''
    if sku and sku not in seen:
        deduped_wh.append(it)
        seen.add(sku)

inventory_store = {
    "warehouse": deduped_wh,
    "machines": inventory_map,
}
save_json_to_db('inventory', inventory_store)
save_json_to_db('employee_routes', employee_routes)

print('Seed complete: machines, locations, inventory (warehouse + machines), employee_routes')
