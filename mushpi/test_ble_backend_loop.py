"""Tests for BLEAsyncLoop and BluezDbusBackend skeleton (Milestone 2).

These tests avoid requiring a real D-Bus daemon. They focus on loop lifecycle
and backend status fields. If dbus-next is unavailable the backend should
still initialize and start without raising.
"""
from __future__ import annotations

import time
import os

from app.ble.backends.bluez_dbus import BluezDbusBackend, BLEAsyncLoop  # type: ignore


def test_ble_async_loop_start_stop():
    loop_owner = BLEAsyncLoop()
    assert loop_owner.start() is True
    status_running = loop_owner.get_status()
    assert status_running['thread_alive'] is True
    assert status_running['loop_running'] is True
    loop_owner.stop(timeout=1.0)
    status_stopped = loop_owner.get_status()
    # Thread may be joined; loop_running should be False after stop
    assert status_stopped['loop_running'] is False


def test_bluez_dbus_backend_basic_lifecycle():
    # Force backend selection env for clarity (not strictly needed here)
    os.environ['MUSHPI_BLE_BACKEND'] = 'bluez-dbus'
    backend = BluezDbusBackend()
    assert backend.initialize() is True
    pre_status = backend.get_status()
    assert pre_status['initialized'] is True
    assert pre_status['started'] is False
    assert backend.start() is True
    started_status = backend.get_status()
    assert started_status['started'] is True
    # notify should be a no-op
    backend.notify('status_flags')
    backend.stop()
    final_status = backend.get_status()
    assert final_status['started'] is False


if __name__ == '__main__':  # rudimentary manual run support
    test_ble_async_loop_start_stop()
    test_bluez_dbus_backend_basic_lifecycle()
    print('Milestone 2 backend skeleton tests passed')
