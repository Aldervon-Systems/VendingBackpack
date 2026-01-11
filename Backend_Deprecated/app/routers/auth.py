from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..db.mock_db import db

router = APIRouter()

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/token")
async def login(req: LoginRequest):
    user = db.get_user(req.email)
    if not user or user["password"] != req.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Return a mock token and user details
    return {
        "access_token": "mock_token_" + user["id"],
        "token_type": "bearer",
        "user": {
            "name": user["name"],
            "email": user["email"],
            "role": user["role"],
            "id": user["id"]
        }
    }
