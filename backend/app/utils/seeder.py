try:
    from sqlalchemy.orm import Session
except ImportError:
    Session = None  # Fallback for environments where SQLAlchemy is not installed
from ..models.item import Item
import logging

logger = logging.getLogger(__name__)

def seed_demo_data(db):
    """
    Populates the database with demo items if it is empty.
    """
    from ..models import Item, Employee, Transaction, TransactionStatus, Machine, WarehouseInventory, EmployeeRoute
    import random
    # Clear existing data for a fresh demo
    db.query(EmployeeRoute).delete()
    db.query(WarehouseInventory).delete()
    db.query(Machine).delete()
    db.query(Transaction).delete()
    db.query(Employee).delete()
    db.query(Item).delete()
    db.commit()

    logger.info("🌱 Seeding database with demo items, employees, machines, warehouse, routes, transactions...")

    # Demo machines
    demo_machines = [
        Machine(name="VM-Alpha", location="HQ Lobby", is_online=True),
        Machine(name="VM-Beta", location="Warehouse Entrance", is_online=True),
        Machine(name="VM-Gamma", location="Cafeteria", is_online=False),
    ]
    for m in demo_machines:
        db.add(m)
    db.commit()

    # Demo items
    demo_items = [
        Item(
            name="Simulation Soda",
            description="Refreshing virtual carbonation. 100% sugar-free (because it's not real).",
            price=1.50,
            quantity=10,
            slot_number="1",
            is_available=True,
            image_url="https://via.placeholder.com/300?text=Soda"
        ),
        Item(
            name="Digital Chips",
            description="Crunchy bytes of salty goodness.",
            price=1.00,
            quantity=15,
            slot_number="2",
            is_available=True,
            image_url="https://via.placeholder.com/300?text=Chips"
        ),
        Item(
            name="Algorithm Apple",
            description="A healthy snack for your neural network.",
            price=0.75,
            quantity=20,
            slot_number="3",
            is_available=True,
            image_url="https://via.placeholder.com/300?text=Apple"
        ),
        Item(
            name="Binary Bar",
            description="Chocolate bar with 1s and 0s.",
            price=1.25,
            quantity=12,
            slot_number="4",
            is_available=True,
            image_url="https://via.placeholder.com/300?text=Choco"
        ),
        Item(
            name="Null Water",
            description="Pure hydration. Contains nothing else.",
            price=2.00,
            quantity=8,
            slot_number="5",
            is_available=True,
            image_url="https://via.placeholder.com/300?text=Water"
        )
    ]
    for item in demo_items:
        db.add(item)
    db.commit()

    # Demo employees
    demo_employees = [
        Employee(name="Alice Smith", department="Ops", location="HQ", floor=1, building="A", is_active=True),
        Employee(name="Bob Jones", department="Logistics", location="Warehouse", floor=0, building="B", is_active=True),
        Employee(name="Charlie Lee", department="Tech", location="HQ", floor=2, building="A", is_active=True),
        Employee(name="Dana Patel", department="Support", location="Remote", floor=None, building="C", is_active=True),
        Employee(name="Evan Green", department="Sales", location="HQ", floor=3, building="A", is_active=True),
    ]
    manager_profile = Employee(name="Morgan Black", department="Management", location="HQ", floor=4, building="A", is_active=True)
    db.add(manager_profile)
    for emp in demo_employees:
        db.add(emp)
    db.commit()

    # Demo warehouse inventory
    demo_warehouse = [
        WarehouseInventory(sku="SODA-001", name="Simulation Soda", quantity=100, location="Aisle 1", price=1.50),
        WarehouseInventory(sku="CHIPS-002", name="Digital Chips", quantity=200, location="Aisle 2", price=1.00),
        WarehouseInventory(sku="APPLE-003", name="Algorithm Apple", quantity=150, location="Aisle 3", price=0.75),
        WarehouseInventory(sku="BAR-004", name="Binary Bar", quantity=120, location="Aisle 4", price=1.25),
        WarehouseInventory(sku="WATER-005", name="Null Water", quantity=80, location="Aisle 5", price=2.00),
    ]
    for wh in demo_warehouse:
        db.add(wh)
    db.commit()

    # Demo employee routes (assign employees to machines)
    demo_routes = []
    for emp in demo_employees:
        assigned_machine = random.choice(demo_machines)
        demo_routes.append(EmployeeRoute(
            employee_id=emp.id,
            machine_id=assigned_machine.id,
            distance_meters=random.uniform(100, 2000),
            duration_seconds=random.uniform(300, 3600),
            notes=f"Route for {emp.name} to {assigned_machine.name}"
        ))
    for route in demo_routes:
        db.add(route)
    db.commit()

    # Demo transactions (simulate sales, refunds, etc)
    demo_transactions = []
    for i in range(20):
        item = random.choice(demo_items)
        emp = random.choice(demo_employees)
        status = random.choice([TransactionStatus.COMPLETED, TransactionStatus.REFUNDED, TransactionStatus.FAILED])
        demo_transactions.append(Transaction(
            item_id=item.id,
            item_name=item.name,
            slot_number=item.slot_number,
            amount=item.price,
            status=status,
            payment_method=random.choice(["cash", "card", "mobile"]),
            user_id=str(emp.id)
        ))
    for tx in demo_transactions:
        db.add(tx)
    db.commit()
    logger.info(f"✅ Seeded {len(demo_items)} items, {len(demo_employees)} employees, {len(demo_machines)} machines, {len(demo_warehouse)} warehouse items, {len(demo_routes)} routes, {len(demo_transactions)} transactions.")
