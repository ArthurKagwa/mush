"""Config Inbound Chunk Characteristic

Write-only characteristic receiving chunk frames used during PUT.
Each write is a UTF-8 JSON object: { op: "CHUNK", tx_id, seq, data_b64 }
"""

from __future__ import annotations

import base64
import json
import logging
import os

from ..base import WriteOnlyCharacteristic
from .config_ctrl import ConfigControlCharacteristic

logger = logging.getLogger(__name__)


def _uuid_from_env(default: str) -> str:
    return os.environ.get("MUSHPI_BLE_CONFIG_IN_CHAR_UUID", default)


CONFIG_IN_CHAR_UUID = _uuid_from_env("12345678-1234-5678-1234-56789abcde12")


class ConfigInCharacteristic(WriteOnlyCharacteristic):
    def __init__(self, service=None, simulation_mode: bool = False, ctrl_char: ConfigControlCharacteristic | None = None, out_char=None):
        self._ctrl = ctrl_char
        self._out = out_char
        super().__init__(CONFIG_IN_CHAR_UUID, service, simulation_mode)

    def _handle_write(self, value: bytes, options):  # noqa: D401
        try:
            text = value.decode("utf-8", errors="ignore").strip()
            if not text:
                return
            frame = json.loads(text)
            if frame.get("op") != "CHUNK":
                return
            tx_id = frame.get("tx_id")
            seq = frame.get("seq")
            data_b64 = frame.get("data_b64")
            if not all([tx_id, isinstance(seq, int), isinstance(data_b64, str)]):
                return
            try:
                data = base64.b64decode(data_b64.encode("ascii"))
            except Exception:
                return
            if self._ctrl is None:
                return
            response = self._ctrl.ingest_chunk(tx_id, seq, data)
            if response and self._out:
                try:
                    self._out.queue_frame(response)
                except Exception:
                    pass
        except Exception as e:
            logger.debug(f"Chunk write error: {e}")

__all__ = ["ConfigInCharacteristic", "CONFIG_IN_CHAR_UUID"]
