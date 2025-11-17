"""BLE Config Protocol Helpers

Defines small JSON frame helpers and chunking utilities for sending
and receiving configuration documents over GATT characteristics.

Frames are UTF-8 JSON, newline-terminated for easy parsing by clients.
We do not keep large buffers in memory inside characteristics; instead,
we store incoming chunks to a temp file handled by ConfigManager.
"""

from __future__ import annotations

import base64
import json
import logging
import os
import time
import uuid
from dataclasses import dataclass
from typing import Any, Dict

logger = logging.getLogger(__name__)


def generate_tx_id() -> str:
    return uuid.uuid4().hex


def to_json_line(obj: Dict[str, Any]) -> bytes:
    return (json.dumps(obj, separators=(",", ":")) + "\n").encode("utf-8")


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def b64dec(txt: str) -> bytes:
    return base64.b64decode(txt.encode("ascii"))


@dataclass
class InboundTransfer:
    tx_id: str
    total_len: int
    sha256: str
    received: int = 0
    tmp_path: str | None = None
    start_ts: float = time.time()


class RateLimiter:
    def __init__(self, min_ms: int):
        self.min_ms = max(0, int(min_ms))
        self._last = 0.0

    def allow(self) -> bool:
        now = time.time()
        if (now - self._last) * 1000.0 >= self.min_ms:
            self._last = now
            return True
        return False
