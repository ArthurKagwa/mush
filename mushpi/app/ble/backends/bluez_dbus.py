"""BlueZ D-Bus BLE backend skeleton (Milestone 2)

This module introduces an asyncio-based skeleton backend using dbus-next.
No GATT service/characteristics are registered yet (that arrives in Milestone 3).
It provides:
  - BLEAsyncLoop: dedicated thread running an asyncio event loop
  - BluezDbusBackend: implements BaseBLEBackend lifecycle with loop + bus

Behavior intentionally limited so existing BlueZero path remains authoritative
for BLE functionality until later milestones. Selecting this backend via env:
  MUSHPI_BLE_BACKEND=bluez-dbus
will start the loop thread and prepare a D-Bus connection if possible, but
notifications / advertising / GATT operations are placeholders.

Environment variables used (with safe defaults):
  MUSHPI_DBUS_BUS_TIMEOUT_MS (int, default 2500)
  MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS (int, default 1500)
  MUSHPI_BLE_ADV_ENABLE (bool, default True)  # reserved for future milestones

All configuration is read at initialize/start; no hard-coded constants beyond
internal fallback defaults.
"""

from __future__ import annotations

import asyncio
import logging
import os
import threading
import time
from typing import Callable, Dict, Any, Optional, Set, List

from .base import BaseBLEBackend

try:  # optional dependency handling
    from dbus_next.aio import MessageBus
    from dbus_next import BusType, Variant
    from dbus_next.service import (ServiceInterface, method as dbus_method,
                                   dbus_property, signal as dbus_signal)
    _DBUS_AVAILABLE = True
except Exception:  # pragma: no cover - import guard
    _DBUS_AVAILABLE = False

logger = logging.getLogger(__name__)


def _get_env_int(name: str, default: int) -> int:
    val = os.environ.get(name, '').strip()
    if not val:
        return default
    try:
        parsed = int(val)
        return parsed if parsed >= 0 else default
    except ValueError:
        logger.warning("Invalid int for %s=%s; using default %d", name, val, default)
        return default


def _get_env_bool(name: str, default: bool) -> bool:
    val = os.environ.get(name, '').strip().lower()
    if not val:
        return default
    if val in ('1', 'true', 'yes', 'on'):
        return True
    if val in ('0', 'false', 'no', 'off'):
        return False
    logger.warning("Invalid bool for %s=%s; using default %s", name, val, default)
    return default


class BLEAsyncLoop:
    """Owns an asyncio event loop in a dedicated thread.

    Provides thread-safe execution helpers and graceful shutdown.
    """

    def __init__(self) -> None:
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._thread: Optional[threading.Thread] = None
        self._started = threading.Event()
        self._stopped = threading.Event()
        self._creation_ts = time.time()

    @property
    def loop(self) -> Optional[asyncio.AbstractEventLoop]:
        return self._loop

    def start(self) -> bool:
        if self._thread and self._thread.is_alive():
            logger.debug("BLEAsyncLoop already running")
            return True

        def _run_loop():
            try:
                self._loop = asyncio.new_event_loop()
                asyncio.set_event_loop(self._loop)
                self._started.set()
                logger.info("BLEAsyncLoop event loop started")
                self._loop.run_forever()
            except Exception as e:
                logger.error("BLEAsyncLoop failed: %s", e)
            finally:
                if self._loop:
                    # Cancel remaining tasks for cleanliness
                    tasks = [t for t in asyncio.all_tasks(self._loop) if not t.done()]
                    for t in tasks:
                        t.cancel()
                    if tasks:
                        self._loop.run_until_complete(asyncio.gather(*tasks, return_exceptions=True))
                    self._loop.close()
                self._stopped.set()
                logger.info("BLEAsyncLoop event loop stopped")

        self._thread = threading.Thread(target=_run_loop, name="BLEAsyncLoop", daemon=True)
        self._thread.start()
        started = self._started.wait(timeout=2.0)
        if not started:
            logger.error("BLEAsyncLoop did not start within timeout")
            return False
        return True

    def stop(self, timeout: float) -> None:
        if not self._loop or not self._thread:
            return
        try:
            if self._loop.is_running():
                self._loop.call_soon_threadsafe(self._loop.stop)
            self._stopped.wait(timeout=timeout)
        finally:
            if self._thread.is_alive():
                logger.debug("Joining BLEAsyncLoop thread")
                self._thread.join(timeout=timeout)

    def run_coro_threadsafe(self, coro) -> Optional[asyncio.Future]:
        if not self._loop or not self._loop.is_running():
            logger.warning("Attempted to schedule coroutine but loop not running")
            return None
        try:
            return asyncio.run_coroutine_threadsafe(coro, self._loop)
        except Exception as e:
            logger.error("Failed to schedule coroutine: %s", e)
            return None

    def get_status(self) -> Dict[str, Any]:
        return {
            'thread_alive': bool(self._thread and self._thread.is_alive()),
            'loop_running': bool(self._loop and self._loop.is_running()),
            'uptime_s': round(time.time() - self._creation_ts, 1),
        }


class BluezDbusBackend(BaseBLEBackend):
    """dbus-next BlueZ backend skeleton (Milestone 2).

    Responsibilities implemented now:
      - Event loop thread lifecycle
      - Optional D-Bus bus connection
      - Status reporting
    Future milestones will add GATT service/characteristic registration and
    advertising, plus notification routing.
    """

    def __init__(self) -> None:
        self._callbacks: Dict[str, Callable] = {}
        self._loop_owner = BLEAsyncLoop()
        self._bus: Optional[MessageBus] = None
        self._app_path: str = os.environ.get('MUSHPI_DBUS_APP_PATH', '/com/mushpi/gatt')
        self._adapter_name: str = os.environ.get('MUSHPI_BLE_ADAPTER', 'hci0')
        self._gatt_minimal: bool = _get_env_bool('MUSHPI_BLE_GATT_MINIMAL_ENABLE', False)
        self._objects_exported: bool = False
        self._status_char: Optional["StatusFlagsCharacteristic"] = None
        self._initialized = False
        self._started = False
        self._bus_timeout_ms = _get_env_int('MUSHPI_DBUS_BUS_TIMEOUT_MS', 2500)
        self._shutdown_timeout_ms = _get_env_int('MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS', 1500)
        self._adv_enable = _get_env_bool('MUSHPI_BLE_ADV_ENABLE', True)

    # ---- BaseBLEBackend interface ----
    def initialize(self) -> bool:
        logger.info("BluezDbusBackend.initialize()")
        # Start loop thread first
        if not self._loop_owner.start():
            logger.error("Failed to start BLE async loop thread")
            return False

        if not _DBUS_AVAILABLE:
            logger.warning("dbus-next not available; backend will run without bus")
            self._initialized = True
            return True

        # Defer bus connection until start() to keep initialize non-blocking
        self._initialized = True
        return True

    async def _connect_bus(self) -> None:
        if not _DBUS_AVAILABLE:
            return
        try:
            # Using system bus for BlueZ
            self._bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
            logger.info("BluezDbusBackend connected to system D-Bus")
        except Exception as e:
            logger.error("Failed to connect to system D-Bus: %s", e)
            self._bus = None

    async def _register_gatt_minimal(self) -> None:
        """Register minimal GATT application exposing Status Flags characteristic.

        This uses BlueZ GattManager1.RegisterApplication and exports two objects:
          - Service object implementing org.bluez.GattService1
          - Characteristic object implementing org.bluez.GattCharacteristic1
        """
        if not _DBUS_AVAILABLE or not self._bus:
            return
        # Build objects
        service_uuid = "12345678-1234-5678-1234-56789abcdef0"  # protocol constant (public)
        service_path = f"{self._app_path}/service0"
        char_uuid = "12345678-1234-5678-1234-56789abcdef5"  # Status Flags
        char_path = f"{service_path}/char0"

        service = GattServiceInterface(service_path, uuid=service_uuid, primary=True)
        self._status_char = StatusFlagsCharacteristic(
            path=char_path,
            uuid=char_uuid,
            service_path=service_path,
            get_flags_cb=self._callbacks.get('get_status_flags'),
        )

        # Export
        self._bus.export(service_path, service)
        self._bus.export(char_path, self._status_char)

        # Register with BlueZ
        adapter_path = f"/org/bluez/{self._adapter_name}"
        introspect = await self._bus.introspect("org.bluez", adapter_path)
        obj = self._bus.get_proxy_object("org.bluez", adapter_path, introspect)
        gatt_manager = obj.get_interface("org.bluez.GattManager1")
        try:
            await gatt_manager.call_register_application(self._app_path, {})
            self._objects_exported = True
            logger.info("Registered minimal GATT application at %s", self._app_path)
        except Exception as e:
            logger.error("GattManager1.RegisterApplication failed: %s", e)
            # Unexport on failure
            try:
                self._bus.unexport(service_path, service)
            except Exception:
                pass
            try:
                self._bus.unexport(char_path, self._status_char)  # type: ignore[arg-type]
            except Exception:
                pass
            self._status_char = None
            self._objects_exported = False

    async def _unregister_gatt_minimal(self) -> None:
        if not _DBUS_AVAILABLE or not self._bus:
            return
        if not self._objects_exported:
            return
        try:
            adapter_path = f"/org/bluez/{self._adapter_name}"
            introspect = await self._bus.introspect("org.bluez", adapter_path)
            obj = self._bus.get_proxy_object("org.bluez", adapter_path, introspect)
            gatt_manager = obj.get_interface("org.bluez.GattManager1")
            await gatt_manager.call_unregister_application(self._app_path)
            logger.info("Unregistered GATT application at %s", self._app_path)
        except Exception as e:
            logger.warning("GattManager1.UnregisterApplication failed: %s", e)
        finally:
            # Best-effort unexport of objects
            service_path = f"{self._app_path}/service0"
            char_path = f"{service_path}/char0"
            try:
                self._bus.unexport(service_path, None)  # type: ignore[arg-type]
            except Exception:
                pass
            try:
                self._bus.unexport(char_path, None)  # type: ignore[arg-type]
            except Exception:
                pass
            self._objects_exported = False

    def start(self) -> bool:
        logger.info("BluezDbusBackend.start()")
        if not self._initialized:
            if not self.initialize():
                return False
        if self._started:
            logger.debug("BluezDbusBackend already started")
            return True

        # Schedule bus connection on loop
        fut = self._loop_owner.run_coro_threadsafe(self._connect_bus())
        if fut is not None:
            try:
                fut.result(timeout=self._bus_timeout_ms / 1000.0)
            except Exception as e:
                logger.error("Bus connection future failed: %s", e)
        else:
            logger.debug("Bus connection skipped (loop not running or dbus-next missing)")

        # Optionally register minimal GATT (guarded by env)
        if self._gatt_minimal and self._bus:
            fut2 = self._loop_owner.run_coro_threadsafe(self._register_gatt_minimal())
            if fut2 is not None:
                try:
                    fut2.result(timeout=self._bus_timeout_ms / 1000.0)
                except Exception as e:
                    logger.error("Minimal GATT registration failed: %s", e)

        self._started = True
        logger.info("BluezDbusBackend skeleton started (no GATT yet)")
        return True

    def stop(self) -> None:
        logger.info("BluezDbusBackend.stop()")
        # Unregister minimal GATT if active
        if self._gatt_minimal and self._bus:
            fut = self._loop_owner.run_coro_threadsafe(self._unregister_gatt_minimal())
            if fut is not None:
                try:
                    fut.result(timeout=self._bus_timeout_ms / 1000.0)
                except Exception as e:
                    logger.warning("Minimal GATT unregister error: %s", e)
        # Close bus if present
        try:
            if self._bus:
                self._bus.disconnect()
                logger.debug("D-Bus connection closed")
        except Exception as e:
            logger.warning("Error closing D-Bus connection: %s", e)
        finally:
            self._bus = None

        # Stop loop
        self._loop_owner.stop(timeout=self._shutdown_timeout_ms / 1000.0)
        self._started = False

    def set_callbacks(self, callbacks: Dict[str, Callable]) -> None:
        self._callbacks = dict(callbacks or {})
        logger.debug("BluezDbusBackend callbacks registered: %s", list(self._callbacks.keys()))

    def notify(self, characteristic_name: str, devices: Optional[Set[str]] = None) -> None:
        # Minimal: only support status_flags when minimal GATT enabled
        if characteristic_name != 'status_flags' or not self._gatt_minimal:
            logger.debug("BluezDbusBackend.notify(%s) ignored (minimal GATT off or unsupported)", characteristic_name)
            return
        if not self._status_char:
            return
        # Schedule async update that emits PropertiesChanged if notifying
        coro = self._status_char.push_update(self._callbacks.get('get_status_flags'))
        self._loop_owner.run_coro_threadsafe(coro)

    def update_advertising_name(self, name: Optional[str] = None) -> None:
        # Placeholder (advertisement arrives future milestone)
        logger.debug("BluezDbusBackend.update_advertising_name(%s) - not implemented in skeleton", name)

    def get_status(self) -> Dict[str, Any]:
        status = self._loop_owner.get_status()
        status.update({
            'backend': 'bluez-dbus',
            'initialized': self._initialized,
            'started': self._started,
            'dbus_connected': bool(self._bus),
            'adv_enable': self._adv_enable,
            'gatt_minimal': self._gatt_minimal,
            'objects_exported': self._objects_exported,
        })
        return status


__all__ = [
    'BluezDbusBackend',
]


# ------------------------ D-Bus Interfaces (Minimal) -------------------------

if _DBUS_AVAILABLE:

    class GattServiceInterface(ServiceInterface):
        """Implements org.bluez.GattService1 for a primary service."""

        def __init__(self, path: str, uuid: str, primary: bool = True, includes: Optional[List[str]] = None):
            super().__init__('org.bluez.GattService1')
            self._path = path
            self._uuid = uuid
            self._primary = primary
            self._includes = includes or []

        @dbus_property()
        def UUID(self) -> 's':  # type: ignore[override]
            return self._uuid

        @dbus_property()
        def Primary(self) -> 'b':  # type: ignore[override]
            return self._primary

        @dbus_property()
        def Includes(self) -> 'ao':  # type: ignore[override]
            return self._includes


    class StatusFlagsCharacteristic(ServiceInterface):
        """org.bluez.GattCharacteristic1 for Status Flags (read/notify)."""

        def __init__(self, path: str, uuid: str, service_path: str, get_flags_cb: Optional[Callable[[], int]] = None):
            super().__init__('org.bluez.GattCharacteristic1')
            self._path = path
            self._uuid = uuid
            self._service = service_path
            self._flags = ['read', 'notify']
            self._value: List[int] = [0x00, 0x00, 0x00, 0x00]  # 4 bytes per spec
            self._notifying = False
            self._get_flags_cb = get_flags_cb

        # Properties required by BlueZ
        @dbus_property()
        def UUID(self) -> 's':  # type: ignore[override]
            return self._uuid

        @dbus_property()
        def Service(self) -> 'o':  # type: ignore[override]
            return self._service

        @dbus_property()
        def Flags(self) -> 'as':  # type: ignore[override]
            return self._flags

        @dbus_property()
        def Value(self) -> 'ay':  # type: ignore[override]
            return self._value

        # Methods
        @dbus_method()
        def ReadValue(self, options: 'a{sv}') -> 'ay':  # type: ignore[override]
            self._value = self._compute_value_bytes()
            return self._value

        @dbus_method()
        def StartNotify(self) -> None:  # type: ignore[override]
            self._notifying = True

        @dbus_method()
        def StopNotify(self) -> None:  # type: ignore[override]
            self._notifying = False

        # Helper: compute bytes from callback (or 0)
        def _compute_value_bytes(self) -> List[int]:
            # Import serializer lazily to avoid heavy imports at module import time
            try:
                from ...ble.serialization import StatusFlagsSerializer  # type: ignore
            except Exception:
                StatusFlagsSerializer = None  # type: ignore

            flags_val: int = 0
            if callable(self._get_flags_cb):
                try:
                    flags_val = int(self._get_flags_cb())
                except Exception as e:
                    logger.warning("get_status_flags callback error: %s", e)

            if StatusFlagsSerializer is not None:
                try:
                    packed: bytes = StatusFlagsSerializer.pack(flags_val)
                    return list(packed)
                except Exception as e:
                    logger.warning("Failed to pack status flags: %s", e)
            # Fallback: 4 zero bytes
            return [0x00, 0x00, 0x00, 0x00]

        async def push_update(self, get_flags_cb: Optional[Callable[[], int]] = None) -> None:
            # Update internal callback if provided
            if get_flags_cb is not None:
                self._get_flags_cb = get_flags_cb
            if not self._notifying:
                return
            self._value = self._compute_value_bytes()
            # Emit PropertiesChanged via dbus-next by using the Properties interface
            try:
                # dbus-next emits PropertiesChanged when returning from set_property,
                # but here we simulate by emitting signal directly through service API
                # Not all bindings expose emit; fallback to no-op if unsupported.
                self.emit_properties_changed({'Value': Variant('ay', self._value)}, [])  # type: ignore[attr-defined]
            except Exception:
                # Fallback: do nothing if emit not supported by backend; BlueZ may still poll via read
                pass
