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
# MushPi Backend Plan — Completed (2025-11-10)

End-to-end plan for the Raspberry Pi backend (“mushpi”) covering sensors, control, stage logic, persistence, BLE GATT, and service lifecycle. This document aligns with the current codebase and baseline, uses environment variables for all configuration (no hard-coded values), and defines milestones, acceptance criteria, and risks.

This plan complements, not duplicates, operational steps in `mushpi/README.md` and Flutter scope in `FLUTTER_APP_PLAN.MD`.

---

## Scope and non-goals

In scope
- Pi backend: sensors, relay control, stage engine, BLE GATT, persistence, logs, service.
- BLE backend migration path to BlueZ D-Bus via `dbus-next`, behind an env flag.
- Configuration via `.env` and JSON profiles; no values in code.

Out of scope
- Flutter UI/UX specifics (see Flutter docs). 
- Cloud sync or remote services.

---

## Current state snapshot (from baseline)
- BLE service is functional with BlueZero: custom service and 5 characteristics work; notifications initialized with valid payload sizes; callbacks correctly wired; non-blocking notify worker with backpressure is in place.
- Backend interface and factory exist to switch BLE backend via env.
- `dbus-next` backend skeleton and async loop thread implemented behind env; minimal GATT (Status Flags) added under an env gate; further characteristics pending on-device validation.
- Flutter app connects, discovers services/chars, subscribes, and logs packets; database writes ok.

---

## Goals and success criteria

Goals
- Reliable sensing and control with stage-aware thresholds and safe defaults loaded from configuration.
- Non-blocking BLE notifications with bounded memory and clear observability.
- Backend swap capability: `bluezero` (default) or `bluez-dbus` via env without changing the external protocol.
- Clean startup/shutdown and resilient error handling.

Success criteria
- Service discoverable with all 5 characteristics; reads return correct byte lengths; writes update live state.
- Notification delivery without producer stalls; bounded queue with measured drops/coalescing under pressure.
- Env-driven configuration validated at boot; missing/invalid values logged with actionable messages.
- Clean shutdown within configured timeout; no hung threads.

---

## Architecture overview

Components (key directories under `mushpi/app/`)
- config/: environment and profile loading (JSON/`.env`).
- sensors/: hardware access for CO₂/Temp/RH, backup Temp/RH, and light input.
- managers/: orchestration for sensors and thresholds.
- core/: control and stage engines, BLE GATT coordination.
- ble/: GATT service, characteristics, and backend selection (BlueZero or BlueZ D-Bus).
- database/: local persistence utilities.
- service/: systemd unit and service assets.

Data flow
1) Sensors → readings → control decisions (hysteresis, schedules) → relays.
2) Stage engine provides current species/stage/mode and expected durations for thresholds.
3) BLE exposes telemetry, accepts config writes and overrides via characteristics.
4) Persistence saves readings/actions/alerts based on managers’ policies.

---

## Configuration (environment-driven)

All configuration is supplied via `.env` and/or JSON profile files. The plan only names variables; see `README.md` for creation and usage.

Core paths
- `MUSHPI_APP_DIR`, `MUSHPI_DATA_DIR`, `MUSHPI_CONFIG_DIR`

Runtime modes
- `MUSHPI_SIMULATION_MODE`, `MUSHPI_DEBUG_MODE`

Relays and GPIO (names only; map to your hardware)
- `MUSHPI_RELAY_FAN`, `MUSHPI_RELAY_MIST`, `MUSHPI_RELAY_LIGHT`, `MUSHPI_RELAY_HEATER`
- `MUSHPI_RELAYS_ACTIVE_LOW`, `MUSHPI_LIGHT_SENSOR_CHANNEL`

Sensors
- I²C enablement and addresses are handled by drivers; any tunables are read via env by sensor modules when supported.

BLE
- `MUSHPI_BLE_BACKEND` (bluezero|bluez-dbus)
- `MUSHPI_BLE_QUEUE_MAX_SIZE`, `MUSHPI_BLE_QUEUE_PUT_TIMEOUT_MS`, `MUSHPI_BLE_BACKPRESSURE_POLICY`
- `MUSHPI_BLE_LOG_SLOW_PUBLISH_MS`, `MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS`
- `MUSHPI_DBUS_BUS_TIMEOUT_MS`, `MUSHPI_BLE_ADV_ENABLE`, `MUSHPI_BLE_ADAPTER`, `MUSHPI_DBUS_APP_PATH`

Stage and thresholds
- Loaded from JSON profiles (species × stage). No numeric constants in code; values originate from config files or env.

Database
- Path is derived from `MUSHPI_DATA_DIR`; permissions managed per README guidance.

Service
- Systemd unit references environment and paths; no absolute constants required in code.

---

## Module responsibilities (contracts)

Sensors
- Inputs: hardware buses/ports and env-configured parameters.
- Outputs: normalized readings or None on invalid samples.
- Error modes: transient sensor failures, bus errors; log and degrade gracefully.

Control
- Inputs: latest readings and stage thresholds.
- Outputs: relay actuation intents, duty-cycle enforcement, condensation guard.
- Error modes: invalid readings; must fail safe (relays default to off) and log.

Stage engine
- Inputs: species, stage, mode, durations from config; elapsed time and compliance metrics.
- Outputs: current targets and optional advancement proposals.

BLE GATT
- Inputs: callbacks for read/write/notify; serialized payloads per protocol.
- Outputs: discoverable service with characteristics; notifications on updates.
- Error modes: backend failures; must not block producers; log and continue.

Database
- Inputs: readings/actions/alerts.
- Outputs: durable storage and retention per policy.

---

## Data and storage

- Readings/actions/alerts/inspections tables managed by database utilities.
- Retention is a policy configured by environment or profile (no constants in code).
- Schema evolution is additive; migrations logged in baseline.

---

## Error handling and logging

- Structured logs at consistent levels; include context (component, characteristic, queue stats).
- Defensive try/except around backend operations; producers unaffected by notify delays.
- Startup validation of required env/paths; emit clear remediation hints.

---

## Security considerations

- Bonding/pairing kept disabled; client writes accepted only for supported characteristics.
- Reject unknown writers at characteristic layer where applicable; log attempts.
- Secrets and keys are never embedded; `.env` is the only source for sensitive data if introduced later.

---

## Testing strategy

- Unit: control hysteresis, schedule math, stage readiness, serializers, queue policies.
- Integration (Pi): end-to-end BLE discovery, read lengths, write effects, notify latency under load.
- Field: multi-day run validating compliance and stability; capture logs for regression.

---

## Deployment and operations

- Follow `mushpi/README.md` for setup, virtualenv, permissions, and systemd configuration.
- Use `.env` to define all settings; keep device-specific values out of source control.
- Observe logs during startup, service publication, and under notify load; adjust env if needed.

---

## Milestones (with acceptance)

1) BLE backend interface and factory (done)
- Acceptance: env-driven selection without changing behavior; BlueZero remains default.

2) `dbus-next` skeleton + async loop thread (done)
- Acceptance: backend starts/stops cleanly; no GATT yet; status reported.

3) Minimal GATT via BlueZ D-Bus: Status Flags (in progress)
- Acceptance: custom service visible; 4-byte read returns; notify reaches client; gated by env.

4) Environmental Measurements characteristic
- Acceptance: 12-byte read+notify; notifications driven via existing queue without producer stalls.

5) Remaining write characteristics: control_targets, stage_state, override_bits
- Acceptance: writes update control/stage subsystems; reads reflect latest state.

6) Advertising (optional)
- Acceptance: advertisement toggled by env; alias fallback when disabled.

7) Hardening and observability
- Acceptance: metrics/logs for queue depth, drops/coalescing, read/notify timing; graceful shutdown with no hangs.

8) Rollout and flip default (post A/B)
- Acceptance: `bluez-dbus` proven stable on a subset; default switched via env policy.

Adjacent backlog
- Implement control target updates and manual overrides in backend callbacks end-to-end.
- Add per-characteristic coalescing keys if required by load.

---

## Risks and mitigations

- D-Bus complexity → incremental rollout behind env; start with one characteristic; verbose logs.
- BLE stack stalls → dedicated async loop and bounded queues; producers never block.
- Permissions and DB locks → follow README scripts for permissions; open DB with safe modes; log and recover.

---

## Acceptance checklist (go/no-go)

- Service discoverable; all characteristics present.
- Reads return protocol-specified lengths; writes take effect.
- Notify latency and throughput within thresholds configured by env; queue remains bounded.
- Clean start/stop; no orphaned threads; logs show healthy state transitions.

---

## References

- `BASELINE.MD` — latest progress and decisions (latest-first).
- `mushpi/README.md` — setup, environment, and service instructions.
- `flutter/mushpi_hub/FLUTTER_BASELINE.md` — app-side state and BLE protocol.
- BLE backend migration notes embedded in baseline entries from 2025-11-10.
