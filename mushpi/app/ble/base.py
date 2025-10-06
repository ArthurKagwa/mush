"""
BLE GATT Base Classes and Common Utilities

Base classes for BLE characteristics and common functionality.
"""

import logging
from abc import ABC, abstractmethod
from typing import Optional, Any, Callable

try:
    from bluezero import peripheral
    BLE_AVAILABLE = True
except ImportError:
    BLE_AVAILABLE = False

from ..models.ble_dataclasses import StatusFlags

logger = logging.getLogger(__name__)


class BLEError(Exception):
    """Base exception for BLE-related errors"""
    pass


class CharacteristicError(BLEError):
    """Exception for characteristic-related errors"""
    pass


class BaseCharacteristic(ABC):
    """Base class for BLE GATT characteristics"""
    
    def __init__(self, uuid: str, properties: list, service=None, simulation_mode: bool = False):
        """Initialize base characteristic
        
        Args:
            uuid: Characteristic UUID
            properties: List of properties (e.g., ['read', 'write', 'notify'])
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        self.uuid = uuid
        self.properties = properties
        self.service = service
        self.simulation_mode = simulation_mode
        self.characteristic = None
        
        # Create characteristic if not in simulation mode
        if not simulation_mode and BLE_AVAILABLE and service:
            self._create_characteristic()
    
    def _create_characteristic(self):
        """Create the actual BLE characteristic"""
        if self.simulation_mode or not BLE_AVAILABLE:
            logger.debug(f"Skipping characteristic creation for {self.uuid} (simulation/no BLE)")
            return
            
        try:
            self.characteristic = peripheral.Characteristic(
                self.uuid,
                self.properties,
                self.service
            )
            
            # Set up callbacks based on properties
            if 'read' in self.properties:
                self.characteristic.read_callback = self._handle_read
            if 'write' in self.properties:
                self.characteristic.write_callback = self._handle_write
                
            logger.debug(f"Created characteristic {self.uuid} with properties {self.properties}")
            
        except Exception as e:
            logger.error(f"Failed to create characteristic {self.uuid}: {e}")
            raise CharacteristicError(f"Failed to create characteristic: {e}")
    
    @abstractmethod
    def _handle_read(self, options) -> bytes:
        """Handle read operations - must be implemented by subclasses
        
        Args:
            options: BLE read options
            
        Returns:
            Binary data to return
        """
        pass
    
    def _handle_write(self, value: bytes, options):
        """Handle write operations - override in subclasses if needed
        
        Args:
            value: Binary data written
            options: BLE write options
        """
        logger.warning(f"Write operation not implemented for {self.uuid}")
    
    def notify(self, data: bytes, device=None):
        """Send notification to connected device(s)
        
        Args:
            data: Binary data to send
            device: Specific device to notify (None for all)
        """
        if self.simulation_mode or not self.characteristic:
            logger.debug(f"Skipping notification for {self.uuid} (simulation/no characteristic)")
            return
            
        if 'notify' not in self.properties:
            logger.warning(f"Characteristic {self.uuid} does not support notifications")
            return
            
        try:
            if device:
                self.characteristic.notify(data, device)
            else:
                self.characteristic.notify(data)
                
        except Exception as e:
            logger.error(f"Failed to send notification for {self.uuid}: {e}")


class ReadOnlyCharacteristic(BaseCharacteristic):
    """Base class for read-only characteristics"""
    
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ['read'], service, simulation_mode)


class ReadWriteCharacteristic(BaseCharacteristic):
    """Base class for read/write characteristics"""
    
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ['read', 'write'], service, simulation_mode)


class NotifyCharacteristic(BaseCharacteristic):
    """Base class for notify characteristics"""
    
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ['read', 'notify'], service, simulation_mode)


class WriteOnlyCharacteristic(BaseCharacteristic):
    """Base class for write-only characteristics"""
    
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ['write'], service, simulation_mode)
    
    def _handle_read(self, options) -> bytes:
        """Write-only characteristics don't support read"""
        logger.warning(f"Read attempted on write-only characteristic {self.uuid}")
        return b'\x00'


# Export all classes
__all__ = [
    'BLEError', 'CharacteristicError', 'BaseCharacteristic',
    'ReadOnlyCharacteristic', 'ReadWriteCharacteristic', 
    'NotifyCharacteristic', 'WriteOnlyCharacteristic'
]