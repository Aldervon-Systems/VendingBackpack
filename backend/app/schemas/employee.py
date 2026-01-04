from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class EmployeeBase(BaseModel):
    name: str
    department: Optional[str] = None
    location: Optional[str] = None
    floor: Optional[int] = None
    building: Optional[str] = None
    is_active: bool = True

class EmployeeCreate(EmployeeBase):
    pass

class EmployeeUpdate(BaseModel):
    name: Optional[str] = None
    department: Optional[str] = None
    location: Optional[str] = None
    is_active: Optional[bool] = None

class EmployeeResponse(EmployeeBase):
    id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class EmployeeRouteBase(BaseModel):
    employee_id: int
    machine_id: int
    route_date: datetime
    notes: Optional[str] = None

class EmployeeRouteCreate(EmployeeRouteBase):
    pass

class EmployeeRouteResponse(EmployeeRouteBase):
    id: int
    distance_meters: float
    duration_seconds: float

    class Config:
        from_attributes = True
