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
        self._get_control_data: Optional[Callable[[], Optional[dict]]] = None

        super().__init__(ACTUATOR_STATUS_UUID, service, simulation_mode)

    # ----------------- Public API -----------------
    def set_control_callback(self, get_callback: Callable[[], Optional[dict]]):
        """Set callback to fetch current control/relay state

        The callback should return a dict that at least contains boolean fields:
          - fan: whether exhaust fan is ON
          - mist: whether humidifier is ON
          - light: whether grow light is ON
          - heater: whether heater is ON
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
        except Exception as e:
            logger.debug(f"Failed to update actuator bits from dict: {e}")

    def get_bits(self) -> int:
        return self._bits

    # ----------------- BLE Handlers -----------------
    def _handle_read(self, options) -> bytes:
        """Read callback for actuator status

        Returns packed 2-byte bitfield.
        """
        try:
            # Refresh from callback if provided
            if self._get_control_data:
                data = self._get_control_data()
                if data:
                    self.update_from_dict(data)

            packed = ActuatorStatusSerializer.pack(self._bits)
            logger.debug(f"BLE actuator read: bits=0x{self._bits:04X}")
            return packed
        except Exception as e:
            logger.error(f"Error reading actuator status: {e}")
            return b"\x00" * ActuatorStatusSerializer.SIZE

    def notify_update(self, connected_devices: Set[str]):
        """Send notification with current actuator bits to all devices"""
        if not connected_devices or self.simulation_mode:
            return
        try:
            data = ActuatorStatusSerializer.pack(self._bits)
            for device in connected_devices:
                try:
                    self.notify(data, device)
                except Exception as e:
                    logger.debug(f"Actuator notify failed to {device}: {e}")
        except Exception as e:
            logger.error(f"Error notifying actuator status: {e}")
