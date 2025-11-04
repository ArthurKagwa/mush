# MushPi Flutter Mobile App Development Plan

## Project Overview

**Project Name:** MushPi Mobile Controller  
**Platform:** Flutter (iOS & Android)  
**Target System:** MushPi Raspberry Pi mushroom cultivation controller  
**Communication:** BLE GATT protocol  
**Version:** 1.0.0  
**Created:** October 6, 2025  
**Last Updated:** November 4, 2025

### Mission Statement
Create a beautiful, intuitive Flutter mobile application that provides seamless wireless control and monitoring of the MushPi mushroom cultivation system through BLE GATT communication.

### Implementation Status
This plan has been updated to reflect the **actual implemented MushPi BLE GATT service** including real UUIDs, data formats, and characteristic behaviors from the production codebase.

---

## Executive Summary

The MushPi Flutter app will serve as the primary user interface for monitoring and controlling the Raspberry Pi-based mushroom cultivation system. The app will connect via BLE GATT to read environmental sensors, adjust control parameters, manage growth stages, and provide real-time status updates.

### Key Features
- **Real-time Monitoring**: Live environmental data (CO₂, temperature, humidity, light)
- **Intelligent Control**: Adjust thresholds and control parameters
- **Stage Management**: Monitor and control growth stages (Incubation, Pinning, Fruiting)
- **Override Controls**: Manual relay overrides for emergency situations
- **Status Dashboard**: System health and alert monitoring
- **Beautiful UI**: Material Design 3 with dark/light theme support

---

## Technical Architecture

### Design Principles
1. **Single Source of Truth**: One centralized state manager for all app data
2. **Simple Persistence**: All data automatically persisted to local database
3. **Linear User Flow**: Clear, simple path from connection to monitoring
4. **Offline-First**: App works without constant BLE connection

### Technology Stack
- **Framework**: Flutter 3.x with Dart 3.x
- **State Management**: `Riverpod` (single source of truth, simple, testable)
- **BLE Communication**: `flutter_blue_plus` package
- **Navigation**: `go_router` for declarative routing
- **Data Persistence**: `sqflite` + `drift` for type-safe local storage
- **Charts/Graphs**: `fl_chart` for data visualization
- **Theme/UI**: Material Design 3 with custom theming
- **Code Generation**: `freezed` for immutable data models

### Simplified Project Structure
```
lib/
├── main.dart                        # App entry + Riverpod setup
├── app.dart                         # MaterialApp + router config
│
├── core/
│   ├── constants/
│   │   ├── ble_constants.dart       # UUIDs, service IDs
│   │   └── app_constants.dart       # App-wide constants
│   ├── theme/
│   │   ├── app_theme.dart           # Material 3 theme
│   │   └── color_schemes.dart       # Light/dark colors
│   └── utils/
│       ├── ble_serializer.dart      # Binary data serialization
│       └── validators.dart          # Input validation
│
├── data/
│   ├── models/                      # Freezed data models
│   │   ├── environmental_data.dart
│   │   ├── control_targets.dart
│   │   ├── stage_state.dart
│   │   └── device_info.dart
│   ├── database/
│   │   ├── app_database.dart        # Drift database definition
│   │   ├── daos/                    # Data access objects
│   │   │   ├── readings_dao.dart    # Environmental readings
│   │   │   ├── settings_dao.dart    # App settings
│   │   │   └── devices_dao.dart     # Saved devices
│   │   └── tables/
│   │       ├── readings_table.dart
│   │       ├── settings_table.dart
│   │       └── devices_table.dart
│   └── repositories/
│       ├── ble_repository.dart      # BLE communication only
│       └── database_repository.dart # Database operations only
│
├── providers/                       # SINGLE SOURCE OF TRUTH
│   ├── app_state_provider.dart      # Main app state
│   ├── ble_provider.dart            # BLE connection state
│   ├── device_provider.dart         # Current device data
│   └── settings_provider.dart       # User preferences
│
├── screens/                         # Simple, linear flow
│   ├── splash_screen.dart           # 1. App launch
│   ├── home_screen.dart             # 2. Main screen (connect or dashboard)
│   ├── device_scan_screen.dart      # 3. Find devices
│   ├── dashboard_screen.dart        # 4. Main monitoring view
│   ├── settings_screen.dart         # 5. App settings
│   └── history_screen.dart          # 6. Historical data
│
└── widgets/                         # Reusable UI components
    ├── connection_card.dart
    ├── environmental_card.dart
    ├── control_slider.dart
    ├── stage_selector.dart
    ├── chart_widget.dart
    └── status_indicator.dart
```

### Key Architecture Changes
1. **Removed complex domain/use_case layers** - Too complex for this app
2. **Single state provider** - One source of truth for all app state
3. **Combined screens** - Fewer screens, simpler navigation
4. **Automatic persistence** - All state changes auto-saved to DB
5. **Provider-based** - Riverpod providers replace ViewModels

---

## Detailed Feature Specifications

### 1. Device Discovery & Connection
**Priority**: Critical  
**Complexity**: Medium  

#### Features:
- Automatic BLE device scanning for MushPi devices
- Device list with signal strength indicators
- One-tap connection with automatic pairing
- Connection status monitoring with auto-reconnect
- Device information display (name, address, services)

#### Technical Details:
- Use `flutter_blue_plus` for BLE operations
- **Scan for devices advertising MushPi service UUID:** `12345678-1234-5678-1234-56789abcdef0`
- **Parse advertising name format:** `MushPi-<species><stage>`
  - Examples: `MushPi-OysterPinning`, `MushPi-ShiitakeFruiting`, `MushPi-Init`
  - Format changes automatically when device stage transitions
- **Required BLE Permissions:**
  - Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`
  - iOS: `NSBluetoothAlwaysUsageDescription`
- Implement connection state management with proper error handling
- Store last connected device for automatic reconnection
- **Service Discovery:** After connection, verify service UUID `12345678-1234-5678-1234-56789abcdef0`
- **Characteristic Discovery:** Locate all 5 characteristics (env, control, stage, override, status)

### 2. Environmental Monitoring Dashboard
**Priority**: Critical  
**Complexity**: High  

#### Features:
- Real-time sensor data display with live updates
- Historical data charts (last 24h, 7 days, 30 days)
- Environmental condition indicators (Good/Warning/Critical)
- Customizable dashboard layout
- Data export functionality

#### BLE Integration:
- **Subscribe to** `env_measurements` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef1`
  - **Properties:** Read + Notify
  - **Data Size:** 12 bytes
  - **Binary Format (little-endian):**
    - Bytes 0-1: CO₂ ppm (unsigned 16-bit)
    - Bytes 2-3: Temperature × 10 (signed 16-bit, divide by 10 for °C)
    - Bytes 4-5: Humidity × 10 (unsigned 16-bit, divide by 10 for %)
    - Bytes 6-7: Light raw value (unsigned 16-bit)
    - Bytes 8-11: Uptime milliseconds (unsigned 32-bit)
- Update UI when notifications received (automatic from device)
- Request read on-demand for latest values

#### UI Components:
```dart
// Environmental data card widget
class EnvironmentalDataCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color statusColor;
  final IconData icon;
  
  // Implementation with Material Design 3 styling
}

// Real-time chart widget
class EnvironmentalChart extends StatefulWidget {
  final List<SensorReading> data;
  final SensorType sensorType;
  
  // fl_chart implementation with responsive design
}
```

### 3. Control System Management
**Priority**: Critical  
**Complexity**: Medium  

#### Features:
- Threshold adjustment sliders/inputs
- Target range visualization
- Control mode selection (AUTO/MANUAL)
- Relay status indicators
- Emergency stop functionality

#### BLE Integration:
- **Read/Write** `control_targets` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef2`
  - **Properties:** Read + Write
  - **Data Size:** 15 bytes
  - **Binary Format (little-endian):**
    - Bytes 0-1: Temperature min × 10 (signed 16-bit)
    - Bytes 2-3: Temperature max × 10 (signed 16-bit)
    - Bytes 4-5: Humidity min × 10 (unsigned 16-bit)
    - Bytes 6-7: CO₂ max ppm (unsigned 16-bit)
    - Byte 8: Light mode (unsigned 8-bit): 0=OFF, 1=ON, 2=CYCLE
    - Bytes 9-10: On minutes (unsigned 16-bit)
    - Bytes 11-12: Off minutes (unsigned 16-bit)
    - Bytes 13-14: Reserved (unsigned 16-bit, always 0)
- **Validation Ranges:**
  - Temperature: -20°C to 60°C
  - Humidity: 0% to 100%
  - CO₂: 0 to 10,000 ppm
  - Light mode: 0-2 only
  - Minutes: 0 to 1440 (24 hours)
- Provide user feedback on successful updates

#### UI Design:
- Clean sliders with value indicators
- Visual range selectors for min/max values
- Color-coded status indicators (green=good, yellow=warning, red=critical)
- Confirmation dialogs for critical changes

### 4. Growth Stage Management
**Priority**: High  
**Complexity**: Medium  

#### Features:
- Current stage display with progress indicators
- Stage transition controls (manual/auto)
- Species and stage selection
- Timeline view of stage progression
- Stage-specific threshold recommendations

#### BLE Integration:
- **Read/Write** `stage_state` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef3`
  - **Properties:** Read + Write
  - **Data Size:** 10 bytes
  - **Binary Format (little-endian):**
    - Byte 0: Mode (unsigned 8-bit): 0=FULL, 1=SEMI, 2=MANUAL
    - Byte 1: Species ID (unsigned 8-bit): 1=Oyster, 2=Shiitake, 3=Lion's Mane
    - Byte 2: Stage ID (unsigned 8-bit): 1=Incubation, 2=Pinning, 3=Fruiting
    - Bytes 3-6: Stage start timestamp (unsigned 32-bit, Unix epoch seconds)
    - Bytes 7-8: Expected days (unsigned 16-bit)
    - Byte 9: Reserved (unsigned 8-bit, always 0)
- Handle stage transitions with user confirmation
- Update advertising name when stage changes (device-side automatic)

#### Species & Stages (Updated with Actual IDs):
```dart
enum Species {
  oyster(1, 'Oyster'),          // ID 1 (not 0!)
  shiitake(2, 'Shiitake'),      // ID 2
  lionsMane(3, "Lion's Mane");  // ID 3
  
  const Species(this.id, this.displayName);
  final int id;
  final String displayName;
}

enum GrowthStage {
  incubation(1, 'Incubation'),  // ID 1 (not 0!)
  pinning(2, 'Pinning'),        // ID 2
  fruiting(3, 'Fruiting');      // ID 3
  
  const GrowthStage(this.id, this.displayName);
  final int id;
  final String displayName;
}

enum ControlMode {
  full(0, 'Full Auto', 'Automatic targets + automatic stage progression'),
  semi(1, 'Semi-Auto', 'Automatic targets, manual stage confirmation'),
  manual(2, 'Manual', 'Manual control only, no automation');
  
  const ControlMode(this.id, this.displayName, this.description);
  final int id;
  final String displayName;
  final String description;
}
```

### 5. Manual Override Controls
**Priority**: High  
**Complexity**: Low  

#### Features:
- Individual relay control switches
- Automation disable toggle
- Timer-based overrides
- Safety confirmations for critical actions
- Override history log

#### BLE Integration:
- **Write-Only** `override_bits` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef4`
  - **Properties:** Write only (no read support)
  - **Data Size:** 2 bytes
  - **Binary Format (little-endian):**
    - Bytes 0-1: Override bits (unsigned 16-bit bit field)
  - **Bit Flags:**
    - Bit 0: LIGHT override
    - Bit 1: FAN override
    - Bit 2: MIST override
    - Bit 3: HEATER override
    - Bit 7: DISABLE_AUTO (disable all automation)
    - Other bits: Reserved (set to 0)
- **Usage:** Set bit to 1 to activate override, 0 to deactivate
- Implement safety confirmations and timeouts
- No read capability - device does not report current override state via this characteristic

### 6. System Status & Alerts
**Priority**: High  
**Complexity**: Medium  

#### Features:
- System health indicators
- Alert notifications
- Error log display
- Connection status monitoring
- Device information panel

#### BLE Integration:
- **Subscribe to** `status_flags` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef5`
  - **Properties:** Read + Notify
  - **Data Size:** 4 bytes
  - **Binary Format (little-endian):**
    - Bytes 0-3: Status flags (unsigned 32-bit bit field)
  - **Bit Flags:**
    - Bit 0: SENSOR_ERROR - Sensor read failure
    - Bit 1: CONTROL_ERROR - Control system error
    - Bit 2: STAGE_READY - Ready for stage advancement
    - Bit 3: THRESHOLD_ALARM - Environmental threshold violation
    - Bit 4: CONNECTIVITY - BLE connected status
    - Bit 7: SIMULATION - Device in simulation mode
    - Other bits: Reserved for future use
- Display appropriate alerts and recommendations
- Implement notification system for critical alerts (bits 0, 1, 3)
- Update connection status indicator (bit 4)

---

## BLE Data Models

### Core Data Classes
```dart
### BLE Data Models

### Service UUID
```dart
// Main BLE GATT Service
const String mushPiServiceUUID = "12345678-1234-5678-1234-56789abcdef0";

// Characteristic UUIDs
const String envMeasurementsUUID = "12345678-1234-5678-1234-56789abcdef1";
const String controlTargetsUUID = "12345678-1234-5678-1234-56789abcdef2";
const String stageStateUUID = "12345678-1234-5678-1234-56789abcdef3";
const String overrideBitsUUID = "12345678-1234-5678-1234-56789abcdef4";
const String statusFlagsUUID = "12345678-1234-5678-1234-56789abcdef5";
```

### Core Data Classes
```dart
@freezed
class EnvironmentalData with _$EnvironmentalData {
  const factory EnvironmentalData({
    required int co2Ppm,              // Direct from u16
    required double temperatureC,     // s16 / 10.0
    required double relativeHumidity, // u16 / 10.0
    required int lightRaw,            // Direct from u16
    required int uptimeMs,            // Direct from u32
    required DateTime timestamp,      // Local timestamp when received
  }) = _EnvironmentalData;
  
  factory EnvironmentalData.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalDataFromJson(json);
}

@freezed
class ControlTargets with _$ControlTargets {
  const factory ControlTargets({
    required double tempMin,      // s16 / 10.0
    required double tempMax,      // s16 / 10.0
    required double rhMin,        // u16 / 10.0
    required int co2Max,          // Direct from u16
    required LightMode lightMode, // u8: 0=OFF, 1=ON, 2=CYCLE
    required int onMinutes,       // Direct from u16
    required int offMinutes,      // Direct from u16
  }) = _ControlTargets;
  
  factory ControlTargets.fromJson(Map<String, dynamic> json) =>
      _$ControlTargetsFromJson(json);
}

enum LightMode {
  off(0, 'Off'),
  on(1, 'On'),
  cycle(2, 'Cycle');
  
  const LightMode(this.value, this.displayName);
  final int value;
  final String displayName;
}

@freezed
class StageState with _$StageState {
  const factory StageState({
    required ControlMode mode,       // u8: 0=FULL, 1=SEMI, 2=MANUAL
    required Species species,        // u8: 1=Oyster, 2=Shiitake, 3=Lion's Mane
    required GrowthStage stage,      // u8: 1=Incubation, 2=Pinning, 3=Fruiting
    required DateTime stageStartTime, // u32: Unix epoch seconds
    required int expectedDays,       // Direct from u16
  }) = _StageState;
  
  factory StageState.fromJson(Map<String, dynamic> json) =>
      _$StageStateFromJson(json);
}

class OverrideBits {
  static const int light = 1 << 0;      // Bit 0
  static const int fan = 1 << 1;        // Bit 1
  static const int mist = 1 << 2;       // Bit 2
  static const int heater = 1 << 3;     // Bit 3
  static const int disableAuto = 1 << 7; // Bit 7
}

class StatusFlags {
  static const int sensorError = 1 << 0;     // Bit 0
  static const int controlError = 1 << 1;    // Bit 1
  static const int stageReady = 1 << 2;      // Bit 2
  static const int thresholdAlarm = 1 << 3;  // Bit 3
  static const int connectivity = 1 << 4;    // Bit 4
  static const int simulation = 1 << 7;      // Bit 7
}
```

### BLE Binary Serialization
```dart
class BLEDataSerializer {
  /// Parse environmental measurements (12 bytes)
  static EnvironmentalData parseEnvironmentalData(List<int> data) {
    if (data.length != 12) {
      throw ArgumentError('Environmental data must be exactly 12 bytes');
    }
    
    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    
    return EnvironmentalData(
      co2Ppm: buffer.getUint16(0, Endian.little),
      temperatureC: buffer.getInt16(2, Endian.little) / 10.0,
      relativeHumidity: buffer.getUint16(4, Endian.little) / 10.0,
      lightRaw: buffer.getUint16(6, Endian.little),
      uptimeMs: buffer.getUint32(8, Endian.little),
      timestamp: DateTime.now(),
    );
  }
  
  /// Serialize control targets (15 bytes)
  static List<int> serializeControlTargets(ControlTargets targets) {
    final buffer = ByteData(15);
    
    buffer.setInt16(0, (targets.tempMin * 10).round(), Endian.little);
    buffer.setInt16(2, (targets.tempMax * 10).round(), Endian.little);
    buffer.setUint16(4, (targets.rhMin * 10).round(), Endian.little);
    buffer.setUint16(6, targets.co2Max, Endian.little);
    buffer.setUint8(8, targets.lightMode.value);
    buffer.setUint16(9, targets.onMinutes, Endian.little);
    buffer.setUint16(11, targets.offMinutes, Endian.little);
    buffer.setUint16(13, 0); // Reserved
    
    return buffer.buffer.asUint8List();
  }
  
  /// Parse control targets (15 bytes)
  static ControlTargets parseControlTargets(List<int> data) {
    if (data.length != 15) {
      throw ArgumentError('Control targets data must be exactly 15 bytes');
    }
    
    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    
    return ControlTargets(
      tempMin: buffer.getInt16(0, Endian.little) / 10.0,
      tempMax: buffer.getInt16(2, Endian.little) / 10.0,
      rhMin: buffer.getUint16(4, Endian.little) / 10.0,
      co2Max: buffer.getUint16(6, Endian.little),
      lightMode: LightMode.values[buffer.getUint8(8)],
      onMinutes: buffer.getUint16(9, Endian.little),
      offMinutes: buffer.getUint16(11, Endian.little),
    );
  }
  
  /// Serialize stage state (10 bytes)
  static List<int> serializeStageState(StageState state) {
    final buffer = ByteData(10);
    
    buffer.setUint8(0, state.mode.id);
    buffer.setUint8(1, state.species.id);
    buffer.setUint8(2, state.stage.id);
    buffer.setUint32(3, state.stageStartTime.millisecondsSinceEpoch ~/ 1000, Endian.little);
    buffer.setUint16(7, state.expectedDays, Endian.little);
    buffer.setUint8(9, 0); // Reserved
    
    return buffer.buffer.asUint8List();
  }
  
  /// Parse stage state (10 bytes)
  static StageState parseStageState(List<int> data) {
    if (data.length != 10) {
      throw ArgumentError('Stage state data must be exactly 10 bytes');
    }
    
    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    
    return StageState(
      mode: ControlMode.values[buffer.getUint8(0)],
      species: Species.values.firstWhere((s) => s.id == buffer.getUint8(1)),
      stage: GrowthStage.values.firstWhere((s) => s.id == buffer.getUint8(2)),
      stageStartTime: DateTime.fromMillisecondsSinceEpoch(
        buffer.getUint32(3, Endian.little) * 1000
      ),
      expectedDays: buffer.getUint16(7, Endian.little),
    );
  }
  
  /// Serialize override bits (2 bytes)
  static List<int> serializeOverrideBits(int bits) {
    final buffer = ByteData(2);
    buffer.setUint16(0, bits, Endian.little);
    return buffer.buffer.asUint8List();
  }
  
  /// Parse status flags (4 bytes)
  static int parseStatusFlags(List<int> data) {
    if (data.length != 4) {
      throw ArgumentError('Status flags data must be exactly 4 bytes');
    }
    
    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    return buffer.getUint32(0, Endian.little);
  }
}
```

---

## User Interface Design

### Design System
- **Primary Color**: Deep Purple (#6750A4) - professional, technical feeling
- **Secondary Color**: Teal (#006A6B) - natural, growth-oriented
- **Accent Color**: Amber (#FFB300) - attention, warnings
- **Surface Colors**: Material Design 3 surface tones
- **Typography**: Roboto with custom hierarchy for technical data

### Screen Layouts

#### 1. Dashboard Screen
```
┌─────────────────────────────────────┐
│ ≡  MushPi Dashboard        🔵 [?]   │
├─────────────────────────────────────┤
│ 🍄 Oyster - Pinning (Day 3/5)      │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │   🌡️    │ │   💧    │ │   💨    │ │
│ │  22.5°C │ │  92.1%  │ │ 1200ppm │ │
│ │ ━━━━━┅━ │ │ ━━━━━━━ │ │ ━━━━┅━━ │ │
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│ 📊 Environmental Trends             │
│ [Chart showing last 24h data]      │
├─────────────────────────────────────┤
│ ⚙️  Controls    📋 Stages    🔧 Manual │
└─────────────────────────────────────┘
```

#### 2. Environmental Details Screen
```
┌─────────────────────────────────────┐
│ ←  Environmental Data      [⚙️] [📊] │
├─────────────────────────────────────┤
│ Temperature                         │
│ 22.5°C  ━━━━━┅━━━━  Target: 20-24°C │
│                                     │
│ Humidity                            │
│ 92.1%   ━━━━━━━━━┅  Target: >90%    │
│                                     │
│ CO₂ Level                           │
│ 1200ppm ━━━━┅━━━━━  Target: <1000   │
│                                     │
│ Light Level                         │
│ 450 lux [●●●●●○○○○○] Cycle: ON     │
├─────────────────────────────────────┤
│ 📈 Historical Charts                │
│ [Detailed charts with time ranges] │
└─────────────────────────────────────┘
```

#### 3. Control Settings Screen
```
┌─────────────────────────────────────┐
│ ←  Control Settings        [Save]   │
├─────────────────────────────────────┤
│ 🌡️ Temperature Targets              │
│ Min: [18°C     ●━━━━━━━━━━] 30°C     │
│ Max: [18°C ━━━━●━━━━━━━━━] 30°C     │
│                                     │
│ 💧 Humidity Target                  │
│ Min: [70%  ━━━━━━━━●━━━━] 100%      │
│                                     │
│ 💨 CO₂ Maximum                      │
│ Max: [500   ━━━●━━━━━━━━] 5000ppm   │
│                                     │
│ 💡 Light Schedule                   │
│ Mode: [Cycle ▼]                     │
│ On:   [16 hours ●━━━━━━━] 24h       │
│ Off:  [8 hours  ━━●━━━━━] 24h       │
└─────────────────────────────────────┘
```

### Theme Configuration
```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.robotoTextTheme(
      ThemeData.dark().textTheme,
    ),
    // ... similar configuration for dark theme
  );
}
```

---

## Simple User Flow

### Linear Navigation Path
```
1. Splash Screen
   ↓
2. Home Screen
   ├─→ No device connected? → Device Scan Screen
   └─→ Device connected? → Dashboard Screen
   
3. Dashboard Screen (Main Hub)
   ├─→ Environmental monitoring (default view)
   ├─→ Control adjustments (slide-up panel)
   ├─→ Stage management (tap stage card)
   ├─→ Manual overrides (emergency FAB)
   ├─→ Settings (top-right icon)
   └─→ History (bottom nav)
```

### User Journey
```
First Time User:
Splash → Home → Scan → Select Device → Dashboard → Done!

Returning User:
Splash → Home → Auto-connect → Dashboard → Done!

Control Adjustment:
Dashboard → Swipe up panel → Adjust sliders → Save → Done!

Stage Change:
Dashboard → Tap stage card → Select new stage → Confirm → Done!
```

---

## Single Source of Truth - State Management

### App State Provider (Main Controller)
```dart
@riverpod
class AppState extends _$AppState {
  @override
  AppStateData build() {
    // Load from database on startup
    _loadFromDatabase();
    
    return AppStateData.initial();
  }
  
  // Single source for all app data
  Future<void> updateEnvironmentalData(EnvironmentalData data) async {
    state = state.copyWith(
      environmentalData: data,
      lastUpdate: DateTime.now(),
    );
    
    // Automatically persist to database
    await _saveToDatabase();
  }
  
  Future<void> updateControlTargets(ControlTargets targets) async {
    state = state.copyWith(controlTargets: targets);
    await _saveToDatabase();
    
    // Send to device via BLE
    await ref.read(bleRepositoryProvider).writeControlTargets(targets);
  }
  
  // All state changes go through this provider
  // Database persistence is automatic
}

@freezed
class AppStateData with _$AppStateData {
  const factory AppStateData({
    required ConnectionStatus connectionStatus,
    DeviceInfo? connectedDevice,
    EnvironmentalData? environmentalData,
    ControlTargets? controlTargets,
    StageState? stageState,
    List<EnvironmentalData> historicalData,
    int? statusFlags,
    DateTime? lastUpdate,
  }) = _AppStateData;
  
  factory AppStateData.initial() => const AppStateData(
    connectionStatus: ConnectionStatus.disconnected,
    historicalData: [],
  );
}
```

### Persistence Strategy
```dart
// Automatic persistence on every state change
class DatabaseRepository {
  final AppDatabase _db;
  
  // Auto-save environmental data
  Future<void> saveEnvironmentalData(EnvironmentalData data) async {
    await _db.readingsDao.insertReading(data);
    
    // Keep only last 30 days
    await _db.readingsDao.deleteOlderThan(
      DateTime.now().subtract(Duration(days: 30))
    );
  }
  
  // Auto-save control targets
  Future<void> saveControlTargets(ControlTargets targets) async {
    await _db.settingsDao.upsertControlTargets(targets);
  }
  
  // Auto-save connected device for reconnection
  Future<void> saveConnectedDevice(DeviceInfo device) async {
    await _db.devicesDao.upsertDevice(device);
  }
  
  // Load complete app state from database
  Future<AppStateData> loadAppState() async {
    final device = await _db.devicesDao.getLastConnectedDevice();
    final targets = await _db.settingsDao.getControlTargets();
    final stage = await _db.settingsDao.getStageState();
    final history = await _db.readingsDao.getRecentReadings(limit: 1000);
    
    return AppStateData(
      connectionStatus: ConnectionStatus.disconnected,
      connectedDevice: device,
      controlTargets: targets,
      stageState: stage,
      historicalData: history,
    );
  }
}
```

### BLE Integration with State
```dart
@riverpod
class BleConnection extends _$BleConnection {
  StreamSubscription? _envSubscription;
  StreamSubscription? _statusSubscription;
  
  @override
  ConnectionStatus build() {
    // Listen to connection state
    return ConnectionStatus.disconnected;
  }
  
  Future<void> connectToDevice(String deviceId) async {
    state = ConnectionStatus.connecting;
    
    try {
      final device = await ref.read(bleRepositoryProvider)
        .connect(deviceId);
      
      state = ConnectionStatus.connected;
      
      // Update main app state
      ref.read(appStateProvider.notifier)
        .setConnectedDevice(device);
      
      // Subscribe to notifications
      _subscribeToNotifications();
      
    } catch (e) {
      state = ConnectionStatus.error;
    }
  }
  
  void _subscribeToNotifications() {
    // Environmental data notifications → update app state
    _envSubscription = ref.read(bleRepositoryProvider)
      .environmentalStream
      .listen((data) {
        ref.read(appStateProvider.notifier)
          .updateEnvironmentalData(data);
      });
    
    // Status flags notifications → update app state
    _statusSubscription = ref.read(bleRepositoryProvider)
      .statusFlagsStream
      .listen((flags) {
        ref.read(appStateProvider.notifier)
          .updateStatusFlags(flags);
      });
  }
}

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}
```

---

## Simplified State Management (Old MVVM Removed)
### Screen Implementation Example
```dart
// Dashboard screen - simple, uses providers directly
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch app state (single source of truth)
    final appState = ref.watch(appStateProvider);
    final connectionStatus = ref.watch(bleConnectionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appState.connectedDevice?.name ?? 'MushPi'),
        actions: [
          // Connection indicator
          ConnectionStatusIcon(status: connectionStatus),
          
          // Settings
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      
      body: appState.environmentalData == null
          ? Center(child: Text('Waiting for data...'))
          : Column(
              children: [
                // Environmental cards (always visible)
                EnvironmentalCardsRow(data: appState.environmentalData!),
                
                // Stage info card
                StageInfoCard(
                  stage: appState.stageState,
                  onTap: () => _showStageSelector(context, ref),
                ),
                
                // Chart section
                Expanded(
                  child: EnvironmentalChart(
                    data: appState.historicalData,
                  ),
                ),
              ],
            ),
      
      // Control panel (swipe up from bottom)
      bottomSheet: DraggableScrollableSheet(
        initialChildSize: 0.1,
        minChildSize: 0.1,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return ControlPanel(
            targets: appState.controlTargets,
            onUpdate: (targets) {
              // Update through provider (auto-persists + sends to device)
              ref.read(appStateProvider.notifier)
                .updateControlTargets(targets);
            },
            scrollController: scrollController,
          );
        },
      ),
      
      // Emergency override FAB
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.emergency),
        onPressed: () => _showOverrideDialog(context, ref),
      ),
    );
  }
}
```

### Persistence Implementation (Drift Database)
```dart
// Define database with Drift
@DriftDatabase(tables: [Readings, Settings, Devices])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File('${dbFolder.path}/mushpi.db');
      return NativeDatabase(file);
    });
  }
}

// Readings table (environmental data)
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get co2Ppm => integer()();
  RealColumn get temperatureC => real()();
  RealColumn get relativeHumidity => real()();
  IntColumn get lightRaw => integer()();
}

// Settings table (control targets, stage state)
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();  // JSON serialized
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {key};
}

// Devices table (remembered devices)
class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  DateTimeColumn get lastConnected => dateTime()();
  
  @override
  Set<Column> get primaryKey => {deviceId};
}

// DAO for readings
@DriftAccessor(tables: [Readings])
class ReadingsDao extends DatabaseAccessor<AppDatabase> with _$ReadingsDaoMixin {
  ReadingsDao(AppDatabase db) : super(db);
  
  // Insert new reading (auto-called on every BLE notification)
  Future<int> insertReading(EnvironmentalData data) {
    return into(readings).insert(
      ReadingsCompanion.insert(
        timestamp: data.timestamp,
        co2Ppm: data.co2Ppm,
        temperatureC: data.temperatureC,
        relativeHumidity: data.relativeHumidity,
        lightRaw: data.lightRaw,
      ),
    );
  }
  
  // Get recent readings for charts
  Future<List<Reading>> getRecentReadings({
    int limit = 1000,
    Duration? period,
  }) {
    final query = select(readings)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit);
    
    if (period != null) {
      final since = DateTime.now().subtract(period);
      query.where((t) => t.timestamp.isBiggerOrEqualValue(since));
    }
    
    return query.get();
  }
  
  // Cleanup old data (run daily)
  Future<int> deleteOlderThan(DateTime date) {
    return (delete(readings)
      ..where((t) => t.timestamp.isSmallerThanValue(date)))
      .go();
  }
}
```

---

## Simplified Navigation

### Simple Route Configuration
```dart
// Only 6 screens total (was 9+)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Splash (loads state from DB)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // 2. Home (auto-connects or shows scan button)
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // 3. Device scan (only when needed)
    GoRoute(
      path: '/scan',
      builder: (context, state) => const DeviceScanScreen(),
    ),
    
    // 4. Dashboard (main screen - all monitoring here)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    
    // 5. History (historical data view)
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    
    // 6. Settings (app preferences)
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  
  // Smart redirect logic
  redirect: (context, state) {
    final appState = ProviderScope.containerOf(context)
      .read(appStateProvider);
    
    // If on splash, check connection and redirect
    if (state.location == '/') {
      return '/home';
    }
    
    // If trying to access dashboard without connection, redirect to home
    if (state.location == '/dashboard' && 
        appState.connectionStatus == ConnectionStatus.disconnected) {
      return '/home';
    }
    
    return null; // No redirect needed
  },
);
```

### Navigation Flow Logic
```dart
// HomeScreen auto-routing logic
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    // Auto-connect if we have a last device
    useEffect(() {
      if (appState.connectedDevice != null) {
        ref.read(bleConnectionProvider.notifier)
          .connectToDevice(appState.connectedDevice!.deviceId)
          .then((_) {
            // Auto-navigate to dashboard on success
            context.go('/dashboard');
          });
      }
      return null;
    }, []);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(Icons.spa, size: 100),
            SizedBox(height: 32),
            
            // Status or action
            if (appState.connectedDevice == null)
              ElevatedButton(
                onPressed: () => context.go('/scan'),
                child: Text('Find MushPi Device'),
              )
            else
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to ${appState.connectedDevice!.name}...'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Development Timeline (Updated for Simplified Architecture)

### Phase 1: Foundation (Week 1)
**Deliverables:**
- [x] Project setup with Riverpod + Drift
- [x] Database schema and DAOs
- [x] Core data models (Freezed)
- [x] BLE serialization utilities
- [x] Basic theme configuration

**Tasks:**
1. Create Flutter project with proper structure (simplified)
2. Add essential dependencies (Riverpod, Drift, flutter_blue_plus, go_router)
3. Define database schema with Drift (3 tables)
4. Create Freezed data models (4 models)
5. Implement BLE serialization utilities
6. Set up Material Design 3 theming
7. Configure code generation (build_runner)

### Phase 2: Core Features (Week 2)
**Deliverables:**
- [x] Device scanning and connection
- [x] Main app state provider
- [x] Environmental data monitoring
- [x] Automatic persistence
- [x] Basic dashboard

**Tasks:**
1. Implement BLE repository (scan, connect, read/write)
2. Create app state provider (single source of truth)
3. Build device scan screen
4. Build home screen with auto-connect
5. Build dashboard screen (environmental + charts)
6. Implement automatic database persistence
7. Add connection state management

### Phase 3: Control & Management (Week 3)
**Deliverables:**
- [x] Control panel (slide-up)
- [x] Stage management
- [x] Manual overrides
- [x] Settings screen
- [x] Historical data view

**Tasks:**
1. Create draggable control panel
2. Implement control targets adjustment
3. Add stage selector and management
4. Create manual override dialog
5. Build settings screen
6. Build history screen with charts
7. Add data export functionality

### Phase 4: Polish & Testing (Week 4)
**Deliverables:**
- [x] UI/UX refinements
- [x] Comprehensive testing
- [x] Error handling
- [x] Documentation
- [x] Release preparation

**Tasks:**
1. UI/UX improvements and animations
2. Comprehensive unit tests (providers, serialization)
3. Widget tests (screens, components)
4. Integration tests with mock BLE
5. Error handling and edge cases
6. Performance optimization
7. Prepare for deployment

**Total Duration:** 4 weeks (was 8 weeks with complex architecture)

---

## Testing Strategy

### Unit Tests
```dart
// Example test for BLE data parsing
group('BLE Data Serialization', () {
  test('should parse environmental data correctly', () {
    // Arrange - Real byte sequence from MushPi device
    final testData = [
      0x2C, 0x01, // CO2: 300 ppm (u16 little-endian)
      0xE2, 0x00, // Temp: 22.6°C (226 / 10, s16 little-endian)
      0x94, 0x03, // RH: 91.6% (916 / 10, u16 little-endian)
      0xC8, 0x01, // Light: 456 (u16 little-endian)
      0x10, 0x27, 0x00, 0x00, // Uptime: 10000ms (u32 little-endian)
    ];
    
    // Act
    final result = BLEDataSerializer.parseEnvironmentalData(testData);
    
    // Assert
    expect(result.co2Ppm, equals(300));
    expect(result.temperatureC, closeTo(22.6, 0.1));
    expect(result.relativeHumidity, closeTo(91.6, 0.1));
    expect(result.lightRaw, equals(456));
    expect(result.uptimeMs, equals(10000));
  });
  
  test('should serialize and parse control targets correctly', () {
    // Arrange
    final targets = ControlTargets(
      tempMin: 18.0,
      tempMax: 24.0,
      rhMin: 85.0,
      co2Max: 1000,
      lightMode: LightMode.cycle,
      onMinutes: 960,  // 16 hours
      offMinutes: 480, // 8 hours
    );
    
    // Act - Serialize to bytes
    final bytes = BLEDataSerializer.serializeControlTargets(targets);
    
    // Assert - Should be exactly 15 bytes
    expect(bytes.length, equals(15));
    
    // Act - Parse back from bytes
    final parsed = BLEDataSerializer.parseControlTargets(bytes);
    
    // Assert - Should match original
    expect(parsed.tempMin, equals(18.0));
    expect(parsed.tempMax, equals(24.0));
    expect(parsed.rhMin, equals(85.0));
    expect(parsed.co2Max, equals(1000));
    expect(parsed.lightMode, equals(LightMode.cycle));
    expect(parsed.onMinutes, equals(960));
    expect(parsed.offMinutes, equals(480));
  });
  
  test('should handle negative temperatures correctly', () {
    // Arrange - Testing signed 16-bit temperature
    final testData = [
      0x00, 0x00, // CO2: 0 ppm
      0x38, 0xFF, // Temp: -20.0°C (-200 / 10, s16 little-endian = 0xFF38)
      0x00, 0x00, // RH: 0%
      0x00, 0x00, // Light: 0
      0x00, 0x00, 0x00, 0x00, // Uptime: 0ms
    ];
    
    // Act
    final result = BLEDataSerializer.parseEnvironmentalData(testData);
    
    // Assert
    expect(result.temperatureC, closeTo(-20.0, 0.1));
  });
  
  test('should serialize override bits correctly', () {
    // Arrange - Enable light and fan, disable automation
    final bits = OverrideBits.light | OverrideBits.fan | OverrideBits.disableAuto;
    
    // Act
    final bytes = BLEDataSerializer.serializeOverrideBits(bits);
    
    // Assert
    expect(bytes.length, equals(2));
    expect(bytes[0], equals(0x83)); // 10000011 in binary
    expect(bytes[1], equals(0x00));
  });
  
  test('should parse status flags correctly', () {
    // Arrange - Sensor error + threshold alarm + connectivity
    final testData = [
      0x19, 0x00, 0x00, 0x00, // Bits 0, 3, 4 set (u32 little-endian)
    ];
    
    // Act
    final flags = BLEDataSerializer.parseStatusFlags(testData);
    
    // Assert
    expect(flags & StatusFlags.sensorError, isNonZero);
    expect(flags & StatusFlags.thresholdAlarm, isNonZero);
    expect(flags & StatusFlags.connectivity, isNonZero);
    expect(flags & StatusFlags.controlError, isZero);
  });
});
```

### Widget Tests
```dart
// Example widget test for environmental card
testWidgets('EnvironmentalDataCard displays data correctly', (tester) async {
  // Arrange
  const testData = EnvironmentalData(
    co2Ppm: 1200,
    temperatureC: 22.5,
    relativeHumidity: 92.1,
    lightRaw: 450,
    uptimeMs: 120000,
    timestamp: DateTime(2025, 10, 6),
  );
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EnvironmentalDataCard(
          title: 'Temperature',
          value: '${testData.temperatureC}°C',
          statusColor: Colors.green,
          icon: Icons.thermostat,
        ),
      ),
    ),
  );
  
  // Assert
  expect(find.text('Temperature'), findsOneWidget);
  expect(find.text('22.5°C'), findsOneWidget);
  expect(find.byIcon(Icons.thermostat), findsOneWidget);
});
```

### Integration Tests
```dart
// Example integration test for BLE connection flow
void main() {
  group('BLE Connection Flow', () {
    testWidgets('complete connection flow works correctly', (tester) async {
      // Mock BLE service
      final mockBLEService = MockBLEService();
      when(mockBLEService.scanForDevices()).thenAnswer(
        (_) => Stream.value([MockBLEDevice('MushPi-OysterPinning')]),
      );
      
      // App with dependency injection
      await tester.pumpWidget(MyApp(bleService: mockBLEService));
      
      // Navigate to device scan
      await tester.tap(find.text('Connect Device'));
      await tester.pumpAndSettle();
      
      // Verify scan screen appears
      expect(find.text('Scanning for devices...'), findsOneWidget);
      
      // Tap on device to connect
      await tester.tap(find.text('MushPi-OysterPinning'));
      await tester.pumpAndSettle();
      
      // Verify navigation to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

---

## Deployment & Distribution

### Build Configuration
```yaml
# pubspec.yaml - Simplified dependencies
name: mushpi_mobile
description: Mobile controller for MushPi mushroom cultivation system
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management (single source of truth)
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # BLE Communication
  flutter_blue_plus: ^1.12.13
  
  # Navigation
  go_router: ^12.1.1
  
  # Database (type-safe, auto-migrations)
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Data Models (immutable, code generation)
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # UI
  fl_chart: ^0.65.0
  google_fonts: ^6.1.0
  
  # Utils
  hooks_riverpod: ^2.4.9
  flutter_hooks: ^0.20.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Code Generation
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  drift_dev: ^2.14.0
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  
  # Testing
  mockito: ^5.4.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png
```

### App Initialization (Simple)
```dart
// main.dart - Clean, simple setup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = AppDatabase();
  
  runApp(
    ProviderScope(
      overrides: [
        // Provide database to all providers
        databaseProvider.overrideWithValue(database),
      ],
      child: const MushPiApp(),
    ),
  );
}

// app.dart - MaterialApp setup
class MushPiApp extends ConsumerWidget {
  const MushPiApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MushPi Mobile',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
```

### Platform-Specific Configuration

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<application
    android:label="MushPi Mobile"
    android:icon="@mipmap/ic_launcher">
    
    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        android:theme="@style/LaunchTheme">
        
        <meta-data
            android:name="io.flutter.embedding.android.NormalTheme"
            android:resource="@style/NormalTheme" />
            
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity>
</application>
```

#### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to your MushPi device for monitoring and control.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to your MushPi device for monitoring and control.</string>
```

### Release Build Commands
```bash
# Android release build
flutter build apk --release --split-per-abi
flutter build appbundle --release

# iOS release build
flutter build ios --release --no-codesign
```

---

## Security & Privacy Considerations

### BLE Security
- **Device Authentication**: Verify device identity through service UUID and advertising name
- **Bonding/Pairing**: Implement proper BLE bonding for secure connections
- **Data Validation**: Validate all incoming BLE data for bounds and format
- **Connection Timeouts**: Implement reasonable timeouts to prevent hanging connections

### Data Privacy
- **Local Storage Only**: All data stored locally on device (no cloud sync by default)
- **User Consent**: Clear privacy policy regarding data collection and usage
- **Minimal Permissions**: Request only essential permissions for BLE functionality
- **Data Retention**: Implement data retention policies for historical sensor data

### Application Security
```dart
// Input validation example
class DataValidator {
  static bool isValidTemperature(double temp) {
    return temp >= -20.0 && temp <= 60.0;
  }
  
  static bool isValidHumidity(double humidity) {
    return humidity >= 0.0 && humidity <= 100.0;
  }
  
  static bool isValidCO2(int co2) {
    return co2 >= 0 && co2 <= 10000;
  }
}

// Secure BLE data handling
class SecureBLEService {
  Future<bool> validateDevice(BluetoothDevice device) async {
    // Verify device advertising the correct service UUID
    final services = await device.discoverServices();
    return services.any((s) => s.uuid.toString() == Config.serviceUUID);
  }
  
  void sanitizeIncomingData(List<int> data) {
    // Validate data length and format before processing
    if (data.length != expectedLength) {
      throw InvalidDataException('Unexpected data length');
    }
  }
}
```

---

## Maintenance & Support Plan

### Error Handling & Logging
```dart
// Centralized logging service
class LoggingService {
  static final Logger _logger = Logger();
  
  static void logInfo(String message, [Map<String, dynamic>? context]) {
    _logger.i(message, context);
  }
  
  static void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
  }
  
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }
  
  static void logBLEEvent(String event, Map<String, dynamic> data) {
    _logger.d('BLE Event: $event', data);
  }
}

// Global error handling
class GlobalErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    LoggingService.logError('Unhandled error', error, stackTrace);
    
    // Show user-friendly error message
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Update Strategy
- **Semantic Versioning**: Follow semver for all releases
- **Compatibility Matrix**: Maintain compatibility with MushPi firmware versions
- **Migration Scripts**: Database migration scripts for app updates
- **Feature Flags**: Use feature flags for gradual rollout of new features

### Documentation Plan
- **User Manual**: Comprehensive user guide with screenshots
- **API Documentation**: BLE protocol documentation for developers
- **Troubleshooting Guide**: Common issues and solutions
- **Developer Documentation**: Code architecture and contribution guidelines

---

## Success Metrics & KPIs

### Technical Metrics
- **Connection Reliability**: >95% successful BLE connections
- **Data Update Frequency**: Real-time updates within 5 seconds
- **App Startup Time**: <3 seconds to dashboard
- **Battery Usage**: <5% per hour during active monitoring
- **Crash Rate**: <0.1% of user sessions

### User Experience Metrics
- **User Onboarding**: <2 minutes from app install to first connection
- **Task Completion**: >90% success rate for common tasks
- **User Retention**: >80% weekly active users
- **Support Requests**: <5% of users requiring support
- **App Store Rating**: >4.5 stars average rating

### Business Metrics
- **Download Rate**: Track adoption curve
- **Device Integration**: Number of active MushPi devices connected
- **Feature Usage**: Analytics on most/least used features
- **User Feedback**: Systematic collection and analysis of user feedback

---

## Risk Assessment & Mitigation

### Technical Risks
| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|---------|-------------------|
| BLE compatibility issues | Medium | High | Extensive testing on multiple devices; MushPi uses standard BLE GATT (well-supported) |
| Battery drain from BLE | Medium | Medium | Optimize scanning intervals, use notifications (not polling), implement smart power management |
| Data corruption during transmission | Low | High | Validate data lengths (12/15/10/2/4 bytes), check value ranges, use little-endian consistently |
| Byte order issues | Low | Medium | All data is little-endian; test on both iOS and Android |
| Integer overflow in parsing | Low | Medium | Validate ranges before parsing (temp: -20 to 60°C, etc.) |
| App store rejection | Low | High | Follow platform guidelines strictly, prepare compliance documentation |
| Device advertising name parsing | Low | Low | Implement robust regex parsing for `MushPi-*` pattern |

### Project Risks
| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|---------|-------------------|
| Timeline delays | Medium | Medium | Buffer time in schedule, prioritize core features |
| Resource constraints | Low | High | Clear scope definition, MVP approach |
| Changing requirements | Medium | Low | Agile development approach, regular stakeholder reviews |
| Third-party dependency issues | Low | Medium | Evaluate alternatives, vendor lock-in assessment |

---

## Conclusion

This comprehensive Flutter App Plan provides a detailed roadmap for developing the MushPi Mobile Controller application. The plan balances technical excellence with user experience, ensuring a robust, maintainable, and delightful mobile application for mushroom cultivation enthusiasts.

### Key Success Factors
1. **Single Source of Truth**: Riverpod providers eliminate state synchronization issues
2. **Automatic Persistence**: Every state change auto-saved to Drift database
3. **Simple User Flow**: 6 screens total, linear navigation, clear purpose
4. **Offline-First**: App works without constant BLE connection
5. **Type-Safe Database**: Drift provides compile-time safety and auto-migrations
6. **Testable Architecture**: Riverpod makes testing simple and reliable

### Next Steps
1. **Stakeholder Review**: Present plan to stakeholders for approval
2. **Resource Allocation**: Assign development team and set timeline
3. **Development Environment**: Set up CI/CD pipeline and development tools
4. **Prototype Development**: Create basic prototype for early feedback
5. **Project Kickoff**: Begin Phase 1 development according to timeline

---

**Document Version**: 1.0  
**Last Updated**: October 6, 2025  
**Next Review**: Weekly during development phases