"""
Actuator Status Characteristic

Exposes current actuator (relay) ON/OFF states as a compact bitfield.
Supports read and notify operations.
"""

import logging
from typing import Optional, Callable, Set

from ..base import NotifyCharacteristic
from ...models.ble_dataclasses import ACTUATOR_STATUS_UUID, ActuatorBits
from ..serialization import ActuatorStatusSerializer

logger = logging.getLogger(__name__)


class ActuatorStatusCharacteristic(NotifyCharacteristic):
    """Actuator status characteristic (read/notify)"""

    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize actuator status characteristic

        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        # Data and callback must be set before calling super().__init__
        self._bits: int = 0
        self._fan_reason: int = 0
        self._mist_reason: int = 0
        self._light_reason: int = 0
        self._heater_reason: int = 0
        self._get_control_data: Optional[Callable[[], Optional[dict]]] = None

        super().__init__(ACTUATOR_STATUS_UUID, service, simulation_mode)

    # ----------------- Public API -----------------
    def set_control_callback(self, get_callback: Callable[[], Optional[dict]]):
        """Set callback to fetch current control/relay state

        The callback should return a dict that contains:
          - fan: whether exhaust fan is ON (bool)
          - mist: whether humidifier is ON (bool)
          - light: whether grow light is ON (bool)
          - heater: whether heater is ON (bool)
          - fan_reason: reason code for fan state (int 0-255)
          - mist_reason: reason code for mist state (int 0-255)
          - light_reason: reason code for light state (int 0-255)
          - heater_reason: reason code for heater state (int 0-255)
        """
        self._get_control_data = get_callback

    def update_from_dict(self, control_data: dict):
        """Update internal bitfield from a dict of booleans"""
        try:
            bits = 0
            if control_data.get('light', False):
                bits |= int(ActuatorBits.LIGHT)
            if control_data.get('fan', False):
                bits |= int(ActuatorBits.FAN)
            if control_data.get('mist', False):
                bits |= int(ActuatorBits.MIST)
            if control_data.get('heater', False):
                bits |= int(ActuatorBits.HEATER)
            self._bits = bits
            # Store reason codes for later packing
            self._fan_reason = control_data.get('fan_reason', 0)
            self._mist_reason = control_data.get('mist_reason', 0)
            self._light_reason = control_data.get('light_reason', 0)
            self._heater_reason = control_data.get('heater_reason', 0)
        except Exception as e:
            logger.debug(f"Failed to update actuator bits from dict: {e}")

    def get_bits(self) -> int:
        return self._bits

    # ----------------- BLE Handlers -----------------
    def _handle_read(self, options) -> bytes:
        """Read callback for actuator status

        Returns packed 6-byte payload (2 bytes status bits + 4 bytes reason codes).
        """
        try:
            # Refresh from callback if provided
            if self._get_control_data:
                data = self._get_control_data()
                if data:
                    self.update_from_dict(data)

            packed = ActuatorStatusSerializer.pack(
                self._bits,
                self._fan_reason,
                self._mist_reason,
                self._light_reason,
                self._heater_reason
            )
            # Log at INFO so it shows up in normal Pi logs when debugging dashboard issues
            logger.info(
                "BLE actuator read: bits=0x%04X (LIGHT=%s,FAN=%s,MIST=%s,HEATER=%s) "
                "reasons=[fan:%d,mist:%d,light:%d,heater:%d]",
                self._bits,
                bool(self._bits & int(ActuatorBits.LIGHT)),
                bool(self._bits & int(ActuatorBits.FAN)),
                bool(self._bits & int(ActuatorBits.MIST)),
                bool(self._bits & int(ActuatorBits.HEATER)),
                self._fan_reason,
                self._mist_reason,
                self._light_reason,
                self._heater_reason,
            )
            return packed
        except Exception as e:
            logger.error(f"Error reading actuator status: {e}")
            return b"\x00" * ActuatorStatusSerializer.SIZE

    def notify_update(self, connected_devices: Set[str]):
        """Send notification with current actuator bits and reason codes to all devices"""
        if not connected_devices or self.simulation_mode:
            return
        try:
            data = ActuatorStatusSerializer.pack(
                self._bits,
                self._fan_reason,
                self._mist_reason,
                self._light_reason,
                self._heater_reason
            )
            for device in connected_devices:
                try:
                    self.notify(data, device)
                except Exception as e:
                    logger.debug(f"Actuator notify failed to {device}: {e}")
        except Exception as e:
            logger.error(f"Error notifying actuator status: {e}")
