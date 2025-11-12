"""
Status Flags Characteristic

Handles system status flags for monitoring system health.
Supports read and notify operations.
"""

import logging
from typing import Optional, Set

from ..base import NotifyCharacteristic
from ...models.ble_dataclasses import STATUS_FLAGS_UUID, StatusFlags
from ..serialization import StatusFlagsSerializer

logger = logging.getLogger(__name__)


class StatusFlagsCharacteristic(NotifyCharacteristic):
    """Status flags characteristic (read/notify)"""
    
    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize status flags characteristic
        
        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        # Data must be set BEFORE calling super().__init__() 
        # because base class will call _handle_read() during initialization
        self.status_flags = StatusFlags.SIMULATION if simulation_mode else 0
        
        super().__init__(STATUS_FLAGS_UUID, service, simulation_mode)
        
    def _handle_read(self, options) -> bytes:
        """Read callback for status flags
        
        Args:
            options: BLE read options
            
        Returns:
            Packed binary data (4 bytes)
        """
        try:
            # Pack and return data
            data = StatusFlagsSerializer.pack(int(self.status_flags))
            
            logger.debug(f"BLE status read: flags=0x{int(self.status_flags):04X}")
            return data
            
        except Exception as e:
            logger.error(f"Error reading status flags: {e}")
            return b'\x00' * StatusFlagsSerializer.SIZE  # Return zeros on error
    
    def update_flags(self, flags: StatusFlags, connected_devices: Optional[Set] = None):
        """Update system status flags
        
        Args:
            flags: Status flags to set
            connected_devices: Set of connected device addresses (for connectivity flag)
        """
        # Update flags
        self.status_flags = flags
        
        # Update connectivity status if device set provided
        if connected_devices is not None:
            if connected_devices:
                self.status_flags |= StatusFlags.CONNECTIVITY
            else:
                self.status_flags &= ~StatusFlags.CONNECTIVITY
                
        logger.debug(f"Status flags updated: 0x{int(self.status_flags):04X}")
    
    def notify_update(self, connected_devices: set):
        """Send notification to connected devices
        
        Args:
            connected_devices: Set of connected device addresses
        """
        if not connected_devices or self.simulation_mode:
            return
            
        try:
            data = StatusFlagsSerializer.pack(int(self.status_flags))
            
            # Send notification to all connected devices
            for device in connected_devices:
                try:
                    self.notify(data, device)
                except Exception as e:
                    logger.warning(f"Failed to notify device {device}: {e}")
                    
        except Exception as e:
            logger.error(f"Error notifying status flags: {e}")
    
    def set_flag(self, flag: StatusFlags, value: bool = True):
        """Set or clear a specific status flag
        
        Args:
            flag: Status flag to modify
            value: True to set, False to clear
        """
        if value:
            self.status_flags |= flag
        else:
            self.status_flags &= ~flag
            
        logger.debug(f"Status flag {flag.name} {'set' if value else 'cleared'}")
    
    def get_flags(self) -> StatusFlags:
        """Get current status flags
        
        Returns:
            Current status flags
        """
        return self.status_flags
    
    def has_flag(self, flag: StatusFlags) -> bool:
        """Check if a specific flag is set
        
        Args:
            flag: Status flag to check
            
        Returns:
            True if flag is set, False otherwise
        """
        return bool(self.status_flags & flag)