from fastapi import APIRouter
from ..db.mock_db import db

router = APIRouter()

@router.get("/warehouse")
async def get_inventory():
    return db.get_inventory()

@router.get("/items/{barcode}")
async def get_item(barcode: str):
    # Search all inventories for this barcode
    warehouse = db.get_inventory()
    for mid, items in warehouse.items():
        for item in items:
            if item.get("barcode") == barcode:
                return item
    return {}

@router.get("/daily_stats")
async def get_daily_stats():
    # Mock data for the last 7 days
    return [
        {"day": "2023-10-24", "amount": 150.0},
        {"day": "2023-10-25", "amount": 200.0},
        {"day": "2023-10-26", "amount": 180.0},
        {"day": "2023-10-27", "amount": 220.0},
        {"day": "2023-10-28", "amount": 300.0},
        {"day": "2023-10-29", "amount": 400.0},
        {"day": "2023-10-30", "amount": 350.0},
    ]
