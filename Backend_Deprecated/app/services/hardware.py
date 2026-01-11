from abc import ABC, abstractmethod

class HardwareInterface(ABC):
    """
    Abstract base class for Vending Machine Hardware.
    All hardware implementations (Mock, Real) must follow this contract.
    """

    @abstractmethod
    async def initialize(self) -> bool:
        """Initialize the hardware connection."""
        pass

    @abstractmethod
    async def dispense_item(self, slot_number: int) -> bool:
        """
        Dispense an item from the given slot.
        Returns True if successful, False otherwise.
        """
        pass

    @abstractmethod
    async def get_status(self) -> dict:
        """Get current hardware status."""
        pass
