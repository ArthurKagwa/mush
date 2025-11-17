"""ConfigManager for stage configuration BLE access.

Provides atomic read/write with validation and version hashing for the
stage configuration JSON document. Avoids external dependencies by
using fcntl advisory locking (Linux / Raspberry Pi environment).

Environment variables (all optional, no hard-coded paths):
  MUSHPI_CONFIG_PATH                -> absolute/relative path to stage config JSON
  MUSHPI_BLE_CONFIG_MAX_DOC_SIZE    -> maximum allowed bytes (default 65536)

Version object exposed:
  {
     "sha256": str,
     "last_modified": iso8601 str (UTC),
     "size": int
  }

Validation (initial minimal schema):
  Required keys: species(str), stage(str), start_time(str ISO8601),
                 expected_days(int>0), mode(str in {'full','semi','manual'})
  thresholds: optional dict (if absent -> {})
"""

from __future__ import annotations

import json
import os
import hashlib
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Tuple

logger = logging.getLogger(__name__)

try:
    import fcntl  # type: ignore
except ImportError:  # pragma: no cover - non-linux
    fcntl = None  # type: ignore


ISO_FMT = "%Y-%m-%dT%H:%M:%S.%fZ"


def _utc_now_iso() -> str:
    return datetime.utcnow().replace(tzinfo=timezone.utc).isoformat().replace("+00:00", "Z")


@dataclass
class ConfigVersion:
    sha256: str
    last_modified: str
    size: int

    def to_dict(self) -> Dict[str, Any]:
        return {"sha256": self.sha256, "last_modified": self.last_modified, "size": self.size}


class ConfigValidationError(Exception):
    pass


class ConfigManager:
    """Manage stage configuration file with atomic writes and versioning."""

    def __init__(self, path: Path | None = None, max_size: int | None = None):
        """Initialize ConfigManager with optional path override
        
        Args:
            path: Optional override for config path
            max_size: Optional override for max document size
            
        If path is not provided, uses MUSHPI_STAGE_CONFIG_PATH from environment,
        falling back to 'data/stage_config.json' for backward compatibility.
        """
        env_path = os.environ.get("MUSHPI_STAGE_CONFIG_PATH")
        # Fallback to existing relative location for backward compatibility
        default_path = Path("data/stage_config.json")
        self.path = Path(path or env_path or default_path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.max_size = max_size or int(os.environ.get("MUSHPI_BLE_CONFIG_MAX_DOC_SIZE", "65536"))

    # --------------------------- Public API ---------------------------
    def read(self) -> Tuple[Dict[str, Any], ConfigVersion]:
        data = self._read_bytes()
        obj = json.loads(data.decode("utf-8")) if data else {}
        version = self._compute_version_bytes(data)
        return obj, version

    def write(self, new_obj: Dict[str, Any]) -> ConfigVersion:
        self._validate(new_obj)
        encoded = json.dumps(new_obj, indent=2, sort_keys=True).encode("utf-8")
        if len(encoded) > self.max_size:
            raise ConfigValidationError(f"Document exceeds max size {self.max_size}")
        tmp = self.path.with_suffix(self.path.suffix + f".tx.{os.getpid()}")
        try:
            with open(tmp, "wb") as f:
                if fcntl:
                    try:
                        fcntl.flock(f, fcntl.LOCK_EX)
                    except Exception:
                        logger.debug("Advisory lock failed on temp file (continuing)")
                f.write(encoded)
                f.flush()
                os.fsync(f.fileno())
            # Acquire lock on target before replace (best-effort)
            if fcntl and self.path.exists():
                try:
                    with open(self.path, "rb") as lf:
                        fcntl.flock(lf, fcntl.LOCK_EX)
                except Exception:
                    logger.debug("Could not lock target file before replace (continuing)")
            os.replace(tmp, self.path)
        finally:
            if tmp.exists():
                try:
                    tmp.unlink()
                except Exception:
                    pass
        return self._compute_version_bytes(encoded)

    def get_version(self) -> ConfigVersion:
        data = self._read_bytes()
        return self._compute_version_bytes(data)

    # --------------------------- Internals ----------------------------
    def _read_bytes(self) -> bytes:
        if not self.path.exists():
            logger.warning(f"Config file missing: {self.path}; returning empty object")
            return b"{}"
        with open(self.path, "rb") as f:
            if fcntl:
                try:
                    fcntl.flock(f, fcntl.LOCK_SH)
                except Exception:
                    logger.debug("Shared lock failed (continuing)")
            data = f.read(self.max_size + 1)
            if len(data) > self.max_size:
                raise ConfigValidationError("Stored document exceeds configured max size")
            return data

    def _compute_version_bytes(self, data: bytes) -> ConfigVersion:
        sha = hashlib.sha256(data).hexdigest()
        try:
            stat = self.path.stat()
            mtime_iso = datetime.utcfromtimestamp(stat.st_mtime).replace(tzinfo=timezone.utc).isoformat().replace("+00:00", "Z")
            size = stat.st_size
        except Exception:
            mtime_iso = _utc_now_iso()
            size = len(data)
        return ConfigVersion(sha256=sha, last_modified=mtime_iso, size=size)

    def _validate(self, obj: Dict[str, Any]) -> None:
        required_str = ["species", "stage", "start_time"]
        for k in required_str:
            if k not in obj or not isinstance(obj[k], str) or not obj[k].strip():
                raise ConfigValidationError(f"Missing/invalid string field: {k}")
        if "expected_days" not in obj or not isinstance(obj["expected_days"], int) or obj["expected_days"] <= 0:
            raise ConfigValidationError("expected_days must be positive int")
        if "mode" not in obj or obj["mode"] not in {"full", "semi", "manual"}:
            raise ConfigValidationError("mode must be one of full|semi|manual")
        # start_time parse
        try:
            datetime.fromisoformat(obj["start_time"].replace("Z", "+00:00"))
        except Exception:
            raise ConfigValidationError("start_time invalid ISO8601")
        if "thresholds" in obj and not isinstance(obj["thresholds"], dict):
            raise ConfigValidationError("thresholds must be an object if present")
        # Accept additional keys for forward compatibility


# Singleton helper (lazy) so multiple characteristics share same instance
_config_manager_singleton: ConfigManager | None = None


def get_config_manager() -> ConfigManager:
    global _config_manager_singleton
    if _config_manager_singleton is None:
        _config_manager_singleton = ConfigManager()
    return _config_manager_singleton

__all__ = ["ConfigManager", "ConfigValidationError", "ConfigVersion", "get_config_manager"]
