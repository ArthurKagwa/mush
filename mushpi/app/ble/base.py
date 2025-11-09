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
        """Single-attempt creation matching official examples"""
        if self.simulation_mode or not BLE_AVAILABLE:
            logger.debug(f"Skipping creation (simulation/no BLE): {self.uuid}")
            return

        peripheral = self.service.peripheral
        srv_id = self.service.srv_id
        chr_id = self._get_next_index_for_service(self.service)

                read_cb = self._handle_read_with_logging if 'read' in self.properties else None
                write_cb = self._handle_write_with_logging if 'write' in self.properties else None

                # Some bluezero releases accept different signatures. Try the most
                # complete form first (includes notifying flag and explicit callbacks).
                notify_cb = None
                flags = list(self.properties)
                value = bytearray()  # Initial empty value; adjust if you need a default non-empty value

                attempts = [
                    {
                        'args': (self.service, char_index, self.uuid, value, False, flags, read_cb, write_cb, notify_cb),
                        'kwargs': {}
                    },
                    {
                        'args': (char_index, self.uuid, flags, self.service),
                        'kwargs': {}
                    },
                    {
                        'args': (self.service, char_index, self.uuid, False, flags, read_cb, write_cb, notify_cb),
                        'kwargs': {}
                    },
                    {
                        'args': (),
                        'kwargs': {
                            'service': self.service,
                            'index': char_index,
                            'uuid': self.uuid,
                            'notifying': False,
                            'flags': flags,
                            'read_callback': read_cb,
                            'write_callback': write_cb,
                            'notify_callback': notify_cb,
                        }
                    },
                    {
                        'args': (self.service, char_index, self.uuid, False, flags, read_cb, write_cb),
                        'kwargs': {}
                    },
                    {
                        'args': (self.service, char_index, self.uuid, False, flags),
                        'kwargs': {}
                    },
                    {
                        'args': (self.service, char_index, self.uuid, flags, read_cb, write_cb),
                        'kwargs': {}
                    },
                    {
                        'args': (self.service, char_index, self.uuid, flags),
                        'kwargs': {}
                    },
                ]

                last_error = None
                for attempt in attempts:
                    try:
                        self.characteristic = localGATT.Characteristic(
                            *attempt['args'], **attempt['kwargs']
                        )
                        break
                    except TypeError as err:
                        last_error = err
                        continue
                else:
                    # All attempts failed
                    raise CharacteristicError(
                        f"localGATT.Characteristic signature mismatch: {last_error}"
                    )

                # Some bluezero releases expect callbacks to be assigned after creation
                if read_cb and hasattr(self.characteristic, 'read_callback'):
                    self.characteristic.read_callback = read_cb
                if write_cb and hasattr(self.characteristic, 'write_callback'):
                    self.characteristic.write_callback = write_cb

                logger.debug(
                    "Created characteristic %s via bluezero.localGATT (index=%s)",
                    self.uuid,
                    char_index,
                )

            else:
                raise CharacteristicError(
                    "No compatible BlueZero characteristic implementation available"
                )
            
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
        if self.simulation_mode or self.characteristic is None:
            logger.debug(f"Skip notify (simulation/no char obj): {self.uuid}")
            return
        if device:
            logger.warning("per-device notify not supported")
        try:
            self.characteristic.set_value(list(data))
        except Exception as e:
            logger.error(f"Notify failed {self.uuid}: {e}")

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