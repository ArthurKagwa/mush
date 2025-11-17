"""Config Version Characteristic

Read/Notify characteristic exposing current configuration version
metadata (sha256 hash, last_modified, size).
"""

from __future__ import annotations

import logging
from ..base import NotifyCharacteristic
from ..config_manager import get_config_manager

logger = logging.getLogger(__name__)


def _uuid_from_env(default: str) -> str:
    import os
    return os.environ.get("MUSHPI_BLE_CONFIG_VERSION_CHAR_UUID", default)


CONFIG_VERSION_CHAR_UUID = _uuid_from_env("12345678-1234-5678-1234-56789abcde10")


class ConfigVersionCharacteristic(NotifyCharacteristic):
    def __init__(self, service=None, simulation_mode: bool = False):
        self._manager = get_config_manager()
        super().__init__(CONFIG_VERSION_CHAR_UUID, service, simulation_mode)

    def _handle_read(self, options) -> bytes:
        try:
            version = self._manager.get_version().to_dict()
            payload = f"{{\"sha256\":\"{version['sha256']}\",\"last_modified\":\"{version['last_modified']}\",\"size\":{version['size']}}}".encode("utf-8")
            return payload
        except Exception as e:
            logger.error(f"Error reading config version: {e}")
            return b"{}"

    def notify_latest(self):
        try:
            data = self._handle_read({})
            self.update_value(data)
        except Exception as e:
            logger.debug(f"Failed to notify version: {e}")

__all__ = ["ConfigVersionCharacteristic", "CONFIG_VERSION_CHAR_UUID"]
