from fastapi import APIRouter
from ..db.mock_db import db

router = APIRouter()

@router.get("/routes")
async def get_routes():
    # Return raw locations for now, representing the 'route'
    # In V1 this was more complex, but for scaffolding we provide the locations.
    return {
        "locations": db.get_locations(),
        "paths": [] # Mock paths if needed
    }

@router.get("/employees")
async def get_employees():
    return db.get_employees()
