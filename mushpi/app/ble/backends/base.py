"""
BLE Backend Interface (Milestone 1)

Defines the interface for pluggable BLE backends and provides a Null backend
that performs no operations. The existing BlueZero-based implementation in
app/ble/service.py remains authoritative until the new backend is implemented
and wired in subsequent milestones.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Callable, Dict, Any, Optional, Set
import logging

logger = logging.getLogger(__name__)


class BaseBLEBackend(ABC):
    """Abstract BLE backend contract.

    Methods mirror the plan in mushpi/PLAN.md and are intentionally minimal
    for milestone 1 to avoid behavior changes in the current service layer.
    """

    @abstractmethod
    def initialize(self) -> bool:
        """Prepare resources. Should be non-blocking."""

    @abstractmethod
    def start(self) -> bool:
        """Start backend services (e.g., register, advertise)."""

    @abstractmethod
    def stop(self) -> None:
        """Stop and clean up resources."""

    @abstractmethod
    def set_callbacks(self, callbacks: Dict[str, Callable]) -> None:
        """Set data and control callbacks matching current service expectations."""

    @abstractmethod
    def notify(self, characteristic_name: str, devices: Optional[Set[str]] = None) -> None:
        """Schedule or send a notification (no-op in milestone 1)."""

    @abstractmethod
    def update_advertising_name(self, name: Optional[str] = None) -> None:
        """Optionally update advertising data (no-op in milestone 1)."""

    @abstractmethod
    def get_status(self) -> Dict[str, Any]:
        """Return backend status for logging/diagnostics."""


class NullBLEBackend(BaseBLEBackend):
    """No-op backend used for milestone 1 to avoid behavior changes.

    The current BlueZero-based path in service.py continues to perform all
    operations. This backend only logs and stores callbacks.
    """

    def __init__(self) -> None:
        self._callbacks: Dict[str, Callable] = {}

    def initialize(self) -> bool:
        logger.debug("NullBLEBackend.initialize() called - no action")
        return True

    def start(self) -> bool:
        logger.debug("NullBLEBackend.start() called - no action")
        return True

    def stop(self) -> None:
        logger.debug("NullBLEBackend.stop() called - no action")

    def set_callbacks(self, callbacks: Dict[str, Callable]) -> None:
        self._callbacks = dict(callbacks or {})
        logger.debug("NullBLEBackend callbacks set: %s", list(self._callbacks.keys()))

    def notify(self, characteristic_name: str, devices: Optional[Set[str]] = None) -> None:
        logger.debug("NullBLEBackend.notify(%s) - no action", characteristic_name)

    def update_advertising_name(self, name: Optional[str] = None) -> None:
        logger.debug("NullBLEBackend.update_advertising_name(%s) - no action", name)

    def get_status(self) -> Dict[str, Any]:
        return {
            'backend': 'null',
            'callbacks': list(self._callbacks.keys()),
        }


__all__ = [
    'BaseBLEBackend',
    'NullBLEBackend',
]
