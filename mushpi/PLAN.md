# BLE Backend Migration Plan (dbus-next over BlueZ D-Bus)

Date: 2025-11-10
Owner: MushPi Backend
Status: Proposal ready; implementation behind env flag

## Summary
BlueZero + GLib can introduce blocking behavior at publish/notify time. We will add an alternative BLE backend that talks to BlueZ directly via D-Bus using `dbus-next` (asyncio). This removes GLib as a dependency, gives us precise timeouts and cancellation, and keeps our existing external API, UUIDs, and Flutter app unchanged. We will make the backend switchable via environment variables (no hard-coded values) and ship it alongside the current BlueZero path for safe rollout.

## Goals
- Eliminate thread blocking and hidden GLib stalls during BLE operations.
- Keep public BLE protocol (UUIDs, payload formats) and callbacks unchanged.
- Make backend selection configurable: `MUSHPI_BLE_BACKEND=bluezero|bluez-dbus`.
- Preserve current queue/backpressure model; notifications never block producers.
- Provide clear logging, metrics, and graceful shutdown.

## Non-goals
- Changing the Flutter app protocol or UI.
- Introducing pairing/bonding flows (we keep connectionless mode).
- Removing BlueZero immediately (we keep it as fallback until proven stable).

## Current issues (observed)
- `peripheral.publish()` and downstream D-Bus calls can block despite threading.
- GLib mainloop dependency makes fine-grained timeouts/cancellation difficult.
- Inline notify paths (now queued) previously stalled sensor reads.

## Proposed solution
- Implement a new backend using `dbus-next` (`asyncio`) to expose:
  - org.bluez.GattService1
  - org.bluez.GattCharacteristic1
  - org.bluez.LEAdvertisement1 (optional, controlled by env)
- Run an asyncio event loop in a dedicated thread; bridge from the sync code using thread-safe queues and `asyncio.run_coroutine_threadsafe`.
- Maintain the existing producer → bounded-queue → worker pattern; the backend only performs the non-blocking notify mechanics.
- Keep all configuration in `.env`; never hard-code values.

## Architecture
- Files (new):
  - `app/ble/backends/base.py`: Backend interface contract
  - `app/ble/backends/bluez_dbus.py`: dbus-next implementation
- Files (modified):
  - `app/ble/service.py`: Select backend per env; retain queue/worker; route notify to backend.

### Backend Interface (contract)
Inputs/Outputs:
- Inputs: callbacks (sensor, control, stage), connected device set, binary payloads.
- Outputs: registered GATT services/characteristics, notifications to connected clients.
- Error modes: D-Bus timeouts, service registration errors, notify failures.
- Success criteria: service discoverable, read returns payloads, notify delivers within configured bounds without blocking producers.

Methods:
- `initialize()` → bool: prepare bus/objects; no blocking operations.
- `start()` → bool: register with BlueZ, start advertisement (optional), ready to accept notify.
- `stop()` → None: unregister, cancel tasks, close bus.
- `set_callbacks(callbacks)` → None: same dict as today.
- `notify(characteristic_name, devices)` → None: schedule async notify task.
- `update_advertising_name()` → None: update AD data if enabled; otherwise adapter alias.
- `get_status()` → dict: current backend status for logging.

### Async loop thread pattern
- Create a backend-owned thread `BLEAsyncLoop`.
- Inside, start `asyncio` event loop; set up D-Bus objects using `dbus-next`.
- Communication from sync code:
  - Use a thread-safe queue or `run_coroutine_threadsafe` for notifications.
  - Apply per-call timeouts with `asyncio.wait_for`.
- Clean shutdown: cancel pending tasks, close bus, join thread with timeout.

### GATT objects
- Implement minimal services/characteristics we need:
  - MushPi custom service UUID.
  - Characteristics: env_measurements (read/notify), status_flags (read/notify), control_targets (read/write), stage_state (read/write), override_bits (write).
- Serialization remains in existing modules.

## Configuration (env)
- `MUSHPI_BLE_BACKEND` (bluezero|bluez-dbus, default: bluezero)
- `MUSHPI_DBUS_BUS_TIMEOUT_MS` (default: 2500)
- `MUSHPI_BLE_ADV_ENABLE` (true|false, default: true)
- `MUSHPI_BLE_ADV_TX_POWER` (string: low|med|high; default: med)
- `MUSHPI_BLE_QUEUE_MAX_SIZE` (default: 64)
- `MUSHPI_BLE_QUEUE_PUT_TIMEOUT_MS` (default: 10)
- `MUSHPI_BLE_BACKPRESSURE_POLICY` (drop_oldest|drop_newest|coalesce; default: drop_oldest)
- `MUSHPI_BLE_LOG_SLOW_PUBLISH_MS` (default: 250)
- `MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS` (default: 1500)

Note: additional retry/backoff variables can be leveraged later if we add retry logic in the backend.

## Step-by-step plan (milestones)
1) Backend interface + factory (no behavior change)
- Add `backends/base.py` and a simple factory selecting backend via env.
- Wire `service.py` to use backend but keep BlueZero as the default implementation.

2) dbus-next skeleton + loop thread
- Add `bluez_dbus.py` with loop/thread startup and clean shutdown; no GATT yet.
- Add config reads for D-Bus timeouts and advertisement enable flag.

3) Minimal GATT (StatusFlags only)
- Implement `GattService1` + `GattCharacteristic1` for Status Flags (read/notify).
- Validate discovery, read 4 bytes, and a test notify reaches a client.

4) Environmental Measurements
- Add env_measurements characteristic (12 bytes), read + notify.
- Drive notifications via the existing queue worker → backend `notify()`.

5) Remaining characteristics
- Implement control_targets (read/write), stage_state (read/write), override_bits (write).
- Ensure write callbacks update our existing control/stage systems.

6) Advertising (optional)
- Implement LE advertisement via `LEAdvertisingManager1` when `MUSHPI_BLE_ADV_ENABLE=true`.
- Otherwise, continue to set adapter alias as today.

7) Hardening & observability
- Add structured logging and metrics for read/notify latency, queue depth, drop/coalesce counters.
- Enforce timeouts using `asyncio.wait_for` and bounded cancellation.

8) Rollout
- Default remains `bluezero`. Enable new backend on selected devices with env switch.
- A/B test performance and stability, then flip default once stable.

## Testing plan
- Unit: backend state machine (initialize/start/stop), notify scheduling, timeout handling.
- Integration (on Pi):
  - Discovery of custom service and characteristics.
  - Read returns correct byte sizes.
  - Notify latency < configured threshold; no producer blocking.
  - Writes update the Python systems correctly.
- Regression: run existing queue tests (`test_ble_nonblocking.py`) to ensure producer side remains non-blocking.

## Rollback plan
- Set `MUSHPI_BLE_BACKEND=bluezero` and restart the service.
- Backend factory falls back automatically.

## Risks & mitigations
- D-Bus API complexity → Start with one characteristic, iterate; log verbosely.
- Kernel/driver hiccups → Isolation via asyncio thread; producers remain non-blocking.
- Dependency footprint → Single, minimal `dbus-next` dependency; keep BlueZero as fallback.

## Acceptance criteria
- On-device: service discoverable; all 5 characteristics available.
- Reads return correct byte lengths within 100 ms p50 / 500 ms p95 (configurable).
- Notifications delivered without producer stalls; queue metrics show zero or controlled drops.
- Clean shutdown under 2 s.

## Try it (env preview)
```
# .env
MUSHPI_BLE_BACKEND=bluez-dbus
MUSHPI_BLE_ADV_ENABLE=true
MUSHPI_DBUS_BUS_TIMEOUT_MS=2500
MUSHPI_BLE_QUEUE_MAX_SIZE=64
MUSHPI_BLE_QUEUE_PUT_TIMEOUT_MS=10
MUSHPI_BLE_BACKPRESSURE_POLICY=drop_oldest
MUSHPI_BLE_LOG_SLOW_PUBLISH_MS=250
MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS=1500
```

## Open questions
- Do we need LE advertisement on all devices or is adapter alias sufficient? (Default: alias, ad optional.)
- Coalescing policy per characteristic? (e.g., last-value-wins for env_measurements.)
- When should we flip default backend to `bluez-dbus`?
