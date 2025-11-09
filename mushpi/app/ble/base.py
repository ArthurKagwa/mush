"""
BLE GATT Base Classes and Common Utilities - Modern bluezero (>=0.8.0, including 0.9.1)

Single-attempt creation using peripheral.add_characteristic (as in official examples).
Assumes your BaseService has:
- self.peripheral: peripheral.Peripheral instance
- self.srv_id: int (from peripheral.add_service(srv_id=..., ...))

See: https://bluezero.readthedocs.io/en/stable/examples.html#peripheral-nordic-uart-service
"""

import logging
from abc import ABC, abstractmethod
from typing import Optional, Any, Dict

try:
    from bluezero import peripheral
except ImportError:
    peripheral = None

BLE_AVAILABLE = peripheral is not None

from ..models.ble_dataclasses import StatusFlags

logger = logging.getLogger(__name__)


class BLEError(Exception):
    """Base exception for BLE-related errors"""
    pass


class CharacteristicError(BLEError):
    """Exception for characteristic-related errors"""
    pass


class BaseCharacteristic(ABC):
    """Base class for BLE GATT characteristics - modern bluezero API (single attempt)"""

    _service_indices = {}  # srv_id -> next chr_id (starts at 1)

    def __init__(self, uuid: str, properties: list[str], service=None, simulation_mode: bool = False):
        self.uuid = uuid
        self.properties = properties  # e.g. ['read', 'notify']
        self.service = service
        self.simulation_mode = simulation_mode
        self.characteristic: Optional[Any] = None

        if not self.simulation_mode and BLE_AVAILABLE and self.service:
            if not hasattr(self.service, "peripheral") or not hasattr(self.service, "srv_id"):
                raise CharacteristicError("Service must have .peripheral and .srv_id attributes")
            self._create_characteristic()

    def _handle_notify_callback(self, notifying: bool, characteristic: Any):
        """Called when client enables/disables CCCD"""
        self.characteristic = characteristic
        logger.info(f"BLE {'ENABLED' if notifying else 'DISABLED'}: {self.uuid}")

    def _create_characteristic(self):
        """Create characteristic using peripheral.add_characteristic() API"""
        if self.simulation_mode or not BLE_AVAILABLE:
            logger.debug(f"Skipping creation (simulation/no BLE): {self.uuid}")
            return

        try:
            periph = self.service.peripheral
            srv_id = self.service.srv_id
            chr_id = self._get_next_index_for_service(self.service)

            # Set up callbacks
            read_cb = self._handle_read_with_logging if 'read' in self.properties else None
            write_cb = self._handle_write_with_logging if 'write' in self.properties else None
            notify_cb = self._handle_notify_callback if 'notify' in self.properties else None

            # Use peripheral.add_characteristic() API
            periph.add_characteristic(
                srv_id=srv_id,
                chr_id=chr_id,
                uuid=self.uuid,
                value=[],  # Start with empty value
                notifying=False,
                flags=self.properties,
                read_callback=read_cb,
                write_callback=write_cb,
                notify_callback=notify_cb
            )

            logger.info(f"  ✓ Created characteristic: {self.uuid} (srv={srv_id}, chr={chr_id})")

        except Exception as e:
            logger.error(f"Failed to create characteristic {self.uuid}: {e}")
            raise CharacteristicError(f"Failed to create characteristic: {e}")
    @classmethod
    def _get_next_index_for_service(cls, service):
        srv_id = service.srv_id
        next_idx = cls._service_indices.get(srv_id, 1)
        cls._service_indices[srv_id] = next_idx + 1
        return next_idx

    def _handle_read_with_logging(self, options=None):
        if options is None:
            options = {}
        logger.info(f"📖 BLE READ: {self.uuid}")
        try:
            result = self._handle_read(options)
            length = len(result) if isinstance(result, (bytes, bytearray, list)) else 0
            logger.debug(f"  ✓ Read {length} bytes")
            return [b for b in result] if isinstance(result, (bytes, bytearray)) else result
        except Exception as e:
            logger.error(f"  ✗ Read failed: {e}", exc_info=True)
            raise

    def _handle_write_with_logging(self, value, options=None):
        if options is None:
            options = {}
        logger.info(f"✍️ BLE WRITE: {self.uuid} ({len(value)} bytes)")
        try:
            byte_value = bytes(value)  # value is list[int]
            self._handle_write(byte_value, options)
            logger.debug("  ✓ Write successful")
        except Exception as e:
            logger.error(f"  ✗ Write failed: {e}", exc_info=True)
            raise

    @abstractmethod
    def _handle_read(self, options: dict) -> bytes:
        pass

    def _handle_write(self, value: bytes, options: dict):
        logger.warning(f"Write not implemented for {self.uuid}")

    def notify(self, data: bytes, device=None):
        """Send notification to connected devices
        
        With peripheral API, notifications are handled automatically when
        the characteristic value is updated via the characteristic object.
        This method is kept for API compatibility but may not work with
        all BlueZero versions.
        """
        if self.simulation_mode:
            logger.debug(f"Skip notify (simulation mode): {self.uuid}")
            return
        
        # Note: With peripheral.add_characteristic(), notifications are sent
        # automatically when characteristic values change. This method is
        # here for compatibility but may need adjustment based on your
        # BlueZero version's notification mechanism.
        logger.debug(f"Notify requested for {self.uuid} (handled by BlueZero)")

# Subclasses unchanged
class ReadOnlyCharacteristic(BaseCharacteristic):
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ["read"], service, simulation_mode)

class ReadWriteCharacteristic(BaseCharacteristic):
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ["read", "write"], service, simulation_mode)

class NotifyCharacteristic(BaseCharacteristic):
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ["read", "notify"], service, simulation_mode)

class WriteOnlyCharacteristic(BaseCharacteristic):
    def __init__(self, uuid: str, service=None, simulation_mode: bool = False):
        super().__init__(uuid, ["write"], service, simulation_mode)

    def _handle_read(self, options) -> list:
        logger.warning(f"Read on write-only {self.uuid}")
        return []

__all__ = [
    "BLEError", "CharacteristicError", "BaseCharacteristic",
    "ReadOnlyCharacteristic", "ReadWriteCharacteristic",
    "NotifyCharacteristic", "WriteOnlyCharacteristic"
]