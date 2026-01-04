from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Machine
from ..schemas import MachineCreate, MachineUpdate, MachineResponse

router = APIRouter()

@router.get("/", response_model=List[MachineResponse])
async def get_machines(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all machines"""
    return db.query(Machine).offset(skip).limit(limit).all()

@router.get("/{machine_id}", response_model=MachineResponse)
async def get_machine(machine_id: int, db: Session = Depends(get_db)):
    """Get specific machine"""
    machine = db.query(Machine).filter(Machine.id == machine_id).first()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")
    return machine
