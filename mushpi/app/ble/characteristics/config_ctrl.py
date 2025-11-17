"""Config Control Characteristic

Handles small JSON control frames: HELLO, GET, PUT_BEGIN, PUT_COMMIT, ABORT.
Streams responses via OUT characteristic (notify) and delegates version
updates to version characteristic.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
from typing import Optional

from ..base import ReadWriteCharacteristic
from ..config_manager import get_config_manager, ConfigValidationError
from ..config_protocol import to_json_line, generate_tx_id, InboundTransfer, RateLimiter
from .config_version import ConfigVersionCharacteristic

logger = logging.getLogger(__name__)


def _uuid_from_env(default: str, env_key: str) -> str:
    return os.environ.get(env_key, default)


CONFIG_CTRL_CHAR_UUID = _uuid_from_env("12345678-1234-5678-1234-56789abcde11", "MUSHPI_BLE_CONFIG_CTRL_CHAR_UUID")


class ConfigControlCharacteristic(ReadWriteCharacteristic):
    def __init__(self, service=None, simulation_mode: bool = False, out_char=None, version_char: Optional[ConfigVersionCharacteristic] = None):
        self._manager = get_config_manager()
        self._out_char = out_char  # notify/read streaming characteristic
        self._version_char = version_char
        self._active: Optional[InboundTransfer] = None
        self._rate = RateLimiter(int(os.environ.get("MUSHPI_BLE_CONFIG_RATE_LIMIT_MS", "2000")))
        self._write_pin = os.environ.get("MUSHPI_BLE_CONFIG_WRITE_PIN")
        self._auth_required = os.environ.get("MUSHPI_BLE_CONFIG_WRITE_AUTH", "optional").lower() == "required"
        super().__init__(CONFIG_CTRL_CHAR_UUID, service, simulation_mode)

    # Helper to push a response via OUT characteristic
    def _send(self, obj: dict):
        if self._out_char is None:
            logger.debug("OUT characteristic not set; dropping frame")
            return
        try:
            self._out_char.queue_frame(obj)
        except Exception as e:
            logger.debug(f"Could not queue frame: {e}")

    def _handle_read(self, options) -> bytes:
        # Control characteristic is not used for read payload beyond minimal status
        status = {"busy": bool(self._active), "auth": "required" if self._auth_required else "optional"}
        return json.dumps(status).encode("utf-8")

    def _handle_write(self, value: bytes, options):
        try:
            text = value.decode("utf-8", errors="ignore").strip()
            if not text:
                return
            frame = json.loads(text)
        except Exception:
            logger.warning("Invalid JSON control frame received")
            return

        op = frame.get("op")
        if op == "HELLO":
            self._handle_hello()
        elif op == "GET":
            self._handle_get(frame)
        elif op == "PUT_BEGIN":
            self._handle_put_begin(frame)
        elif op == "PUT_COMMIT":
            self._handle_put_commit(frame)
        elif op == "ABORT":
            self._handle_abort(frame)
        else:
            self._send({"op": "ERROR", "err": "bad_op"})

    def _handle_hello(self):
        version = self._manager.get_version().to_dict()
        mtu_hint = 180  # Static hint; actual MTU negotiation not exposed here
        max_chunk = int(os.environ.get("MUSHPI_BLE_CONFIG_MAX_CHUNK", "180"))
        self._send({"op": "HELLO", "ok": True, "mtu": mtu_hint, "max_chunk": max_chunk, "version": version})

    def _handle_get(self, frame: dict):
        # Stream entire document via OUT
        try:
            obj, version = self._manager.read()
            raw = json.dumps(obj, separators=(",", ":")).encode("utf-8")
            sha = hashlib.sha256(raw).hexdigest()
            self._send({"op": "DATA_BEGIN", "path": "config", "total_len": len(raw), "sha256": sha})
            max_chunk = int(os.environ.get("MUSHPI_BLE_CONFIG_MAX_CHUNK", "180"))
            seq = 0
            for i in range(0, len(raw), max_chunk):
                chunk = raw[i:i+max_chunk]
                # We stream raw UTF-8 JSON slices (not base64) for efficiency.
                # Client should concatenate "data" fields to reconstruct.
                self._send({"op": "DATA_CHUNK", "seq": seq, "data": chunk.decode("utf-8")})
                seq += 1
            self._send({"op": "DATA_END", "sha256": sha})
        except Exception as e:
            logger.error(f"GET error: {e}")
            self._send({"op": "ERROR", "err": "io_error"})

    def _handle_put_begin(self, frame: dict):
        if self._active:
            self._send({"op": "ERROR", "err": "busy"})
            return
        if not self._rate.allow():
            self._send({"op": "ERROR", "err": "rate_limited"})
            return
        if self._auth_required and self._write_pin and frame.get("pin") != self._write_pin:
            self._send({"op": "ERROR", "err": "unauthorized"})
            return
        total_len = frame.get("total_len")
        sha256 = frame.get("sha256")
        if not isinstance(total_len, int) or total_len <= 0 or not isinstance(sha256, str):
            self._send({"op": "ERROR", "err": "bad_request"})
            return
        tx_id = generate_tx_id()
        self._active = InboundTransfer(tx_id=tx_id, total_len=total_len, sha256=sha256)
        self._send({"op": "PUT_BEGIN", "ok": True, "tx_id": tx_id})

    def _handle_put_commit(self, frame: dict):
        if not self._active or frame.get("tx_id") != self._active.tx_id:
            self._send({"op": "ERROR", "err": "no_active"})
            return
        # Read temp bytes
        try:
            if self._active.received != self._active.total_len:
                self._send({"op": "PUT_RESULT", "tx_id": self._active.tx_id, "ok": False, "err": "length_mismatch"})
                self._active = None
                return
            with open(self._active.tmp_path, "rb") as f:
                payload = f.read()
            calc_sha = hashlib.sha256(payload).hexdigest()
            if calc_sha != self._active.sha256:
                self._send({"op": "PUT_RESULT", "tx_id": self._active.tx_id, "ok": False, "err": "checksum_mismatch"})
                self._cleanup_tmp()
                self._active = None
                return
            obj = json.loads(payload.decode("utf-8"))
            version = self._manager.write(obj).to_dict()
            self._send({"op": "PUT_RESULT", "tx_id": self._active.tx_id, "ok": True, "version": version})
            if self._version_char:
                self._version_char.notify_latest()
        except ConfigValidationError as ve:
            self._send({"op": "PUT_RESULT", "tx_id": self._active.tx_id, "ok": False, "err": "schema_validation_failed", "details": str(ve)})
        except Exception as e:
            logger.error(f"PUT_COMMIT error: {e}")
            self._send({"op": "PUT_RESULT", "tx_id": self._active.tx_id, "ok": False, "err": "io_error"})
        finally:
            self._cleanup_tmp()
            self._active = None

    def _handle_abort(self, frame: dict):
        if self._active and frame.get("tx_id") == self._active.tx_id:
            self._cleanup_tmp()
            self._send({"op": "ABORT", "ok": True, "tx_id": self._active.tx_id})
            self._active = None
        else:
            self._send({"op": "ERROR", "err": "no_active"})

    def _cleanup_tmp(self):
        if self._active and self._active.tmp_path:
            try:
                os.remove(self._active.tmp_path)
            except Exception:
                pass

    # Called by inbound chunk characteristic
    def ingest_chunk(self, tx_id: str, seq: int, data: bytes):
        if not self._active or tx_id != self._active.tx_id:
            return {"op": "ERROR", "err": "no_active"}
        if self._active.tmp_path is None:
            # Create temp path lazily
            self._active.tmp_path = str(self._manager.path) + f".put.{self._active.tx_id}.tmp"
            try:
                with open(self._active.tmp_path, "wb"):
                    pass
            except Exception as e:
                logger.error(f"Temp file create failed: {e}")
                return {"op": "ERROR", "err": "io_error"}
        try:
            with open(self._active.tmp_path, "ab") as f:
                f.write(data)
            self._active.received += len(data)
            if self._active.received > self._active.total_len:
                return {"op": "ERROR", "err": "overflow"}
            return {"op": "ACK", "tx_id": tx_id, "seq": seq}
        except Exception as e:
            logger.error(f"Chunk ingest error: {e}")
            return {"op": "ERROR", "err": "io_error"}

__all__ = ["ConfigControlCharacteristic", "CONFIG_CTRL_CHAR_UUID"]
