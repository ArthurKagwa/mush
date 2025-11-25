# MushPi System Software Report

**Report Date:** January 2025  
**System Version:** Phase 2 (Control + Telemetry)  
**Status:** Production-Ready

---

## Executive Summary

MushPi is a complete mushroom cultivation automation system consisting of two integrated components:

1. **MushPi Firmware** - Raspberry Pi-based environmental controller with BLE telemetry
2. **MushPi Hub** - Flutter mobile application for remote monitoring and control

The system provides automated environmental control (temperature, humidity, CO₂, lighting) with stage-aware thresholds, real-time BLE communication, and comprehensive mobile management.

---

## Part 1: MushPi Firmware (Raspberry Pi)

### Overview
Python-based firmware running on Raspberry Pi (Zero 2 W or better) that monitors environmental conditions and controls actuators via GPIO relays. Features modular architecture, SQLite persistence, and BLE GATT service for mobile connectivity.

### Core Capabilities

#### Sensor Integration
- **SCD41** (I²C): Primary CO₂, temperature, and humidity sensor
- **DHT22** (GPIO): Backup temperature/humidity sensor
- **ADS1115 + Photoresistor** (I²C): Light level detection
- Automatic sensor validation and fallback mechanisms
- Configurable monitoring intervals (5-300 seconds)

#### Actuator Control
- **4-Channel Relay Control:**
  - Fan/Exhaust (GPIO 17)
  - Mist/Humidifier (GPIO 27)
  - Grow Light (GPIO 22)
  - Heater (GPIO 23, optional)
- **Control Features:**
  - Hysteresis-based control (prevents relay chattering)
  - Duty-cycle caps (prevents over-actuation)
  - Condensation guard (protects against excessive humidity)
  - Manual override support
  - Emergency stop capability

#### Stage Management
- **Three Automation Modes:**
  - **FULL**: Automatic stage advancement + automatic control
  - **SEMI**: Manual stage advancement + automatic control
  - **MANUAL**: Manual stage advancement + manual control only
- **Species Support:** Oyster, Shiitake, Lion's Mane
- **Growth Stages:** Incubation, Pinning, Fruiting
- **Stage-Aware Thresholds:** Each stage has species-specific environmental targets
- **Auto-Advancement:** FULL mode advances stages based on age and compliance ratio

#### Control Logic
- **Hysteresis Bands:**
  - Temperature: ±1.0°C
  - Humidity: +3% (for OFF)
  - CO₂: ±100 ppm
- **Control Rules:**
  - Fan: ON when CO₂ > max OR temp > max
  - Mist: ON when RH < min
  - Light: Configurable (OFF/ON/CYCLE with timing)
  - Heater: ON when temp < min (optional)
- **Safety Features:**
  - Fail-safe: Relays default OFF at boot
  - Condensation protection
  - Duty-cycle limits
  - Emergency stop override

#### Data Persistence
- **SQLite Database** (`mushpi.db`):
  - Sensor readings (time-series)
  - Control actions (relay state changes with reason codes)
  - Stage configurations (species, stage, thresholds)
  - Alerts and system events
- **Retention Policy:** ~30 days of readings/actions, weekly VACUUM
- **Configuration Storage:** JSON-based threshold profiles per species/stage

#### BLE GATT Service
- **Service UUID:** `12345678-1234-5678-1234-56789abcdef0`
- **Characteristics:**
  1. **Environmental Measurements** (notify/read, 12 bytes)
     - CO₂ (u16), Temperature×10 (s16), RH×10 (u16), Light (u16), Uptime (u32)
  2. **Control Targets** (read/write, 15 bytes)
     - Temperature min/max, RH min, CO₂ max, light mode/timing
  3. **Stage State** (read/write, 10 bytes)
     - Mode, species, stage, start timestamp, expected days
  4. **Override Bits** (write-only, 2 bytes)
     - Manual relay overrides, disable automation, emergency stop
  5. **Status Flags** (notify/read, 4 bytes)
     - System health indicators
  6. **Actuator Status** (notify/read, 2 bytes, optional)
     - Live relay states (bitfield)
- **Advertising:** `MushPi-<species><stage>` (e.g., "MushPi-OysterPinning")
- **Connection Management:** Bondless BLE, supports multiple concurrent connections

#### System Architecture
- **Modular Design:**
  - `app/core/`: Control, sensors, stage management
  - `app/ble/`: BLE GATT service and characteristics
  - `app/database/`: SQLite persistence
  - `app/managers/`: Sensor and threshold orchestration
  - `app/integrations/`: ThingSpeak cloud sync (optional)
- **Backend Flexibility:** Supports BlueZero (default) or BlueZ D-Bus backends
- **Configuration:** Environment-driven via `.env` (no hard-coded values)
- **Service Management:** Runs as systemd service for production deployment

#### Key Features
- ✅ Real-time sensor monitoring with configurable intervals
- ✅ Hysteresis-based control prevents relay chattering
- ✅ Stage-aware threshold management
- ✅ Automatic stage progression (FULL mode)
- ✅ Manual override support with emergency stop
- ✅ BLE telemetry for mobile app connectivity
- ✅ SQLite persistence for historical data
- ✅ ThingSpeak integration for cloud backup (optional)
- ✅ Comprehensive logging and diagnostics
- ✅ Production-ready systemd service

### Technical Stack
- **Language:** Python 3.9+
- **Key Libraries:**
  - `bluezero` / `dbus-next`: BLE GATT service
  - `adafruit-circuitpython-scd4x`: SCD41 sensor
  - `adafruit-circuitpython-dht`: DHT22 sensor
  - `adafruit-circuitpython-ads1x15`: ADS1115 ADC
  - `RPi.GPIO`: GPIO control
  - `apscheduler`: Task scheduling
- **Database:** SQLite3
- **Platform:** Raspberry Pi OS (Linux)

---

## Part 2: MushPi Hub Mobile App (Flutter)

### Overview
Cross-platform mobile application (iOS & Android) built with Flutter that connects to MushPi devices via BLE. Provides real-time monitoring, environmental control, stage management, and multi-farm support with offline-first architecture.

### Core Capabilities

#### Multi-Farm Management
- **Farm Registry:** Create and manage multiple grow chambers
- **Device Binding:** Link BLE devices to farms
- **Farm Status:** Online/offline tracking with 30-minute timeout
- **Farm Analytics:** Production metrics, compliance tracking, yield statistics
- **Local Persistence:** Drift (SQLite) database for offline-first operation

#### Real-Time Monitoring
- **Environmental Dashboard:**
  - Live temperature, humidity, CO₂, and light readings
  - Color-coded status indicators (green/orange/red)
  - Data freshness timestamps
  - Multi-farm overview with averages
- **Historical Charts:**
  - 24-hour trend visualization
  - Time-based scrollable charts with zoom/pan
  - Custom date range selection
  - Zero/negative value filtering
  - ThingSpeak backfill for remote data access
- **Auto-Refresh:** 30-second polling for live data updates

#### Environmental Control
- **Control Screen:**
  - Temperature range (min/max sliders)
  - Humidity minimum slider
  - CO₂ maximum slider
  - Light mode selector (OFF/ON/CYCLE)
  - Light timing configuration (HH:MM format)
  - Manual relay overrides (Light, Fan, Mist, Heater)
  - Disable automation master switch
  - Batch send to reduce BLE traffic
- **Current Stage Banner:** Shows which stage is being edited
- **Dual Write:** Updates both control targets and stage thresholds

#### Stage Management
- **Stage Wizard (5-Step):**
  1. Basic Information (species, date planted, current stage, automation mode)
  2. Incubation Stage Setup (thresholds, expected duration)
  3. Pinning Stage Setup (thresholds, expected duration)
  4. Fruiting Stage Setup (thresholds, expected duration)
  5. Review & Submit (atomic configuration)
- **Stage Screen:**
  - Automation mode selection (FULL/SEMI/MANUAL)
  - Species selection (Oyster/Shiitake/Lion's Mane)
  - Growth stage tracking (Incubation/Pinning/Fruiting)
  - Progress visualization with guidelines
  - Expected duration configuration
  - Stage threshold editing for any stage
- **Species-Specific Defaults:** Pre-filled optimal values per species/stage

#### BLE Communication
- **Connection Management:**
  - Device scanning with timeout
  - Secure bondless BLE connection
  - Auto-reconnect on app resume
  - Connection state tracking
- **Protocol Implementation:**
  - Full support for all 6 BLE characteristics
  - Binary serialization/deserialization (little-endian)
  - Smart write fallback (WRITE_WITH_RESPONSE / WRITE_NO_RESPONSE)
  - Read retry logic with configurable timeouts
  - Comprehensive packet logging
- **Backward Compatibility:**
  - Species ID mapping for legacy Pi deployments
  - Expected days clamping
  - Graceful degradation for missing characteristics

#### Data Management
- **Local Database (Drift):**
  - Farms table (metadata, device binding)
  - Readings table (time-series sensor data)
  - Harvests table (production records)
  - Devices table (BLE device registry)
  - Settings table (key-value configuration)
- **ThingSpeak Integration:**
  - Optional cloud data backfill
  - Fills gaps in local data when online
  - Remote data access when away from device
  - Configurable via environment variables
- **Offline-First:** All data stored locally, syncs when connected

#### User Interface
- **5-Tab Navigation:**
  1. **Farms:** Farm list, device scanning, history
  2. **Monitoring:** Real-time environmental dashboard
  3. **Control:** Environmental parameter adjustment
  4. **Stage:** Growth stage configuration wizard
  5. **Settings:** App configuration and preferences
- **Material Design 3:** Modern UI with light/dark theme support
- **Responsive Design:** Adapts to different screen sizes
- **Accessibility:** Clear visual hierarchy, color-coded status indicators

#### State Management
- **Riverpod:** Reactive state management
- **Providers:**
  - `bleConnectionManagerProvider`: BLE connection lifecycle
  - `sensorDataListenerProvider`: Automatic data saving
  - `readingsProvider`: Historical data queries
  - `farmsProvider`: Farm CRUD operations
  - `currentFarmProvider`: Selected farm tracking
- **Event-Driven:** No polling, updates on connection/state changes

#### Key Features
- ✅ Multi-farm management with device binding
- ✅ Real-time environmental monitoring with color-coded status
- ✅ Interactive historical charts with zoom/pan
- ✅ Complete environmental control (temperature, humidity, CO₂, light)
- ✅ 5-step stage configuration wizard
- ✅ Stage-aware threshold management
- ✅ Manual relay overrides with emergency stop
- ✅ BLE communication with smart fallback
- ✅ Offline-first architecture with local database
- ✅ ThingSpeak cloud integration (optional)
- ✅ Material Design 3 UI
- ✅ Comprehensive error handling and logging

### Technical Stack
- **Framework:** Flutter 3.35.7+
- **Language:** Dart 3.9.2+
- **Key Packages:**
  - `flutter_riverpod`: State management
  - `flutter_blue_plus`: BLE communication
  - `drift`: Type-safe SQL database
  - `freezed`: Immutable data classes
  - `go_router`: Declarative navigation
  - `fl_chart`: Data visualization
  - `flutter_dotenv`: Environment configuration
  - `http`: REST API calls (ThingSpeak)
- **Platforms:** iOS, Android, Linux, macOS, Windows

---

## Part 3: System Integration

### Communication Protocol
- **BLE GATT Service:** Primary communication channel
- **Service UUID:** `12345678-1234-5678-1234-56789abcdef0`
- **Data Format:** Binary little-endian for efficiency
- **Connection Type:** Bondless BLE (no pairing required)
- **Update Frequency:** Configurable (default: every monitor interval)

### Data Flow
1. **Pi → App (Telemetry):**
   - Environmental measurements (notify every monitor interval)
   - Status flags (notify on state changes)
   - Actuator status (notify on relay changes, optional)
2. **App → Pi (Control):**
   - Control targets (write on user changes)
   - Stage state (write on stage updates)
   - Override bits (write on manual overrides)
   - Stage thresholds (write on threshold updates)

### Synchronization
- **Real-Time:** BLE notifications for live data
- **Historical:** Local database queries for charts
- **Cloud Backup:** Optional ThingSpeak integration
- **Offline Support:** App works offline with cached data

### Configuration Management
- **Firmware:** Environment variables (`.env`) + JSON thresholds
- **App:** Environment variables (`.env`) + local database
- **No Hard-Coded Values:** All configuration via environment or user input
- **Backward Compatibility:** Client-side normalization for legacy Pi deployments

---

## Technical Highlights

### Firmware Strengths
- ✅ Modular architecture with clear separation of concerns
- ✅ Robust control logic with hysteresis and safety features
- ✅ Stage-aware threshold management
- ✅ Comprehensive BLE GATT implementation
- ✅ Production-ready systemd service
- ✅ Extensive logging and diagnostics
- ✅ Environment-driven configuration

### App Strengths
- ✅ Offline-first architecture
- ✅ Multi-farm support
- ✅ Real-time monitoring with historical charts
- ✅ Complete control interface
- ✅ Intuitive stage management wizard
- ✅ Smart BLE communication with fallbacks
- ✅ Material Design 3 UI
- ✅ Comprehensive error handling

### System Integration Strengths
- ✅ Efficient binary BLE protocol
- ✅ Bondless connection (no pairing)
- ✅ Real-time telemetry
- ✅ Bidirectional control
- ✅ Backward compatibility
- ✅ Optional cloud backup

---

## Deployment

### Firmware Deployment
- **Platform:** Raspberry Pi (Zero 2 W or better)
- **OS:** Raspberry Pi OS (Linux)
- **Service:** systemd service for auto-start
- **Dependencies:** Python 3.9+, virtual environment
- **Hardware:** I²C sensors, GPIO relays, BLE support

### App Deployment
- **Platforms:** iOS, Android (primary), Linux, macOS, Windows
- **Distribution:** App stores (iOS App Store, Google Play)
- **Requirements:** BLE support, Android 6.0+ / iOS 13.0+
- **Configuration:** `.env` file for environment variables

---

## Status & Roadmap

### Current Status: ✅ Production-Ready
- Core functionality complete
- BLE communication stable
- Multi-farm support operational
- Historical data visualization
- Stage management wizard
- Control interface complete

### Recent Enhancements
- ThingSpeak cloud integration
- Enhanced chart scrolling and zoom
- Stage configuration wizard
- Actuator status characteristic
- Smart BLE write fallback
- Offline cache support

### Future Enhancements (Phase 3)
- Photo/inspection workflow
- Quality scoring system
- Advanced analytics dashboard
- OTA firmware updates
- Multi-user support
- Cloud sync enhancements

---

## Conclusion

The MushPi system represents a complete, production-ready solution for automated mushroom cultivation. The firmware provides robust environmental control with stage-aware thresholds, while the mobile app offers comprehensive monitoring and control capabilities. The BLE-based communication ensures real-time updates and remote control, while the offline-first architecture ensures reliability even when connectivity is intermittent.

Both components follow best practices: modular architecture, environment-driven configuration, comprehensive error handling, and extensive logging. The system is designed for maintainability, scalability, and user-friendliness.

---

**Report Generated:** January 2025  
**System Version:** Phase 2 (Control + Telemetry)  
**Status:** ✅ Production-Ready

