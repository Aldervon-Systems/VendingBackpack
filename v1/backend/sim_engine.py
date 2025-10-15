import threading
import time
import random
import json
from pathlib import Path
from datetime import datetime, timedelta
import sqlite3

DATA_DIR = Path(__file__).parent.parent / 'src' / 'data'
DB_PATH = DATA_DIR / 'vending_machine.db'

# Simulation parameters
SALE_CHANCE_PER_MIN = 0.03
OFFLINE_CHANCE_PER_HOUR = 0.01
SIM_MINUTES_PER_WEEK = 7 * 24 * 60

class SimEngine:
    def __init__(self):
        self.lock = threading.Lock()
        self.running = False
        self.thread = None
        self.machines = []  # List of machine dicts
        self.history = []
        self.kpis = {}
        self.offline_machines = set()  # Set of machine IDs
        self.start_time = datetime.now() - timedelta(days=7)
        self.current_time = self.start_time
        self.inventory = {}  # Dict of machine_id -> list of SKUs
        self.daily_stats = []  # list of {'date','sales','restock_alerts'} for last 7 days
        self._load_machines()
        self._init_inventory()
        self._simulate_initial_week()
        self._save_state()
    def _init_inventory(self):
        # Initialize each machine with 10 SKUs, random stock 0-20, cap 20
        for m in self.machines:
            mid = m['id']
            # Use 8 canonical items per machine to match seed_data (item_1..item_8)
            self.inventory[mid] = [
                {'sku': f'item_{i+1}', 'qty': random.randint(0, 20), 'cap': 20} for i in range(8)
            ]

    def _load_machines(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('SELECT value FROM config WHERE key = ?', ('machines',))
        row = c.fetchone()
        if row:
            self.machines = json.loads(row[0])
        else:
            self.machines = []
        # If fewer than 20 machines, auto-generate and save
        if len(self.machines) < 20:
            self.machines = [
                {'id': f'machine{i+1}', 'name': f'Machine {i+1}'} for i in range(20)
            ]
            c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', ('machines', json.dumps(self.machines)))
            conn.commit()
        conn.close()

    def _simulate_initial_week(self):
        # Seed history, inventory and daily stats for the past week
        self.history = []
        self.offline_machines = set()
        sales = 0
        offline_events = 0
        # ensure inventory reset
        self._init_inventory()

        minutes_per_day = 24 * 60
        daily_sales = 0
        self.daily_stats = []

        for minute in range(SIM_MINUTES_PER_WEEK):
            sim_time = self.start_time + timedelta(minutes=minute)
            # Sales
            if random.random() < SALE_CHANCE_PER_MIN:
                sales += 1
                daily_sales += 1
                m = random.choice(self.machines) if self.machines else None
                mid = m['id'] if m and 'id' in m else None
                if mid and self.inventory.get(mid):
                    sku = random.choice(self.inventory[mid])
                    if sku.get('qty', 0) > 0:
                        sku['qty'] = sku.get('qty', 0) - 1
                self.history.append({
                    'timestamp': sim_time.isoformat(),
                    'event': 'sale',
                    'machine': mid
                })

            # Offline events (hourly)
            if minute % 60 == 0 and random.random() < OFFLINE_CHANCE_PER_HOUR:
                offline_events += 1
                m = random.choice(self.machines) if self.machines else None
                mid = m['id'] if m and 'id' in m else None
                if mid:
                    self.offline_machines.add(mid)
                    self.history.append({
                        'timestamp': sim_time.isoformat(),
                        'event': 'offline',
                        'machine': mid
                    })

            # End of day: record daily stats
            if (minute + 1) % minutes_per_day == 0:
                # compute restock alerts from current inventory
                restock_alerts = 0
                for inv in self.inventory.values():
                    for sku in inv:
                        if sku.get('qty', 0) == 0 or sku.get('qty', 0) < 5:
                            restock_alerts += 1
                day_date = (self.start_time + timedelta(minutes=minute)).date().isoformat()
                self.daily_stats.append({'date': day_date, 'sales': daily_sales, 'restock_alerts': restock_alerts})
                daily_sales = 0

        # Ensure 7 days
        if len(self.daily_stats) > 7:
            self.daily_stats = self.daily_stats[-7:]
        elif len(self.daily_stats) < 7:
            # pad older days
            final_day = (self.start_time + timedelta(minutes=SIM_MINUTES_PER_WEEK)).date()
            while len(self.daily_stats) < 7:
                d = final_day - timedelta(days=(6 - len(self.daily_stats)))
                self.daily_stats.insert(0, {'date': d.isoformat(), 'sales': 0, 'restock_alerts': 0})

        # Set kpis (keep sales/offline and time window)
        self.kpis = {
            'sales': sales,
            'offline_events': offline_events,
            'start_time': self.start_time.isoformat(),
            'end_time': (self.start_time + timedelta(minutes=SIM_MINUTES_PER_WEEK)).isoformat()
        }

    def _save_state(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', ('history', json.dumps(self.history)))
        c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', ('kpis', json.dumps(self.kpis)))
        c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', ('offline_machines', json.dumps(list(self.offline_machines))))
        # persist weekly/daily stats so API and frontend can read them
        try:
            c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', ('daily_stats', json.dumps(self.daily_stats)))
        except Exception:
            pass
        conn.commit()
        conn.close()

    def start(self):
        if not self.running:
            self.running = True
            self.thread = threading.Thread(target=self._run, daemon=True)
            self.thread.start()

    def _run(self):
        while self.running:
            with self.lock:
                self._step()
            time.sleep(60)  # Simulate every minute

    def _step(self):
        self.current_time += timedelta(minutes=1)
        # Sale event
        if random.random() < SALE_CHANCE_PER_MIN:
            m = random.choice(self.machines) if self.machines else None
            mid = m['id'] if m and 'id' in m else None
            if mid and self.inventory.get(mid):
                sku = random.choice(self.inventory[mid])
                if sku['qty'] > 0:
                    sku['qty'] -= 1
            self.history.append({
                'timestamp': self.current_time.isoformat(),
                'event': 'sale',
                'machine': mid
            })
            self.kpis['sales'] += 1
            # increment today's counter in daily_stats
            if not self.daily_stats or self.daily_stats[-1]['date'] != self.current_time.date().isoformat():
                # roll daily_stats to keep last 7 days
                while len(self.daily_stats) >= 7:
                    self.daily_stats.pop(0)
                self.daily_stats.append({'date': self.current_time.date().isoformat(), 'sales': 0, 'restock_alerts': 0})
            self.daily_stats[-1]['sales'] = self.daily_stats[-1].get('sales', 0) + 1
        # Offline event
        if self.current_time.minute == 0 and random.random() < OFFLINE_CHANCE_PER_HOUR:
            m = random.choice(self.machines) if self.machines else None
            mid = m['id'] if m and 'id' in m else None
            if mid:
                self.offline_machines.add(mid)
                self.history.append({
                    'timestamp': self.current_time.isoformat(),
                    'event': 'offline',
                    'machine': mid
                })
                self.kpis['offline_events'] += 1
        # Update today's restock_alerts based on current inventory snapshot
        if self.daily_stats:
            restock_alerts = 0
            for inv in self.inventory.values():
                for sku in inv:
                    if sku.get('qty', 0) == 0 or sku.get('qty', 0) < 5:
                        restock_alerts += 1
            self.daily_stats[-1]['restock_alerts'] = restock_alerts
        # Keep only last week of history
        week_ago = self.current_time - timedelta(days=7)
        self.history = [h for h in self.history if datetime.fromisoformat(h['timestamp']) >= week_ago]
        self.kpis['start_time'] = week_ago.isoformat()
        self.kpis['end_time'] = self.current_time.isoformat()
        self._save_state()

    def get_weekly_stats(self):
        # return a copy to avoid external mutation
        return list(self.daily_stats)

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join()

# Singleton
sim_engine = SimEngine()
