# In-memory warehouse inventory and item metadata
from warehouse_models import WarehouseItem
from typing import Dict

# barcode -> WarehouseItem
warehouse_items: Dict[str, WarehouseItem] = {}

def get_item(barcode: str):
    return warehouse_items.get(barcode)

def add_or_update_item(item: WarehouseItem):
    warehouse_items[item.barcode] = item

def check_in_item(barcode: str, qty: int, location: str):
    item = warehouse_items.get(barcode)
    if item:
        item.qty += qty
        if location not in item.locations:
            item.locations.append(location)
        return True
    return False

def check_out_item(barcode: str, qty: int, location: str):
    item = warehouse_items.get(barcode)
    if item and item.qty >= qty:
        item.qty -= qty
        return True
    return False
