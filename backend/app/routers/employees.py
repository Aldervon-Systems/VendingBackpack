from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Employee, EmployeeRoute
from ..schemas import EmployeeCreate, EmployeeUpdate, EmployeeResponse, EmployeeRouteResponse

router = APIRouter()

@router.get("/", response_model=List[EmployeeResponse])
async def get_employees(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all employees"""
    return db.query(Employee).offset(skip).limit(limit).all()

@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(employee_id: int, db: Session = Depends(get_db)):
    """Get specific employee"""
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return employee

@router.get("/routes/", response_model=List[EmployeeRouteResponse])
async def get_all_routes(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all route assignments"""
    return db.query(EmployeeRoute).offset(skip).limit(limit).all()

@router.get("/{employee_id}/routes", response_model=List[EmployeeRouteResponse])
async def get_employee_routes(employee_id: int, db: Session = Depends(get_db)):
    """Get routes for specific employee"""
    return db.query(EmployeeRoute).filter(EmployeeRoute.employee_id == employee_id).all()
