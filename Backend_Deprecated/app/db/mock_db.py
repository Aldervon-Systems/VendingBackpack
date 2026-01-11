from typing import List, Dict, Optional
import random

class MockDB:
    def __init__(self):
        self.users = [
            {
                "email": "Simon.swartout@gmail.com",
                "name": "Simon Swartout",
                "password": "test123",
                "role": "manager",
                "id": "simon_swartout",
            },
            {
                "email": "amanda.jones@example.com",
                "name": "Amanda Jones",
                "password": "employee123",
                "role": "employee",
                "id": "amanda_jones",
            },
        ]

        self.employees = [
             {
                "id": "amanda_jones",
                "name": "Amanda Jones",
                "color": 0xFF42A5F5, # Blue
            }
        ]

        self.locations = [
            {"id": "M-101", "name": "Boston Common",         "lat": 42.3550, "lng": -71.0656},
            {"id": "M-102", "name": "South Station",         "lat": 42.3523, "lng": -71.0552},
            {"id": "M-103", "name": "Seaport District",      "lat": 42.3521, "lng": -71.0426},
            {"id": "M-104", "name": "TD Garden",             "lat": 42.3662, "lng": -71.0621},
            {"id": "M-105", "name": "North End",             "lat": 42.3651, "lng": -71.0545},
            {"id": "M-106", "name": "Fenway Park",           "lat": 42.3467, "lng": -71.0972},
            {"id": "M-107", "name": "Back Bay (Copley)",     "lat": 42.3493, "lng": -71.0780},
            {"id": "M-108", "name": "MIT (Kendall Sq.)",     "lat": 42.3620, "lng": -71.0912},
            {"id": "M-109", "name": "Logan Terminal A",      "lat": 42.3664, "lng": -71.0200},
            {"id": "M-110", "name": "Harvard (Harvard Sq.)", "lat": 42.3736, "lng": -71.1190},
        ]

        # Inventory: Map of MachineID -> List of Items
        self.inventory: Dict[str, List[Dict]] = {}
        self._seed_inventory()
    
    def _seed_inventory(self):
        products = [
            {"name": "Coke", "sku": "coke_can"},
            {"name": "Sprite", "sku": "sprite_can"},
            {"name": "Water", "sku": "water_bottle"},
            {"name": "Chips", "sku": "chips_bag"},
            {"name": "Candy", "sku": "candy_bar"},
        ]
        
        for loc in self.locations:
            machine_id = loc["id"]
            items = []
            # Randomly add 3-5 products per machine
            num_products = random.randint(3, 5)
            selected_products = random.sample(products, num_products)
            for prod in selected_products:
                items.append({
                    "sku": prod["sku"],
                    "name": prod["name"],
                    "qty": random.randint(1, 20),
                    "barcode": prod["sku"] + "_code"
                })
            self.inventory[machine_id] = items

    def get_user(self, email: str) -> Optional[Dict]:
        for u in self.users:
            if u["email"].lower() == email.lower():
                return u
        return None

    def get_employees(self) -> List[Dict]:
        return self.employees

    def get_locations(self) -> List[Dict]:
        return self.locations

    def get_inventory(self, machine_id: Optional[str] = None) -> Dict:
        if machine_id:
             return {machine_id: self.inventory.get(machine_id, [])}
        return self.inventory

db = MockDB()
