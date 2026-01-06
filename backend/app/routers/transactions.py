from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ..database import get_db
from ..models import Transaction, Item, TransactionStatus
from ..schemas import TransactionCreate, TransactionResponse

router = APIRouter()


@router.get("/", response_model=List[TransactionResponse])
async def get_transactions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all transactions"""
    transactions = db.query(Transaction).offset(skip).limit(limit).all()
    return transactions


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(transaction_id: int, db: Session = Depends(get_db)):
    """Get a specific transaction"""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction {transaction_id} not found"
        )
    return transaction


@router.post("/", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    transaction: TransactionCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Create a new transaction (purchase)"""
    # Verify item exists and is available
    item = db.query(Item).filter(Item.id == transaction.item_id).first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item {transaction.item_id} not found"
        )
    
    if not item.is_available or item.quantity <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Item {item.name} is not available"
        )
    
    # Attempt to dispense item via hardware
    hardware = request.app.state.hardware
    # Use slot_number from item, as it's the source of truth
    # Convert to int if needed, assuming hardware expects int
    try:
        slot_num = int(item.slot_number)
    except ValueError:
        # If slot is alphanumeric (e.g. "A1"), hardware service needs to handle it
        # For now assuming int based on our models
        slot_num = 0 
        
    dispense_success = await hardware.dispense_item(slot_num)
    
    if not dispense_success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Hardware dispense failed"
        )
    
    # Create transaction
    db_transaction = Transaction(**transaction.model_dump())
    db_transaction.status = TransactionStatus.COMPLETED
    db_transaction.completed_at = datetime.utcnow()
    
    # Decrease item quantity
    item.quantity -= 1
    if item.quantity == 0:
        item.is_available = False
    
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    
    return db_transaction


@router.post("/{transaction_id}/refund", response_model=TransactionResponse)
async def refund_transaction(transaction_id: int, db: Session = Depends(get_db)):
    """Refund a transaction"""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction {transaction_id} not found"
        )
    
    if transaction.status == TransactionStatus.REFUNDED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transaction already refunded"
        )
    
    # Update transaction status
    transaction.status = TransactionStatus.REFUNDED
    
    # Restore item quantity
    item = db.query(Item).filter(Item.id == transaction.item_id).first()
    if item:
        item.quantity += 1
        item.is_available = True
    
    db.commit()
    db.refresh(transaction)
    
    return transaction
