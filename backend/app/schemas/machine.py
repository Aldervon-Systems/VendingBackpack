from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class MachineBase(BaseModel):
    name: str
    location: Optional[str] = None
    is_online: bool = True

class MachineCreate(MachineBase):
    pass

class MachineUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    is_online: Optional[bool] = None

class MachineResponse(MachineBase):
    id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
