"""
Control Targets Characteristic

Handles control system threshold configuration.
Supports read and write operations.
"""

import logging
from typing import Optional, Callable

from ..base import ReadWriteCharacteristic
from ...models.ble_dataclasses import CONTROL_TARGETS_UUID, ControlTargets
from ..serialization import ControlTargetsSerializer, DataConverter
from ..validators import ControlTargetsValidator

logger = logging.getLogger(__name__)


class ControlTargetsCharacteristic(ReadWriteCharacteristic):
    """Control targets characteristic (read/write)"""
    
    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize control targets characteristic
        
        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        super().__init__(CONTROL_TARGETS_UUID, service, simulation_mode)
        
        # Data and callbacks
        self.control_targets = ControlTargets.create_default()
        self.get_control_data: Optional[Callable] = None
        self.set_control_targets: Optional[Callable] = None
        
    def _handle_read(self, options) -> bytes:
        """Read callback for control targets
        
        Args:
            options: BLE read options
            
        Returns:
            Packed binary data (15 bytes)
        """
        try:
            # Update current targets from control system
            if self.get_control_data:
                control_data = self.get_control_data()
                if control_data:
                    self.control_targets = DataConverter.control_targets_from_dict(control_data)
            
            # Pack and return data
            data = ControlTargetsSerializer.pack(self.control_targets)
            
            logger.debug(f"BLE control read: T={self.control_targets.temp_min_x10/10}-"
                        f"{self.control_targets.temp_max_x10/10}°C")
            return data
            
        except Exception as e:
            logger.error(f"Error reading control targets: {e}")
            return b'\x00' * ControlTargetsSerializer.SIZE  # Return zeros on error
    
    def _handle_write(self, value: bytes, options):
        """Write callback for control targets
        
        Args:
            value: Binary data to write (15 bytes)
            options: BLE write options
        """
        try:
            if len(value) != ControlTargetsSerializer.SIZE:
                logger.warning(f"Invalid control targets data length: {len(value)} "
                              f"(expected {ControlTargetsSerializer.SIZE})")
                return
                
            # Unpack data
            new_targets = ControlTargetsSerializer.unpack(value)
            
            # Validate ranges
            if not ControlTargetsValidator.validate(new_targets):
                logger.warning("Invalid control target values received")
                return
                
            # Update local copy
            self.control_targets = new_targets
                
            # Apply to control system
            if self.set_control_targets:
                target_dict = DataConverter.control_targets_to_dict(new_targets)
                self.set_control_targets(target_dict)
                
            logger.info(f"BLE control targets updated: T={new_targets.temp_min_x10/10}-"
                       f"{new_targets.temp_max_x10/10}°C")
            
        except Exception as e:
            logger.error(f"Error writing control targets: {e}")
    
    def set_control_callbacks(self, get_callback: Callable, set_callback: Callable):
        """Set callback functions for control data access
        
        Args:
            get_callback: Function to get current control data
            set_callback: Function to set new control targets
        """
        self.get_control_data = get_callback
        self.set_control_targets = set_callback
    
    def update_targets(self, targets: ControlTargets):
        """Update control targets from external source
        
        Args:
            targets: New control targets
        """
        if ControlTargetsValidator.validate(targets):
            self.control_targets = targets
            logger.debug("Control targets updated from external source")
        else:
            logger.warning("Invalid control targets provided for update")