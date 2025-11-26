from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from ..database import Base

class WarehouseInventory(Base):
    """Warehouse inventory model"""
    __tablename__ = "warehouse_inventory"
    id = Column(Integer, primary_key=True, index=True)
    sku = Column(String(50), nullable=False)
    name = Column(String(100), nullable=False)
    quantity = Column(Integer, default=0)
    location = Column(String(100))
    price = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def __repr__(self):
        return f"<WarehouseInventory {self.sku} ({self.name}) qty={self.quantity}>"
