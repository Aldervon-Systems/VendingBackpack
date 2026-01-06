from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import WarehouseInventory
from ..schemas import WarehouseItemCreate, WarehouseItemUpdate, WarehouseItemResponse

router = APIRouter()

@router.get("/", response_model=List[WarehouseItemResponse])
async def get_warehouse_inventory(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all warehouse inventory"""
    return db.query(WarehouseInventory).offset(skip).limit(limit).all()

@router.get("/{item_id}", response_model=WarehouseItemResponse)
async def get_warehouse_item(item_id: int, db: Session = Depends(get_db)):
    """Get specific warehouse item"""
    item = db.query(WarehouseInventory).filter(WarehouseInventory.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item
