# Warehouse models for inventory, item metadata, and locations
from dataclasses import dataclass, asdict
from typing import List, Optional

@dataclass
class WarehouseItem:
    barcode: str
    name: str
    photo_url: Optional[str]
    locations: List[str]
    qty: int

@dataclass
class WarehouseLocation:
    name: str
    description: Optional[str]
