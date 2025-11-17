"""Config Outbound Stream Characteristic

Notify/Read characteristic that the server uses to push JSON frames back
to clients (HELLO, DATA_*, ACK, PUT_RESULT, ERROR). We maintain a small
ring buffer of last frames so reads can fetch the most recent state if
notifications were missed.
"""

from __future__ import annotations

import json
import logging
import os
from collections import deque
from typing import Deque, Dict, Any

from ..base import NotifyCharacteristic

logger = logging.getLogger(__name__)


def _uuid_from_env(default: str) -> str:
    return os.environ.get("MUSHPI_BLE_CONFIG_OUT_CHAR_UUID", default)


CONFIG_OUT_CHAR_UUID = _uuid_from_env("12345678-1234-5678-1234-56789abcde13")


class ConfigOutCharacteristic(NotifyCharacteristic):
    def __init__(self, service=None, simulation_mode: bool = False):
        self._buffer: Deque[Dict[str, Any]] = deque(maxlen=16)
        super().__init__(CONFIG_OUT_CHAR_UUID, service, simulation_mode)

    def _handle_read(self, options) -> bytes:
        # Return the last frame (or empty)
        if self._buffer:
            try:
                return json.dumps(self._buffer[-1], separators=(",", ":")).encode("utf-8")
            except Exception:
                return b"{}"
        return b"{}"

    def queue_frame(self, frame: Dict[str, Any]):
        try:
            self._buffer.append(frame)
            data = json.dumps(frame, separators=(",", ":")).encode("utf-8")
            self.update_value(data)
        except Exception as e:
            logger.debug(f"Failed to queue/notify frame: {e}")

__all__ = ["ConfigOutCharacteristic", "CONFIG_OUT_CHAR_UUID"]
