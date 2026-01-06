import logging
from .hardware import HardwareInterface

logger = logging.getLogger(__name__)

class RealHardwareService(HardwareInterface):
    """
    Interface for real physical hardware (e.g., via Serial/GPIO).
    Currently a placeholder.
    """

    async def initialize(self) -> bool:
        logger.info("🔌 REAL HARDWARE: Initializing connection...")
        # TODO: Implement actual serial connection here
        # e.g., self.serial = serial.Serial('/dev/ttyUSB0', 9600)
        logger.warning("🔌 REAL HARDWARE: Not implemented yet!")
        return False

    async def dispense_item(self, slot_number: int) -> bool:
        logger.info(f"🔌 REAL HARDWARE: Dispensing from slot {slot_number}")
        # TODO: Send bytes to microcontroller
        return False

    async def get_status(self) -> dict:
        return {
            "status": "offline",
            "mode": "real",
            "details": "Real Hardware Not Connected"
        }
