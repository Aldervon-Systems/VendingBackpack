"""
Mock Hardware Service for Demo/Sales Mode.

Simulates a WiFi-connected vending machine with serial communication.
Used when DEMO_MODE=true for testing and sales demonstrations.
"""

import asyncio
import logging
import random
from typing import Optional
from .hardware import HardwareInterface

logger = logging.getLogger(__name__)


class MockHardwareService(HardwareInterface):
    """
    Simulates vending machine hardware over WiFi with serial-like communication.
    
    Provides realistic delays and occasional failures for demo purposes.
    """
    
    def __init__(self):
        self._connected = False
        self._wifi_ssid: Optional[str] = None
        self._serial_buffer: list[str] = []
        self._slots: dict[int, int] = {}  # slot_number -> items remaining
        
    async def initialize(self) -> bool:
        """Simulate WiFi connection and serial handshake."""
        logger.info("🔧 MOCK HARDWARE: Starting initialization...")
        
        # Simulate WiFi connection delay
        await asyncio.sleep(0.5)
        self._wifi_ssid = "VendingMachine_Demo"
        logger.info(f"📶 MOCK HARDWARE: Connected to WiFi '{self._wifi_ssid}'")
        
        # Simulate serial handshake
        await asyncio.sleep(0.3)
        self._serial_write("INIT")
        response = await self._serial_read()
        
        if response == "ACK":
            self._connected = True
            # Initialize demo slots with random stock
            for slot in range(1, 13):  # 12 slots typical
                self._slots[slot] = random.randint(3, 10)
            logger.info("✅ MOCK HARDWARE: Serial handshake complete, ready for operations")
            return True
        else:
            logger.error("❌ MOCK HARDWARE: Serial handshake failed")
            return False
    
    async def dispense_item(self, slot_number: int) -> bool:
        """
        Simulate dispensing an item from the given slot.
        
        Includes realistic delays and occasional failures.
        """
        if not self._connected:
            logger.error("❌ MOCK HARDWARE: Not connected, cannot dispense")
            return False
            
        logger.info(f"🎰 MOCK HARDWARE: Dispensing from slot {slot_number}...")
        
        # Send dispense command via "serial"
        self._serial_write(f"DISPENSE:{slot_number}")
        
        # Simulate motor operation time
        await asyncio.sleep(random.uniform(1.0, 2.0))
        
        # Read response
        response = await self._serial_read()
        
        # Simulate occasional failures (5% chance)
        if random.random() < 0.05:
            logger.warning(f"⚠️ MOCK HARDWARE: Dispense failed for slot {slot_number} (jam simulation)")
            return False
        
        # Check if slot has items
        if slot_number in self._slots and self._slots[slot_number] > 0:
            self._slots[slot_number] -= 1
            logger.info(f"✅ MOCK HARDWARE: Dispensed from slot {slot_number}, {self._slots[slot_number]} remaining")
            return True
        else:
            logger.warning(f"⚠️ MOCK HARDWARE: Slot {slot_number} is empty")
            return False
    
    async def get_status(self) -> dict:
        """Get current mock hardware status including slot inventory."""
        return {
            "status": "online" if self._connected else "offline",
            "mode": "demo",
            "wifi_ssid": self._wifi_ssid,
            "wifi_signal": random.randint(-70, -30) if self._connected else None,  # dBm
            "serial_connected": self._connected,
            "slots": self._slots.copy(),
            "temperature": round(random.uniform(18.0, 25.0), 1),  # Celsius
            "uptime_seconds": random.randint(1000, 86400),
        }
    
    async def read_sensor_data(self) -> dict:
        """
        Simulate reading sensor data over serial.
        
        Returns temperature, humidity, and door status.
        """
        if not self._connected:
            return {"error": "Not connected"}
        
        self._serial_write("READ_SENSORS")
        await asyncio.sleep(0.1)
        
        return {
            "temperature_c": round(random.uniform(18.0, 25.0), 1),
            "humidity_pct": random.randint(30, 60),
            "door_open": False,
            "coin_box_full": random.random() < 0.1,  # 10% chance
            "bill_acceptor_ok": True,
        }
    
    async def get_slot_status(self, slot_number: int) -> dict:
        """Get status of a specific slot."""
        if slot_number not in self._slots:
            return {"error": f"Invalid slot {slot_number}"}
        
        return {
            "slot": slot_number,
            "items_remaining": self._slots[slot_number],
            "motor_ok": True,
            "sensor_ok": True,
        }
    
    def _serial_write(self, command: str) -> None:
        """Simulate writing to serial port."""
        logger.debug(f"📤 SERIAL TX: {command}")
        self._serial_buffer.append(f"TX:{command}")
    
    async def _serial_read(self, timeout: float = 1.0) -> str:
        """Simulate reading from serial port with timeout."""
        await asyncio.sleep(random.uniform(0.05, 0.2))  # Realistic serial delay
        
        # Simulate responses based on last command
        if self._serial_buffer and "INIT" in self._serial_buffer[-1]:
            response = "ACK"
        elif self._serial_buffer and "DISPENSE" in self._serial_buffer[-1]:
            response = "OK"
        else:
            response = "READY"
        
        logger.debug(f"📥 SERIAL RX: {response}")
        self._serial_buffer.append(f"RX:{response}")
        return response
