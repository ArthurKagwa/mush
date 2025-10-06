# MushPi Flutter Mobile App Development Plan

## Project Overview

**Project Name:** MushPi Mobile Controller  
**Platform:** Flutter (iOS & Android)  
**Target System:** MushPi Raspberry Pi mushroom cultivation controller  
**Communication:** BLE GATT protocol  
**Version:** 1.0.0  
**Created:** October 6, 2025

### Mission Statement
Create a beautiful, intuitive Flutter mobile application that provides seamless wireless control and monitoring of the MushPi mushroom cultivation system through BLE GATT communication.

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

### Technology Stack
- **Framework**: Flutter 3.x with Dart 3.x
- **State Management**: Built-in Flutter solutions (ChangeNotifier, ValueNotifier)
- **BLE Communication**: `flutter_blue_plus` package
- **Navigation**: `go_router` for declarative routing
- **Data Persistence**: `sqflite` for local storage
- **Charts/Graphs**: `fl_chart` for data visualization
- **Theme/UI**: Material Design 3 with custom theming

### Project Structure
```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── ble_config.dart
│   │   └── theme_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── ble_uuids.dart
│   │   └── colors.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── extensions/
│       ├── datetime_extensions.dart
│       └── string_extensions.dart
├── data/
│   ├── models/
│   │   ├── environmental_data.dart
│   │   ├── control_targets.dart
│   │   ├── stage_state.dart
│   │   ├── override_bits.dart
│   │   └── status_flags.dart
│   ├── repositories/
│   │   ├── ble_repository.dart
│   │   ├── settings_repository.dart
│   │   └── local_storage_repository.dart
│   └── services/
│       ├── ble_service.dart
│       ├── notification_service.dart
│       └── data_logging_service.dart
├── domain/
│   ├── entities/
│   │   ├── mushroom_chamber.dart
│   │   ├── sensor_reading.dart
│   │   └── growth_stage.dart
│   ├── use_cases/
│   │   ├── connect_to_device.dart
│   │   ├── monitor_environment.dart
│   │   ├── update_control_targets.dart
│   │   └── manage_growth_stages.dart
│   └── repositories/
│       └── mushpi_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   ├── device_scan/
│   │   ├── dashboard/
│   │   ├── environmental/
│   │   ├── control/
│   │   ├── stages/
│   │   ├── settings/
│   │   └── about/
│   ├── widgets/
│   │   ├── common/
│   │   ├── charts/
│   │   ├── cards/
│   │   └── dialogs/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── color_schemes.dart
│   │   └── text_themes.dart
│   └── view_models/
│       ├── dashboard_view_model.dart
│       ├── environmental_view_model.dart
│       ├── control_view_model.dart
│       └── stage_view_model.dart
└── routes/
    ├── app_router.dart
    └── route_constants.dart
```

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
- Scan for devices advertising MushPi service UUID: `12345678-1234-5678-1234-56789abcdef0`
- Parse advertising name: `MushPi-<species><stage>` format
- Implement connection state management with proper error handling
- Store paired devices for automatic reconnection

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
- Subscribe to `env_measurements` characteristic (UUID: `12345678-1234-5678-1234-56789abcdef1`)
- Parse binary data: CO₂ (u16), Temp×10 (s16), RH×10 (u16), light_raw (u16), uptime_ms (u32)
- Update UI with 5-second intervals (or characteristic notification frequency)

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
- Read/Write to `control_targets` characteristic (UUID: `12345678-1234-5678-1234-56789abcdef2`)
- Binary format: temp_min×10, temp_max×10, rh_min×10, co2_max, light_mode, on_minutes, off_minutes
- Validate input ranges before sending to device
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
- Read/Write to `stage_state` characteristic (UUID: `12345678-1234-5678-1234-56789abcdef3`)
- Binary format: mode, species_id, stage_id, stage_start_ts, expected_days
- Handle stage transitions with user confirmation
- Update advertising name when stage changes

#### Species & Stages:
```dart
enum Species {
  oyster(0, 'Oyster'),
  shiitake(1, 'Shiitake'),
  lionsMane(2, "Lion's Mane");
  
  const Species(this.id, this.displayName);
  final int id;
  final String displayName;
}

enum GrowthStage {
  incubation(0, 'Incubation'),
  pinning(1, 'Pinning'),
  fruiting(2, 'Fruiting');
  
  const GrowthStage(this.id, this.displayName);
  final int id;
  final String displayName;
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
- Write to `override_bits` characteristic (UUID: `12345678-1234-5678-1234-56789abcdef4`)
- Binary format: bit flags (LIGHT=0, FAN=1, MIST=2, HEATER=3, DISABLE_AUTO=7)
- No read capability - write-only characteristic
- Implement safety timeouts to prevent equipment damage

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
- Subscribe to `status_flags` characteristic (UUID: `12345678-1234-5678-1234-56789abcdef5`)
- Monitor flags: SENSOR_ERROR, RELAY_ERROR, TEMP_ALARM, RH_ALARM, CO2_ALARM, etc.
- Display appropriate alerts and recommendations
- Implement notification system for critical alerts

---

## BLE Data Models

### Core Data Classes
```dart
@freezed
class EnvironmentalData with _$EnvironmentalData {
  const factory EnvironmentalData({
    required int co2Ppm,
    required double temperatureC,
    required double relativeHumidity,
    required int lightRaw,
    required int uptimeMs,
    required DateTime timestamp,
  }) = _EnvironmentalData;
  
  factory EnvironmentalData.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalDataFromJson(json);
}

@freezed
class ControlTargets with _$ControlTargets {
  const factory ControlTargets({
    required double tempMin,
    required double tempMax,
    required double rhMin,
    required int co2Max,
    required LightMode lightMode,
    required int onMinutes,
    required int offMinutes,
  }) = _ControlTargets;
  
  factory ControlTargets.fromJson(Map<String, dynamic> json) =>
      _$ControlTargetsFromJson(json);
}

@freezed
class StageState with _$StageState {
  const factory StageState({
    required ControlMode mode,
    required Species species,
    required GrowthStage stage,
    required DateTime stageStartTime,
    required int expectedDays,
  }) = _StageState;
  
  factory StageState.fromJson(Map<String, dynamic> json) =>
      _$StageStateFromJson(json);
}
```

### BLE Binary Serialization
```dart
class BLEDataSerializer {
  static EnvironmentalData parseEnvironmentalData(List<int> data) {
    final buffer = ByteData.fromList(data);
    
    return EnvironmentalData(
      co2Ppm: buffer.getUint16(0, Endian.little),
      temperatureC: buffer.getInt16(2, Endian.little) / 10.0,
      relativeHumidity: buffer.getUint16(4, Endian.little) / 10.0,
      lightRaw: buffer.getUint16(6, Endian.little),
      uptimeMs: buffer.getUint32(8, Endian.little),
      timestamp: DateTime.now(),
    );
  }
  
  static List<int> serializeControlTargets(ControlTargets targets) {
    final buffer = ByteData(14);
    
    buffer.setInt16(0, (targets.tempMin * 10).round(), Endian.little);
    buffer.setInt16(2, (targets.tempMax * 10).round(), Endian.little);
    buffer.setUint16(4, (targets.rhMin * 10).round(), Endian.little);
    buffer.setUint16(6, targets.co2Max, Endian.little);
    buffer.setUint8(8, targets.lightMode.index);
    buffer.setUint16(9, targets.onMinutes, Endian.little);
    buffer.setUint16(11, targets.offMinutes, Endian.little);
    buffer.setUint8(13, 0); // Reserved
    
    return buffer.buffer.asUint8List();
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

## State Management Architecture

### MVVM Pattern Implementation
```dart
// View Model Base Class
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() => setError(null);
}

// Dashboard View Model
class DashboardViewModel extends BaseViewModel {
  final BLEService _bleService;
  final DataLoggingService _dataService;
  
  EnvironmentalData? _currentData;
  StageState? _currentStage;
  List<StatusFlag> _activeAlerts = [];
  
  // Getters
  EnvironmentalData? get currentData => _currentData;
  StageState? get currentStage => _currentStage;
  List<StatusFlag> get activeAlerts => _activeAlerts;
  
  // Methods
  Future<void> initialize() async {
    setLoading(true);
    try {
      await _bleService.connect();
      _startDataSubscription();
    } catch (e) {
      setError('Failed to connect to device: $e');
    } finally {
      setLoading(false);
    }
  }
  
  void _startDataSubscription() {
    _bleService.environmentalDataStream.listen(
      (data) {
        _currentData = data;
        notifyListeners();
      },
      onError: (error) => setError('Data stream error: $error'),
    );
  }
}
```

### Dependency Injection
```dart
// Service Locator
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;
  ServiceLocator._();
  
  final Map<Type, dynamic> _services = {};
  
  void register<T>(T service) {
    _services[T] = service;
  }
  
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }
}

// App initialization
void setupServiceLocator() {
  final serviceLocator = ServiceLocator.instance;
  
  serviceLocator.register<BLEService>(BLEService());
  serviceLocator.register<SettingsRepository>(SettingsRepository());
  serviceLocator.register<LocalStorageRepository>(LocalStorageRepository());
  serviceLocator.register<DataLoggingService>(DataLoggingService());
}
```

---

## Navigation Structure

### Route Configuration
```dart
// Route constants
class RouteConstants {
  static const String splash = '/';
  static const String deviceScan = '/scan';
  static const String dashboard = '/dashboard';
  static const String environmental = '/environmental';
  static const String control = '/control';
  static const String stages = '/stages';
  static const String manual = '/manual';
  static const String settings = '/settings';
  static const String about = '/about';
}

// Router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: RouteConstants.splash,
  routes: [
    GoRoute(
      path: RouteConstants.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteConstants.deviceScan,
      builder: (context, state) => const DeviceScanScreen(),
    ),
    GoRoute(
      path: RouteConstants.dashboard,
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'environmental',
          builder: (context, state) => const EnvironmentalScreen(),
        ),
        GoRoute(
          path: 'control',
          builder: (context, state) => const ControlScreen(),
        ),
        GoRoute(
          path: 'stages',
          builder: (context, state) => const StagesScreen(),
        ),
        GoRoute(
          path: 'manual',
          builder: (context, state) => const ManualControlScreen(),
        ),
      ],
    ),
    GoRoute(
      path: RouteConstants.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: RouteConstants.about,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
  errorBuilder: (context, state) => const ErrorScreen(),
);
```

---

## Development Timeline

### Phase 1: Foundation (Weeks 1-2)
**Deliverables:**
- [ ] Project setup and configuration
- [ ] Core architecture implementation
- [ ] BLE service foundation
- [ ] Basic navigation structure
- [ ] Theme and design system

**Tasks:**
1. Create Flutter project with proper structure
2. Add essential dependencies (flutter_blue_plus, go_router, etc.)
3. Implement BLE service discovery and connection
4. Create base view models and repository patterns
5. Set up Material Design 3 theming
6. Implement basic navigation with go_router

### Phase 2: Core Features (Weeks 3-4)
**Deliverables:**
- [ ] Device scanning and connection
- [ ] Environmental data monitoring
- [ ] Basic dashboard implementation
- [ ] BLE characteristic communication

**Tasks:**
1. Complete BLE device scanning screen
2. Implement environmental data parsing and display
3. Create dashboard with real-time data
4. Add basic charts for environmental trends
5. Implement connection management and error handling

### Phase 3: Control Features (Weeks 5-6)
**Deliverables:**
- [ ] Control targets adjustment
- [ ] Growth stage management
- [ ] Manual override controls
- [ ] Status monitoring and alerts

**Tasks:**
1. Create control settings screens
2. Implement threshold adjustment UI
3. Add growth stage management
4. Create manual override controls
5. Implement status flags monitoring

### Phase 4: Polish & Testing (Weeks 7-8)
**Deliverables:**
- [ ] UI/UX refinements
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Documentation and deployment

**Tasks:**
1. UI/UX improvements and animations
2. Comprehensive unit and widget testing
3. Integration testing with simulated BLE
4. Performance optimization and bug fixes
5. Prepare for deployment and create documentation

---

## Testing Strategy

### Unit Tests
```dart
// Example test for BLE data parsing
group('BLE Data Serialization', () {
  test('should parse environmental data correctly', () {
    // Arrange
    final testData = [
      0x2C, 0x01, // CO2: 300 ppm
      0xE2, 0x00, // Temp: 22.6°C (226 / 10)
      0x94, 0x03, // RH: 91.6% (916 / 10)
      0xC8, 0x01, // Light: 456
      0x10, 0x27, 0x00, 0x00, // Uptime: 10000ms
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
# pubspec.yaml key sections
name: mushpi_mobile
description: Mobile controller for MushPi mushroom cultivation system
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_blue_plus: ^1.12.13
  go_router: ^12.1.1
  google_fonts: ^6.1.0
  sqflite: ^2.3.0
  fl_chart: ^0.65.0
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  change_notifier_provider: ^6.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  mockito: ^5.4.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
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
| BLE compatibility issues | Medium | High | Extensive testing on multiple devices, fallback communication modes |
| Battery drain from BLE | Medium | Medium | Optimize scanning intervals, implement smart power management |
| Data corruption during transmission | Low | High | Implement checksums and data validation |
| App store rejection | Low | High | Follow platform guidelines strictly, prepare compliance documentation |

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
1. **Modular Architecture**: Clean separation of concerns enables maintainability
2. **BLE Integration**: Robust communication with the MushPi hardware system
3. **User-Centric Design**: Intuitive interface for both novice and expert users
4. **Quality Assurance**: Comprehensive testing strategy ensures reliability
5. **Future-Proof Design**: Extensible architecture supports future enhancements

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