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
        self.characteristic = None  # BlueZero characteristic object once available
        self._char_object_cached = None  # Cached object for direct value updates
        self._notify_enabled = False  # Track subscription state
        self._notify_enable_count = 0  # How many times enabled in this runtime
        self._notify_push_count = 0  # Successful push count for diagnostics
        # Store service/characteristic indices so we can update values later
        self._srv_id = None
        self._chr_id = None

        if not self.simulation_mode and BLE_AVAILABLE and self.service:
            if not hasattr(self.service, "peripheral") or not hasattr(self.service, "srv_id"):
                raise CharacteristicError("Service must have .peripheral and .srv_id attributes")
            self._create_characteristic()

    def _handle_notify_callback(self, notifying: bool, characteristic: Any):
        """Called when client enables/disables CCCD"""
        self.characteristic = characteristic
        # Cache underlying characteristic object if present for direct updates
        if characteristic is not None:
            self._char_object_cached = characteristic
        # Track subscription state
        self._notify_enabled = bool(notifying)
        if notifying:
            self._notify_enable_count += 1
        else:
            # When notifications are disabled clear cached object to avoid stale refs
            self._char_object_cached = None
        logger.info(f"BLE {'ENABLED' if notifying else 'DISABLED'}: {self.uuid}")
        # When notifications are enabled, proactively push the current value
        # so clients receive a fresh packet immediately after subscription.
        if notifying:
            try:
                # Attempt to read current value via handler if available
                if 'read' in self.properties:
                    current = self._handle_read({})
                    if isinstance(current, (bytes, bytearray)) and len(current) > 0:
                        self.update_value(current)
                        logger.info(f"Pushed current value on notify enable for {self.uuid} ({len(current)} bytes)")
                    elif isinstance(current, list) and len(current) > 0:
                        self.update_value(bytes(current))
                        logger.info(f"Pushed current list value on notify enable for {self.uuid} ({len(current)} bytes)")
                    else:
                        logger.info(f"No current value to push on notify enable for {self.uuid}")
                else:
                    logger.info(f"Notify enabled for {self.uuid} but characteristic is not readable; skipping initial push")
            except Exception as e:
                logger.warning(f"Initial push on notify enable failed for {self.uuid}: {e}")

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

            # Get initial value from read handler (if available)
            initial_value = []
            if read_cb:
                try:
                    initial_value = read_cb({})
                    logger.debug(f"  Initial value: {len(initial_value) if isinstance(initial_value, list) else 0} bytes")
                except Exception as e:
                    logger.warning(f"  Could not get initial value: {e}")
                    initial_value = []

            # Use peripheral.add_characteristic() API
            periph.add_characteristic(
                srv_id=srv_id,
                chr_id=chr_id,
                uuid=self.uuid,
                value=initial_value,  # Use initial value from read handler
                notifying=False,
                flags=self.properties,
                read_callback=read_cb,
                write_callback=write_cb,
                notify_callback=notify_cb
            )

            logger.info(f"  ✓ Created characteristic: {self.uuid} (srv={srv_id}, chr={chr_id})")
            # Persist identifiers for future value updates
            self._srv_id = srv_id
            self._chr_id = chr_id

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
        try:
            self.update_value(data)
            logger.debug(f"Notify/update requested for {self.uuid} ({len(data)} bytes)")
        except Exception as e:
            logger.warning(f"Notify/update failed for {self.uuid}: {e}")

    # ---------------------------------------------------------------------
    # Value update helpers
    # ---------------------------------------------------------------------
    def update_value(self, data: bytes):
        """Update the characteristic value (triggering notify if subscribed).

        We attempt multiple BlueZero peripheral APIs to remain compatible
        with different library versions. Silent no-op if identifiers unknown.
        """
        if self.simulation_mode or not BLE_AVAILABLE:
            return
        if self._srv_id is None or self._chr_id is None:
            # Characteristic created in simulation or identifiers not captured
            logger.debug(f"Cannot update value (ids missing) for {self.uuid}")
            return
        periph = getattr(self.service, 'peripheral', None)
        if periph is None:
            logger.debug(f"Peripheral missing when updating {self.uuid}")
            return
        value_list = list(data)
        # If this is a notify-capable characteristic and no client has enabled notifications yet,
        # skip noisy update attempts; reads will still use the read handler.
        if 'notify' in self.properties and not self._notify_enabled:
            logger.debug(f"No subscribers for {self.uuid}; skipping notify update")
            return
        # Preferred fast path: if we have a cached characteristic object, try direct APIs
        if self._char_object_cached is not None:
            obj = self._char_object_cached
            try:
                # Try common direct methods
                if hasattr(obj, 'set_value'):
                    obj.set_value(value_list)
                    self._notify_push_count += 1
                    logger.info(f"Direct set_value succeeded for {self.uuid}")
                    return
                if hasattr(obj, 'notify'):
                    obj.notify(value_list)
                    self._notify_push_count += 1
                    logger.info(f"Direct notify(value) succeeded for {self.uuid}")
                    return
                # Attribute assignment fallback
                if hasattr(obj, 'value'):
                    setattr(obj, 'value', value_list)
                    self._notify_push_count += 1
                    logger.info(f"Direct setattr(value) succeeded for {self.uuid}")
                    return
            except Exception as e:
                logger.debug(f"Direct cached char update failed for {self.uuid}: {e}")
            # Continue to legacy peripheral method probing if direct failed
        attempted = False
        succeeded = False
        # Debug aid: ensure we're not accidentally pushing empty payloads
        if not isinstance(data, (bytes, bytearray)) or len(data) == 0:
            logger.debug(f"update_value called with empty/invalid data for {self.uuid}")
        
        # Known method names across BlueZero versions
        for method_name in (
            'update_characteristic_value',  # hypothetical newer API
            'update_char_value',            # observed in some forks
            'update_characteristic',        # legacy naming
            'notify',                       # some bluezero versions
            'send_notify',                  # alternative naming
        ):
            if hasattr(periph, method_name):
                attempted = True
                try:
                    # Try keyword signature first
                    getattr(periph, method_name)(
                        srv_id=self._srv_id,
                        chr_id=self._chr_id,
                        value=value_list
                    )
                    logger.info(f"{method_name}(kw) succeeded for {self.uuid}")
                    succeeded = True
                    return
                except TypeError:
                    # Some variants may accept positional args only
                    try:
                        getattr(periph, method_name)(self._srv_id, self._chr_id, value_list)
                        logger.info(f"{method_name}(positional) succeeded for {self.uuid}")
                        succeeded = True
                        return
                    except Exception as inner:
                        logger.debug(f"{method_name} positional call failed for {self.uuid}: {inner}")
                except Exception as inner:
                    logger.debug(f"{method_name} failed for {self.uuid}: {inner}")
        if not succeeded:
            # Fallback: attempt generic characteristic store (best-effort)
            try:
                # Some implementations maintain internal dict: characteristics[(srv_id, chr_id)]['value']
                chars = getattr(periph, 'characteristics', None)
                if isinstance(chars, dict):
                    key = (self._srv_id, self._chr_id)
                    if key in chars:
                        try:
                            # Attempt common object-level methods or attributes
                            char_obj = chars[key]
                            # dict-like storage
                            if isinstance(char_obj, dict):
                                char_obj['value'] = value_list  # type: ignore[index]
                                logger.info(f"Fallback dict value set for {self.uuid}")
                                return
                            # object-like API
                            if hasattr(char_obj, 'notify'):
                                try:
                                    char_obj.notify(value_list)
                                    logger.info(f"Fallback char.notify succeeded for {self.uuid}")
                                    return
                                except Exception:
                                    pass
                            if hasattr(char_obj, 'set_value'):
                                try:
                                    char_obj.set_value(value_list)
                                    logger.info(f"Fallback char.set_value succeeded for {self.uuid}")
                                    return
                                except Exception:
                                    pass
                            if hasattr(char_obj, 'value'):
                                try:
                                    setattr(char_obj, 'value', value_list)
                                    logger.info(f"Fallback setattr(value) succeeded for {self.uuid}")
                                    return
                                except Exception:
                                    pass
                        except Exception:
                            pass
                
                # Deeper reflection: traverse services -> characteristics to find the object
                def _try_apply_to_char(obj) -> bool:
                    try:
                        if hasattr(obj, 'set_value'):
                            obj.set_value(value_list)
                            logger.info(f"Reflection set_value succeeded for {self.uuid}")
                            return True
                        if hasattr(obj, 'notify'):
                            obj.notify(value_list)
                            logger.info(f"Reflection notify succeeded for {self.uuid}")
                            return True
                        if hasattr(obj, 'value'):
                            setattr(obj, 'value', value_list)
                            logger.info(f"Reflection setattr(value) succeeded for {self.uuid}")
                            return True
                    except Exception as _:
                        return False
                    return False

                # 1) Look for services container
                services = (
                    getattr(periph, 'services', None)
                    or getattr(periph, '_services', None)
                    or getattr(periph, 'gatt_services', None)
                )
                service_obj = None
                if isinstance(services, dict):
                    service_obj = services.get(self._srv_id) or services.get(str(self._srv_id))
                elif isinstance(services, (list, tuple)):
                    # srv_id is 1-based; adjust if list
                    idx = max(0, int(self._srv_id) - 1) if self._srv_id else 0
                    if 0 <= idx < len(services):
                        service_obj = services[idx]

                # 2) From service, get characteristics
                char_obj = None
                if service_obj is not None:
                    candidates = (
                        getattr(service_obj, 'characteristics', None)
                        or getattr(service_obj, 'chars', None)
                        or getattr(service_obj, '_characteristics', None)
                    )
                    if isinstance(candidates, dict):
                        # Try by various keys
                        char_obj = candidates.get(self._chr_id) or candidates.get(str(self._chr_id))
                        if not char_obj:
                            # Some dicts keyed by uuid
                            for k, v in candidates.items():
                                try:
                                    if str(getattr(v, 'uuid', '')).lower() == str(self.uuid).lower():
                                        char_obj = v
                                        break
                                except Exception:
                                    continue
                    elif isinstance(candidates, (list, tuple)):
                        idx = max(0, int(self._chr_id) - 1) if self._chr_id else 0
                        if 0 <= idx < len(candidates):
                            char_obj = candidates[idx]

                    if char_obj and _try_apply_to_char(char_obj):
                        return

                # 3) Broad search: scan periph attributes for containers holding a matching uuid
                try:
                    for attr_name in dir(periph):
                        if attr_name.startswith('_'):
                            continue
                        try:
                            val = getattr(periph, attr_name)
                        except Exception:
                            continue
                        # Only inspect containers
                        if isinstance(val, dict):
                            for _, v in val.items():
                                try:
                                    if str(getattr(v, 'uuid', '')).lower() == str(self.uuid).lower():
                                        if _try_apply_to_char(v):
                                            logger.info(f"Reflection via periph.{attr_name} container succeeded for {self.uuid}")
                                            return
                                except Exception:
                                    continue
                        elif isinstance(val, (list, tuple)):
                            for v in val:
                                try:
                                    if str(getattr(v, 'uuid', '')).lower() == str(self.uuid).lower():
                                        if _try_apply_to_char(v):
                                            logger.info(f"Reflection via periph.{attr_name} list succeeded for {self.uuid}")
                                            return
                                except Exception:
                                    continue
                except Exception:
                    pass
            except Exception:
                pass
        if attempted and not succeeded:
            logger.warning(f"No compatible BlueZero update method succeeded for {self.uuid} (attempted direct methods)")
        elif not attempted:
            logger.debug(f"No BlueZero update methods found for {self.uuid}; fallbacks also failed")

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