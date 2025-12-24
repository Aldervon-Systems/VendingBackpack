#!/usr/bin/env python3
"""Generate a mock demo DB with 50 machines (Manchester, NH) and 5 employees."""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / 'demo_db.json'

center_lat = 42.9956
center_lng = -71.4548

machines = []
locations = []
inventory = []
history = []

# create 50 machines with incremental offsets
for i in range(1, 51):
    mid = f"machine_{i}"
    lat = round(center_lat + ((i % 7) - 3) * 0.0009, 6)
    lng = round(center_lng + ((i % 11) - 5) * 0.0011, 6)
    machines.append({"id": mid, "label": f"Machine {i}", "lat": lat, "lng": lng})
    locations.append({"id": mid, "label": f"Machine {i}", "lat": lat, "lng": lng})
    # add two SKUs per machine
    inventory.append({"id": i * 1000 + 1, "sku": f"{mid}_S1", "name": "Snack", "qty": 10 + (i % 5) * 3, "price": 1.5, "location": mid})
    inventory.append({"id": i * 1000 + 2, "sku": f"{mid}_S2", "name": "Drink", "qty": 8 + (i % 4) * 2, "price": 2.0, "location": mid})

# five employees based in Manchester
employees = []
for j in range(1, 6):
    eid = f"emp_{j}"
    employees.append({
        "id": eid,
        "email": f"{eid}@example.com",
        "role": "employee",
        "name": f"Employee {j}",
        "residence": {"address": "Manchester, NH", "lat": round(center_lat + (j - 3) * 0.0012, 6), "lng": round(center_lng + (j - 3) * 0.0016, 6)}
    })

# create 5 routes assigned to 5 employees, distribute machines evenly
routes = []
for r in range(5):
    stops = []
    for idx, m in enumerate(machines):
        if idx % 5 == r:
            stops.append({"id": 1000 + idx + 1, "label": f"Stop {1000 + idx + 1}", "machine_id": m['id']})
    routes.append({"id": r + 1, "name": f"Route {r+1}", "employee_id": employees[r]['id'], "assigned_to": employees[r]['id'], "stops": stops})

# warehouse seed
warehouse = {"address": "Manchester, NH", "inventory": []}
skus = {}
for it in inventory:
    sku = it['sku']
    if sku not in skus:
        skus[sku] = it['name']
for sku, name in list(skus.items())[:10]:  # seed a few SKUs to keep file small
    warehouse['inventory'].append({"sku": sku, "name": name, "qty": 500})

# status
status = {"hardware": "simulated", "home_base": "Manchester, NH"}

db = {
    "inventory": inventory,
    "machines": machines,
    "locations": locations,
    "history": history,
    "employees": employees,
    "routes": routes,
    "warehouse": warehouse,
    "status": status,
    "daily_stats": {}
}

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2)

print(f"Wrote {OUT} with {len(machines)} machines and {len(employees)} employees")
