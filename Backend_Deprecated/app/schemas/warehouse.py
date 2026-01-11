from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class WarehouseItemBase(BaseModel):
    sku: str
    name: str
    quantity: int = 0
    location: Optional[str] = None
    price: Optional[float] = None

class WarehouseItemCreate(WarehouseItemBase):
    pass

class WarehouseItemUpdate(BaseModel):
    quantity: Optional[int] = None
    location: Optional[str] = None
    price: Optional[float] = None

class WarehouseItemResponse(WarehouseItemBase):
    id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
