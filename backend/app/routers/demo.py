from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db, Base, engine
from ..config import settings
from ..utils import seed_demo_data
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/toggle_demo", status_code=status.HTTP_200_OK)
def toggle_demo(enable: bool, db: Session = Depends(get_db)):
    """
    Toggle demo mode. If enabled, reseed the database with demo data.
    """
    settings.DEMO_MODE = enable
    if enable:
        # Drop all tables and recreate for a clean demo environment
        logger.info("🔄 Resetting database for demo mode...")
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        seed_demo_data(db)
        logger.info("✅ Demo mode enabled and database seeded.")
        return {"demo_mode": True, "message": "Demo mode enabled and database seeded."}
    else:
        logger.info("🚫 Demo mode disabled. Please restart backend for full reset.")
        return {"demo_mode": False, "message": "Demo mode disabled. Restart backend for full reset."}
