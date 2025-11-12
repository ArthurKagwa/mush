"""Backend selection utilities for BLE implementations.

Milestones:
  - Milestone 1: Interface + Null backend (no behavior change)
  - Milestone 2: Introduce dbus-next skeleton + asyncio loop thread (no GATT yet)

This module now attempts to load the BlueZ D-Bus backend skeleton when
`MUSHPI_BLE_BACKEND=bluez-dbus`. If import fails (e.g., missing dependency
`dbus-next`), it falls back to the Null backend without raising.

Environment Variables:
  MUSHPI_BLE_BACKEND = 'bluezero' | 'bluez-dbus' (default: 'bluezero')
"""

from .base import BaseBLEBackend, NullBLEBackend
import os
import logging

logger = logging.getLogger(__name__)


def _load_bluez_dbus_backend() -> BaseBLEBackend:
    """Attempt to import and instantiate the BlueZ D-Bus backend skeleton.

    Returns a NullBLEBackend on any failure to keep runtime stable.
    """
    try:
        from .bluez_dbus import BluezDbusBackend  # type: ignore
        logger.debug("bluez_dbus backend module imported successfully")
        return BluezDbusBackend()
    except Exception as e:  # broad: intentional safe fallback
        logger.warning("Falling back to NullBLEBackend (bluez_dbus import failed: %s)", e)
        return NullBLEBackend()


def select_backend() -> tuple[str, BaseBLEBackend]:
    """Select BLE backend instance based on environment variable.

    Returns:
      (backend_name, backend_instance)
    """
    name = os.environ.get('MUSHPI_BLE_BACKEND', 'bluezero').strip().lower()
    if name not in ('bluezero', 'bluez-dbus'):
        logger.warning("Invalid MUSHPI_BLE_BACKEND=%s; falling back to 'bluezero'", name)
        name = 'bluezero'

    if name == 'bluez-dbus':
        backend = _load_bluez_dbus_backend()
        logger.info("BLE backend selected: bluez-dbus (skeleton active)")
    else:
        backend = NullBLEBackend()
        logger.info("BLE backend selected: bluezero (legacy path remains authoritative)")

    return name, backend


__all__ = [
    'BaseBLEBackend',
    'NullBLEBackend',
    'select_backend',
]
