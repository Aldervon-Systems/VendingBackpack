from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from ..models.transaction import TransactionStatus


class TransactionBase(BaseModel):
    """Base transaction schema"""
    item_id: int
    item_name: str = Field(..., min_length=1, max_length=100)
    slot_number: str = Field(..., min_length=1, max_length=10)
    amount: float = Field(..., gt=0)
    payment_method: Optional[str] = Field(None, max_length=50)
    user_id: Optional[str] = Field(None, max_length=100)


class TransactionCreate(TransactionBase):
    """Schema for creating a transaction"""
    pass


class TransactionResponse(TransactionBase):
    """Schema for transaction response"""
    id: int
    status: TransactionStatus
    created_at: datetime
    completed_at: Optional[datetime]
    
    class Config:
        from_attributes = True
