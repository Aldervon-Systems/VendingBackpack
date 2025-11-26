from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlalchemy.orm import Session
from sqlalchemy import text
import logging

from .database import engine, Base, get_db, SessionLocal
from .config import settings
from .routers import items, transactions, demo
from .services import HardwareInterface, MockHardwareService, RealHardwareService
from .utils import seed_demo_data

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global hardware instance
hardware: HardwareInterface = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting VendingBackpack Backend...")
    
    # Initialize Database
    Base.metadata.create_all(bind=engine)
    logger.info("📦 Database initialized")
    
    # Initialize Hardware Service
    global hardware
    if settings.DEMO_MODE:
        logger.info("🎮 DEMO MODE ENABLED: Using Mock Hardware")
        hardware = MockHardwareService()
        
        # Seed Demo Data
        db = SessionLocal()
        try:
            seed_demo_data(db)
        finally:
            db.close()
    else:
        logger.info("🔌 REAL MODE: Using Real Hardware Service")
        hardware = RealHardwareService()
    
    await hardware.initialize()
    
    # Inject hardware into app state for routers to access
    app.state.hardware = hardware
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down...")

app = FastAPI(
    title="VendingBackpack API",
    description="Backend API for VendingBackpack",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware - adjust origins for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(items.router, prefix="/api/items", tags=["items"])
app.include_router(transactions.router, prefix="/api/transactions", tags=["transactions"])
app.include_router(demo.router, prefix="/api", tags=["demo"])

@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "VendingBackpack API",
        "demo_mode": settings.DEMO_MODE
    }

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        # Check database connection
        db.execute(text("SELECT 1"))
        
        # Check hardware status
        hw_status = "unknown"
        if hasattr(app.state, 'hardware'):
             # We need to await this if we call it, but we can't await in sync def
             # For simple health check, existence is enough
             hw_status = "initialized"

        return {
            "status": "healthy", 
            "database": "connected",
            "hardware": hw_status,
            "demo_mode": settings.DEMO_MODE
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Service unhealthy: {str(e)}")
