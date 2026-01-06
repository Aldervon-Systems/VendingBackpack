from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlalchemy.orm import Session
from sqlalchemy import text
import logging
from datetime import datetime

from .database import engine, Base, get_db, SessionLocal, init_db
from .config import settings
from .routers import items, transactions, employees, machines, warehouse
from .services import HardwareInterface, RealHardwareService, MockHardwareService, initialize_demo_data

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

VERSION = "1.1.0-fixed"

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle events for the FastAPI application"""
    logger.info(f"🚀 Starting VendingBackpack Backend {VERSION}...")
    
    # 1. Initialize Database
    try:
        logger.info("💾 Initializing database...")
        init_db()
        logger.info("✅ Database tables verified/created.")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {str(e)}", exc_info=True)
    
    # 2. Hardware Service Setup
    try:
        if settings.DEMO_MODE:
            logger.info("🎮 Running in DEMO_MODE - using MockHardwareService")
            hardware_service = MockHardwareService()
        else:
            logger.info("🔌 Running in PRODUCTION mode - using RealHardwareService")
            hardware_service = RealHardwareService()
            
        await hardware_service.initialize()
        app.state.hardware = hardware_service
        logger.info("✅ Hardware service initialized.")
    except Exception as e:
        logger.error(f"❌ Hardware service initialization failed: {str(e)}", exc_info=True)

    # 3. Seed Demo Data if applicable
    if settings.DEMO_MODE:
        try:
            logger.info("🌱 Seeding demo data...")
            db = SessionLocal()
            initialize_demo_data(db)
            db.close()
            logger.info("✅ Demo data seeded.")
        except Exception as e:
            logger.error(f"❌ Demo data seeding failed: {str(e)}", exc_info=True)

    yield
    logger.info("🛑 Shutting down VendingBackpack Backend...")

app = FastAPI(
    title="VendingBackpack API",
    description="Backend API for VendingBackpack system",
    version=VERSION,
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(items, prefix="/api/items", tags=["items"])
app.include_router(transactions, prefix="/api/transactions", tags=["transactions"])
app.include_router(employees, prefix="/api/employees", tags=["employees"])
app.include_router(machines, prefix="/api/machines", tags=["machines"])
app.include_router(warehouse, prefix="/api/warehouse", tags=["warehouse"])

@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "VendingBackpack API",
        "version": VERSION
    }

@app.get("/health")
async def health_check():
    """Basic health check for external monitors/gateways."""
    return {
        "status": "online",
        "version": VERSION,
        "mode": "demo" if settings.DEMO_MODE else "production",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/debug/health")
async def debug_health(db: Session = Depends(get_db)):
    """Detailed health check for internal diagnostics."""
    health_info = {
        "status": "online",
        "version": VERSION,
        "database": "connected",
        "hardware": "unknown",
        "timestamp": datetime.now().isoformat()
    }
    
    # Check database
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        health_info["database"] = f"error: {str(e)}"
        health_info["status"] = "degraded"

    # Check hardware
    if hasattr(app.state, 'hardware'):
        try:
            hw_status = await app.state.hardware.get_status()
            health_info["hardware"] = hw_status
        except Exception as e:
            health_info["hardware"] = f"error: {str(e)}"
            health_info["status"] = "degraded"
            
    return health_info

@app.post("/api/debug/seed", tags=["debug"])
def force_seed_data(db: Session = Depends(get_db)):
    if not settings.DEMO_MODE:
        raise HTTPException(status_code=400, detail="Only available in DEMO_MODE")
    initialize_demo_data(db)
    return {"message": "Demo data seeded successfully"}
