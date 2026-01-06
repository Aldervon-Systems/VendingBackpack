import logging
from sqlalchemy.orm import Session
from ..models.item import Item
from ..models.employee import Employee
from ..models.machine import Machine
from ..models.warehouse_inventory import WarehouseInventory
from ..models.employee_route import EmployeeRoute
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

def initialize_demo_data(db: Session):
    """
    Seeds the database with demo/simulation data if empty.
    Used when DEMO_MODE=true.
    """
    logger.info("🎮 DEMO DATA: Checking if seeding is required...")
    
    # 1. Check if data exists - simple check on Items table
    if db.query(Item).first():
        logger.info("🎮 DEMO DATA: Data already exists, skipping seed.")
        return

    logger.info("🎮 DEMO DATA: Seeding fresh simulation data...")

    try:
        # --- Machines ---
        machines = [
            Machine(name="Lobby Vending", location="Main Lobby", is_online=True),
            Machine(name="Break Room 2F", location="2nd Floor Breakroom", is_online=True),
            Machine(name="Gym Vending", location="Basement Gym", is_online=False)
        ]
        db.add_all(machines)
        db.flush() # flush to get IDs if needed

        # --- Items (Inventory in Machine) ---
        items = [
            Item(name="Cola Classic", description="Refreshing cola", price=1.50, quantity=10, slot_number="A1", image_url="https://flaticon.com/soda.png"),
            Item(name="Diet Cola", description="Zero sugar cola", price=1.50, quantity=8, slot_number="A2", image_url="https://flaticon.com/diet-soda.png"),
            Item(name="Lemon Lime", description="Sparkling lemon lime", price=1.50, quantity=5, slot_number="A3", image_url="https://flaticon.com/lemon-lime.png"),
            Item(name="Orange Soda", description="Orange flavored soda", price=1.50, quantity=2, slot_number="A4", image_url="https://flaticon.com/orange.png"),
            
            Item(name="Potato Chips", description="Classic salted chips", price=1.25, quantity=12, slot_number="B1", image_url="https://flaticon.com/chips.png"),
            Item(name="BBQ Chips", description="Spicy BBQ chips", price=1.25, quantity=6, slot_number="B2", image_url="https://flaticon.com/bbq.png"),
            Item(name="Pretzels", description="Salty twists", price=1.00, quantity=9, slot_number="B3", image_url="https://flaticon.com/pretzels.png"),
            Item(name="Popcorn", description="Buttered popcorn", price=1.00, quantity=4, slot_number="B4", image_url="https://flaticon.com/popcorn.png"),
            
            Item(name="Chocolate Bar", description="Deep dark chocolate", price=1.75, quantity=15, slot_number="C1", image_url="https://flaticon.com/choco.png"),
            Item(name="Gummy Bears", description="Fruity gummies", price=1.75, quantity=0, slot_number="C2", is_available=False, image_url="https://flaticon.com/gummy.png"), # Out of stock demo
            Item(name="Protein Bar", description="20g protein", price=2.50, quantity=10, slot_number="C3", image_url="https://flaticon.com/protein.png"),
            Item(name="Energy Drink", description="Maximum power", price=3.00, quantity=7, slot_number="C4", image_url="https://flaticon.com/energy.png"),
        ]
        db.add_all(items)

        # --- Employees ---
        employees = [
            Employee(name="Alice Johnson", department="Logistics", location="Warehouse A", floor=1, building="Main"),
            Employee(name="Bob Smith", department="Maintenance", location="Workshop", floor=0, building="Main"),
            Employee(name="Charlie Davis", department="Logistics", location="Warehouse B", floor=1, building="Annex"),
        ]
        db.add_all(employees)
        db.flush()

        # --- Warehouse Inventory ---
        warehouse_items = [
            WarehouseInventory(sku="SNK-001", name="Cola Classic Case", quantity=50, location="A-12-01", price=12.00),
            WarehouseInventory(sku="SNK-002", name="Diet Cola Case", quantity=30, location="A-12-02", price=12.00),
            WarehouseInventory(sku="SNK-003", name="Potato Chips Box", quantity=100, location="B-05-01", price=15.50),
            WarehouseInventory(sku="SNK-004", name="Chocolate Bar Box", quantity=20, location="C-02-04", price=25.00),
            WarehouseInventory(sku="PRT-001", name="Spare Motor A1", quantity=5, location="D-01-01", price=45.00),
            WarehouseInventory(sku="PRT-002", name="Display Panel", quantity=2, location="D-01-02", price=120.00),
        ]
        db.add_all(warehouse_items)

        # --- Employee Routes (Assignments) ---
        # Assign Alice to check Lobby Vending today
        routes = [
            EmployeeRoute(
                employee_id=employees[0].id, # Alice
                machine_id=machines[0].id,   # Lobby Vending
                route_date=datetime.now(),
                notes="Restock Cola and Chips"
            ),
             EmployeeRoute(
                employee_id=employees[0].id, # Alice
                machine_id=machines[1].id,   # Break Room
                route_date=datetime.now(),
                notes="Check coin mechanism"
            ),
             EmployeeRoute(
                employee_id=employees[1].id, # Bob
                machine_id=machines[2].id,   # Gym
                route_date=datetime.now() + timedelta(days=1), # Tomorrow
                notes="Repair offline status"
            )
        ]
        db.add_all(routes)

        db.commit()
        logger.info("✅ DEMO DATA: Seeding complete!")

    except Exception as e:
        logger.error(f"❌ DEMO DATA: Seeding failed: {str(e)}")
        db.rollback()
