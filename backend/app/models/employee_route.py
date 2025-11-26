from sqlalchemy import Column, Integer, String, DateTime, Float
from sqlalchemy.sql import func
from ..database import Base

class EmployeeRoute(Base):
    """Employee route assignment model"""
    __tablename__ = "employee_routes"
    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, nullable=False)
    machine_id = Column(Integer, nullable=False)
    route_date = Column(DateTime(timezone=True), server_default=func.now())
    distance_meters = Column(Float, default=0.0)
    duration_seconds = Column(Float, default=0.0)
    notes = Column(String(500))

    def __repr__(self):
        return f"<EmployeeRoute emp={self.employee_id} machine={self.machine_id} date={self.route_date}>"
