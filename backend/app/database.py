import logging
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

# Configure logging
logger = logging.getLogger(__name__)

# Create database engine
# Smart connection string handling (SQLite needs special args)
connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}

try:
    logger.info(f"💾 Creating database engine for: {settings.DATABASE_URL.split('@')[-1] if '@' in settings.DATABASE_URL else 'HIDDEN'}")
    engine = create_engine(
        settings.DATABASE_URL,
        connect_args=connect_args
    )
    logger.info("✅ Database engine created.")
except Exception as e:
    logger.error(f"❌ Failed to create database engine: {str(e)}")
    raise

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()


def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    try:
        logger.info("📦 Checking/Creating database tables...")
        # Import models here to ensure they're registered with Base before create_all
        from . import models
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database initialization complete.")
    except Exception as e:
        logger.error(f"❌ init_db failed: {str(e)}")
        raise
