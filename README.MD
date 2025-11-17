# MushPi — Phase 2 (Control + Telemetry)

Raspberry Pi–based mushroom chamber controller for **sensing, control, and BLE telemetry**.
Phase 2 covers on-device logic: sensors, hysteresis control, stage-aware thresholds, persistence, BLE GATT, and a systemd service.

---

## Features

### Backend (Raspberry Pi)
* Sensors: **SCD41** (CO₂, Temp, RH), **DHT22** fallback (Temp, RH), **ADS1115** + photoresistor (light level)
* Actuators: **Humidifier (MIST)**, **Fan (VENT)**, **Light**, optional **Heater**
* Control policy with hysteresis, duty-cycle caps, and condensation guard
* Stage engine: **FULL**, **SEMI**, **MANUAL** modes; species/stage/age aware thresholds
* Local persistence (SQLite) for readings, actions, alerts, inspections
* **BLE GATT** for live telemetry + config writes
* Runs as a **systemd** service; designed for Pi Zero 2 W / Pi 3+

### Mobile App (Flutter)
* **5-Tab Navigation**: Farms, Monitoring, Control, Stage, Settings
* **Real-time Monitoring**: Live environmental data with color-coded indicators
* **Comprehensive Control**: 
  - Temperature range (min/max)
  - Humidity minimum
  - CO₂ maximum
  - Light mode (OFF/ON/CYCLE) with timing
  - Manual relay overrides (Light, Fan, Mist, Heater)
  - Batch send to reduce BLE traffic
* **Stage Management**:
  - Automation mode selection (FULL/SEMI/MANUAL)
  - Species selection (Oyster/Shiitake/Lion's Mane)
  - Growth stage tracking (Incubation/Pinning/Fruiting)
  - Progress visualization with guidelines
* **Multi-Farm Support**: Manage multiple grow chambers
* **BLE Communication**: Direct device-to-device control via Bluetooth
* **Offline-First**: Local database with automatic sync

---

## Hardware

* Raspberry Pi (Zero 2 W or better) with **I²C** and **Bluetooth** enabled
* SCD41 (I²C)
* DHT22 (1-wire style)
* ADS1115 (I²C) + photoresistor divider
* 3–4 channel relay board (5 V or 3.3 V logic; confirm polarity)
* Loads: humidifier/ultrasonic mister, DC/AC fan, LED strip/panel, optional heater

> Safety: Enclose mains wiring, fuse appropriately, respect relay ratings, strain-relieve cables, add drip shields over electronics.

### Suggested GPIO (change as needed)

| Function |        Pin (BCM) | Notes                    |
| -------- | ---------------: | ------------------------ |
| Relays   |   17, 27, 22, 23 | FAN, MIST, LIGHT, HEATER |
| DHT22    |                4 | With 10 k pull-up        |
| I²C      | 2 (SDA), 3 (SCL) | SCD41 + ADS1115          |
| Photores |       ADS1115 A0 | 10 k–100 k divider       |

---

## Software Setup

```bash
# Enable I²C + Bluetooth first (raspi-config)
sudo apt update
sudo apt install -y python3 python3-venv python3-pip bluez i2c-tools sqlite3 git

sudo mkdir -p /opt/mushpi && sudo chown $USER /opt/mushpi
cd /opt/mushpi
git clone <your-repo-url> app
python3 -m venv /opt/mushpi/.venv
source /opt/mushpi/.venv/bin/activate
pip install -U pip
pip install adafruit-circuitpython-scd4x Adafruit_DHT adafruit-circuitpython-ads1x15 RPi.GPIO bluezero apscheduler
```

---

## Repository Layout

```
app/
  config/
    thresholds.json
  core/
    sensors.py
    control.py
    stage.py
    safety.py
    persistence.py
    ble_gatt.py
  main.py
  service/
    mushpi.service
```

---

## Configuration

### `config/thresholds.json`

Species × stage targets and light schedule. Example (Oyster):

```json
{
  "Oyster": {
    "Incubation": {
      "temp_min": 24.0, "temp_max": 28.0,
      "rh_min": 70.0, "co2_max": 5000,
      "light": {"mode": "off"}, "expected_days": 14
    },
    "Pinning": {
      "temp_min": 18.0, "temp_max": 22.0,
      "rh_min": 90.0, "co2_max": 1000,
      "light": {"mode": "cycle","on_min": 960,"off_min": 480},
      "expected_days": 5
    },
    "Fruiting": {
      "temp_min": 15.0, "temp_max": 20.0,
      "rh_min": 85.0, "co2_max": 800,
      "light": {"mode": "cycle","on_min": 900,"off_min": 540},
      "expected_days": 0
    }
  }
}
```

> RH uses a **minimum** with hysteresis. Optional `rh_soft_max` (e.g., 96) can enable brief drying pulses.

---

## Control Logic

* **Hysteresis** (defaults): Temp ±1.0 °C, RH +3 % (for OFF), CO₂ ±100 ppm
* **Fan** ON: `CO₂ > co2_max` **or** `Temp > temp_max`; OFF when below thresholds with hysteresis
* **Mist** ON: `RH < rh_min`; OFF when `RH > rh_min + hysteresis`
* **Light**: `off` / `on` / `cycle` via schedule; verify brightness via photoresistor
* **Heater** (optional) ON: `Temp < temp_min`; OFF when `Temp > temp_min + hysteresis`
* **Condensation guard**: if `RH > 95–98%` for > N min or `dewpoint ~ air temp`, pause mist and short fan pulse
* **Duty caps**: rolling windows to prevent over-ventilation/misting
* **Fail-safe**: relays default OFF at boot; enable only after first valid sensor set

---

## Stage & Autonomy

Modes:

* **FULL** — auto targets + auto stage advance
* **SEMI** — auto targets; propose stage change, require confirmation
* **MANUAL** — no automatic control (UI/overrides only)

State tracked: `species`, `stage`, `stage_start_ts`, `expected_days`, `mode`.
Auto-advance uses **age** + **compliance ratio** (time within band over last window).

---

## Persistence (SQLite)

Tables:

* `config(key, value)`
* `profiles(species, stage, thresholds, expected_days)`
* `readings(ts, temp_c, rh, co2_ppm, light_raw)`
* `actions(ts, actuator, state, reason)`
* `alerts(ts, code, message, severity)`
* `inspections(id, ts, stage, notes, photo_uri, score)`

Retention policy: keep \~30 days of `readings/actions`, weekly `VACUUM`.

---

## BLE GATT

Service UUID: `12345678-1234-5678-1234-56789abcdef0` (ENV-CONTROL)

Characteristics:

* `env_measurements` (notify/read)

  * CO₂ ppm (u16), Temp×10 (s16), RH×10 (u16), light\_raw (u16), uptime\_ms (u32)
* `control_targets` (read/write)

  * temp\_min×10, temp\_max×10, rh\_min×10, co2\_max, light\_mode, on\_minutes, off\_minutes
* `stage_state` (read/write)

  * mode, species\_id, stage\_id, stage\_start\_ts, expected\_days
* `override_bits` (write)

  * bit0 LIGHT, bit1 FAN, bit2 MIST, bit3 HEATER, bit7 DISABLE\_AUTOMATION
* `status_flags` (notify/read)

Optional (feature-gated):

* `actuator_status` (read/notify)
  - 2-byte bitfield of live relay states
  - Bit 0: Light ON; Bit 1: Fan ON; Bit 2: Mist ON; Bit 3: Heater ON; others reserved

Enable via `.env`:

```
MUSHPI_BLE_ACTUATOR_STATUS_ENABLE=true
```

Default is `false` to preserve backward compatibility for clients expecting only the legacy characteristic set.

Advertising name: `MushPi-<species><stage>`; pair once; reject unknown writers.

---

## Running (systemd)

```ini
# app/service/mushpi.service
[Unit]
Description=Mushroom Pi Control Service
After=network-online.target bluetooth.target
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/mushpi/app
ExecStart=/opt/mushpi/.venv/bin/python -u /opt/mushpi/app/main.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Install & start:

```bash
sudo cp app/service/mushpi.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mushpi
sudo systemctl status mushpi
journalctl -u mushpi -f
```

---

## Calibration

* **SCD41**: enable ASC if space gets fresh air; otherwise perform FRC outdoors occasionally
* **DHT22**: reject implausible jumps (>5 °C in 5 s, >10 % RH in 5 s)
* **Photoresistor**: two-point calibration (dark vs known light) into 0–1000

---

## Testing

* **Unit**: hysteresis FSMs, schedule math, stage readiness, sensor parsers
* **Integration**: simulated sensors → verify relay timing, BLE packets
* **Field**: 72-hour run; check compliance ratio, auto-advance (FULL), alert noise

---

## Troubleshooting

* Reads are `None` → check I²C addresses (`i2cdetect -y 1`), wiring, pull-ups
* Relays inverted → set `ACTIVE_LOW=True` in `control.set_relays` config
* BLE connects but writes rejected → device not bonded; clear bonds and pair again
* RH sticks near 100% → add airflow, ensure sensor isn’t in mist stream, enable condensation guard

---

## Roadmap (Phase 3 Preview)

* Mobile app: setup wizard (species, stage, start date), live charts, alerts
* OTA threshold edits and stage confirmations
* Photo/inspection workflow + quality scoring
* Cloud sync option (optional)

---

## License

MIT (proposed). See `LICENSE` (add file).

---

## Acknowledgements

Sensor and actuator vendors; open-source Python libs by Adafruit and community.
