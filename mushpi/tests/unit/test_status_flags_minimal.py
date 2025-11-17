"""Minimal tests for Status Flags serialization and backend notify path.

These do not require a running BlueZ or dbus-next installation.
"""
from __future__ import annotations

from app.ble.serialization import StatusFlagsSerializer
from app.ble.backends.bluez_dbus import BluezDbusBackend  # type: ignore


def test_status_flags_serializer_pack_size():
    data = StatusFlagsSerializer.pack(0x00FF)
    assert isinstance(data, (bytes, bytearray))
    assert len(data) == StatusFlagsSerializer.SIZE == 4


def test_backend_notify_ignored_when_minimal_disabled():
    be = BluezDbusBackend()
    assert be.initialize() is True
    assert be.start() is True
    # By default minimal GATT is disabled via env; notify should be a no-op
    be.notify('status_flags')
    be.stop()


if __name__ == '__main__':
    test_status_flags_serializer_pack_size()
    test_backend_notify_ignored_when_minimal_disabled()
    print('Status Flags minimal tests passed')
