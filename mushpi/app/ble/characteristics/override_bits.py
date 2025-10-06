"""
Override Bits Characteristic

Handles manual relay control override bits.
Supports write-only operations.
"""

import logging
from typing import Optional, Callable

from ..base import WriteOnlyCharacteristic
from ...models.ble_dataclasses import OVERRIDE_BITS_UUID, OverrideBits
from ..serialization import OverrideBitsSerializer, DataConverter
from ..validators import OverrideBitsValidator

logger = logging.getLogger(__name__)


class OverrideBitsCharacteristic(WriteOnlyCharacteristic):
    """Override bits characteristic (write-only)"""
    
    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize override bits characteristic
        
        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        super().__init__(OVERRIDE_BITS_UUID, service, simulation_mode)
        
        # Data and callbacks
        self.override_bits = 0
        self.apply_overrides: Optional[Callable] = None
        
    def _handle_write(self, value: bytes, options):
        """Write callback for override bits
        
        Args:
            value: Binary data to write (2 bytes)
            options: BLE write options
        """
        try:
            if len(value) != OverrideBitsSerializer.SIZE:
                logger.warning(f"Invalid override bits data length: {len(value)} "
                              f"(expected {OverrideBitsSerializer.SIZE})")
                return
                
            # Unpack data
            override_bits = OverrideBitsSerializer.unpack(value)
            
            # Validate bits
            if not OverrideBitsValidator.validate(override_bits):
                logger.warning(f"Invalid override bits received: 0x{override_bits:04X}")
                return
                
            # Update local copy
            self.override_bits = override_bits
                
            # Apply overrides to control system
            if self.apply_overrides:
                override_dict = DataConverter.override_bits_to_dict(override_bits)
                self.apply_overrides(override_dict)
                
            logger.info(f"BLE override bits updated: 0x{override_bits:04X}")
            
        except Exception as e:
            logger.error(f"Error writing override bits: {e}")
    
    def set_override_callback(self, callback: Callable):
        """Set callback function for applying overrides
        
        Args:
            callback: Function to apply override settings
        """
        self.apply_overrides = callback
    
    def get_current_overrides(self) -> int:
        """Get current override bits value
        
        Returns:
            Current override bits value
        """
        return self.override_bits
    
    def clear_overrides(self):
        """Clear all override bits"""
        self.override_bits = 0
        if self.apply_overrides:
            override_dict = DataConverter.override_bits_to_dict(0)
            self.apply_overrides(override_dict)
        logger.info("All override bits cleared")