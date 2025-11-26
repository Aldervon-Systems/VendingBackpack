import asyncio
import logging
from .hardware import HardwareInterface

logger = logging.getLogger(__name__)

class MockHardwareService(HardwareInterface):
    """
    Simulates vending machine hardware for Demo Mode.
    """

    async def initialize(self) -> bool:
        logger.info("🤖 MOCK HARDWARE: Initializing...")
        await asyncio.sleep(0.5)  # Simulate startup delay
        logger.info("🤖 MOCK HARDWARE: Ready!")
        return True

    async def dispense_item(self, slot_number: int) -> bool:
        logger.info(f"🤖 MOCK HARDWARE: Request to dispense from slot {slot_number}")
        
        # Simulate mechanical delay (motor turning)
        logger.info("🤖 MOCK HARDWARE: Motor turning... ⚙️")
        await asyncio.sleep(2.0) 
        
        logger.info(f"🤖 MOCK HARDWARE: Item dispensed from slot {slot_number} ✅")
        return True

    async def get_status(self) -> dict:
        return {
            "status": "online",
            "mode": "demo",
            "details": "Mock Hardware Service Active"
        }
