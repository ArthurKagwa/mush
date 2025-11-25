# MushPi Flutter Mobile App Development Plan

## Project Overview

**Project Name:** MushPi Mobile Controller  
**Platform:** Flutter (iOS & Android)  
**Target System:** MushPi Raspberry Pi mushroom cultivation controller  
**Communication:** BLE GATT protocol  
**Version:** 2.0.0  
**Created:** October 6, 2025  
**Last Updated:** November 4, 2025

### Mission Statement
Create a beautiful, intuitive Flutter mobile application that provides seamless wireless control and monitoring of multiple MushPi mushroom cultivation farms through BLE GATT communication. Each device represents a farm, and users can manage multiple farms with comprehensive analytics across their entire operation.

### Implementation Status
This plan has been updated to reflect:
- The **actual implemented MushPi BLE GATT service** including real UUIDs, data formats, and characteristic behaviors from the production codebase
- **Multi-farm architecture** where each device identifies a unique farm, users can own multiple farms, and the dashboard provides cross-farm analytics

---

## Executive Summary

The MushPi Flutter app will serve as the primary user interface for monitoring and controlling the Raspberry Pi-based mushroom cultivation system. The app will connect via BLE GATT to read environmental sensors, adjust control parameters, manage growth stages, and provide real-time status updates.

### Key Features
- **Multi-Farm Management**: Manage unlimited farms, each represented by a MushPi device
- **Farm Analytics Dashboard**: Cross-farm analytics, performance metrics, and insights
- **Real-time Monitoring**: Live environmental data per farm (CO₂, temperature, humidity, light)
- **Intelligent Control**: Adjust thresholds and control parameters per farm
- **Stage Management**: Monitor and control growth stages per farm (Incubation, Pinning, Fruiting)
- **Override Controls**: Manual relay overrides for emergency situations
- **Farm Comparison**: Compare environmental conditions and yields across farms
- **Production Tracking**: Track harvests, yields, and production metrics per farm
- **Status Dashboard**: System health and alert monitoring across all farms
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
│   │   ├── farm.dart                # NEW: Farm entity
│   │   ├── farm_analytics.dart      # NEW: Farm analytics data
│   │   ├── environmental_data.dart
│   │   ├── control_targets.dart
│   │   ├── stage_state.dart
│   │   ├── harvest_record.dart      # NEW: Harvest tracking
│   │   └── device_info.dart
│   ├── database/
│   │   ├── app_database.dart        # Drift database definition
│   │   ├── daos/                    # Data access objects
│   │   │   ├── farms_dao.dart       # NEW: Farm operations
│   │   │   ├── analytics_dao.dart   # NEW: Analytics queries
│   │   │   ├── harvests_dao.dart    # NEW: Harvest tracking
│   │   │   ├── readings_dao.dart    # Environmental readings
│   │   │   ├── settings_dao.dart    # App settings
│   │   │   └── devices_dao.dart     # Saved devices
│   │   └── tables/
│   │       ├── farms_table.dart     # NEW: Farms table
│   │       ├── harvests_table.dart  # NEW: Harvests table
│   │       ├── readings_table.dart
│   │       ├── settings_table.dart
│   │       └── devices_table.dart
│   └── repositories/
│       ├── farm_repository.dart     # NEW: Farm operations
│       ├── ble_repository.dart      # BLE communication only
│       └── database_repository.dart # Database operations only
│
├── providers/                       # SINGLE SOURCE OF TRUTH
│   ├── app_state_provider.dart      # Main app state
│   ├── farms_provider.dart          # NEW: All farms management
│   ├── current_farm_provider.dart   # NEW: Currently selected farm
│   ├── analytics_provider.dart      # NEW: Cross-farm analytics
│   ├── ble_provider.dart            # BLE connection state
│   ├── device_provider.dart         # Current device data
│   └── settings_provider.dart       # User preferences
│
├── screens/                         # UPDATED for multi-farm
│   ├── splash_screen.dart           # 1. App launch
│   ├── home_screen.dart             # 2. Farm overview (all farms)
│   ├── farm_list_screen.dart        # NEW: Manage all farms
│   ├── farm_dashboard_screen.dart   # NEW: Analytics across farms
│   ├── device_scan_screen.dart      # 3. Find devices & link to farms
│   ├── farm_detail_screen.dart      # 4. Single farm monitoring (was dashboard)
│   ├── settings_screen.dart         # 5. App settings
│   └── history_screen.dart          # 6. Historical data (per farm or all)
│
└── widgets/                         # Reusable UI components
    ├── farm_card.dart               # NEW: Farm summary card
    ├── farm_analytics_widget.dart   # NEW: Analytics visualization
    ├── farm_comparison_chart.dart   # NEW: Compare farms
    ├── harvest_tracker.dart         # NEW: Harvest recording
    ├── connection_card.dart
    ├── environmental_card.dart
    ├── control_slider.dart
    ├── stage_selector.dart
    ├── chart_widget.dart
    └── status_indicator.dart
```

### Key Architecture Changes
1. **Multi-farm support** - Each device represents one farm; users can manage multiple farms
2. **Farm entity** - New core entity representing a mushroom farm with metadata and analytics
3. **Cross-farm analytics** - Dashboard shows aggregated data and comparisons across all farms
4. **Farm-device binding** - Each device is permanently linked to a farm
5. **Harvest tracking** - Record harvests and yields per farm for production analytics
6. **Performance comparison** - Compare environmental compliance, yields, and efficiency across farms
7. **Single state provider** - One source of truth for all app state (updated for multi-farm)
8. **Combined screens** - Fewer screens, simpler navigation (with farm context)
9. **Automatic persistence** - All state changes auto-saved to DB
10. **Provider-based** - Riverpod providers replace ViewModels

---

## Automation Levels & Mushroom Species Management

### Core Automation Philosophy
The app supports **three automation levels** matching the MushPi device implementation, giving users full control over how much automation they want. The system is **species-aware** with built-in threshold profiles for common mushroom types while allowing full customization.

### Automation Modes (Backward Compatible)

#### 1. FULL AUTO Mode (Mode ID: 0)
**Description**: Complete hands-free operation with automatic stage advancement  
**Use Case**: Experienced growers who trust the system, commercial operations  

**Behavior**:
- ✅ Automatically maintains environmental targets (temp, humidity, CO₂, light)
- ✅ Automatically advances growth stages when conditions met
- ✅ Monitors stage age and compliance ratio
- ✅ Sends notifications for stage transitions
- ⚠️ User can override manually if needed

**BLE Integration**:
```dart
// Write to stage_state characteristic (Byte 0 = 0)
StageState(
  mode: ControlMode.full,  // ID: 0
  species: Species.oyster,
  stage: GrowthStage.incubation,
  stageStartTime: DateTime.now(),
  expectedDays: 14,
)
```

#### 2. SEMI-AUTO Mode (Mode ID: 1)
**Description**: Automatic environmental control with manual stage confirmation  
**Use Case**: Default for most users, learning growers, cautious operations  

**Behavior**:
- ✅ Automatically maintains environmental targets
- ✅ Monitors stage readiness (age + compliance)
- 📱 Sends notification when stage advancement recommended
- ❌ Waits for user confirmation before advancing stage
- ✅ Shows "Ready to advance" indicator in UI
- ✅ User reviews conditions and confirms manually

**UI Flow**:
```
Device detects stage ready → App shows notification
→ User opens app → "Ready for Pinning" banner displayed
→ User reviews current conditions → Taps "Advance to Pinning"
→ Confirmation dialog → Stage advanced → Thresholds updated
```

#### 3. MANUAL Mode (Mode ID: 2)
**Description**: Full manual control, no automation  
**Use Case**: Experimental grows, custom species, research, learning  

**Behavior**:
- ❌ No automatic environmental control
- ❌ No automatic stage advancement
- ❌ No stage readiness monitoring
- ✅ User controls all relays manually via override bits
- ✅ Thresholds shown as reference only
- ✅ Full data logging and monitoring continues

**Override Controls**:
- Manual relay switches (Light, Fan, Mist, Heater)
- Timer-based overrides
- Safety confirmations for critical actions
- Clear indication of manual mode status

### Mushroom Species Profiles

The app includes **built-in threshold profiles** for common mushroom species, based on the MushPi `thresholds.json` format. Users can select a species during farm creation or modify thresholds later.

#### Supported Species (Expandable)

**1. Oyster Mushroom (Pleurotus ostreatus)** - Species ID: 1
```dart
Species.oyster(1, 'Oyster', profiles: {
  GrowthStage.incubation: ThresholdProfile(
    tempMin: 24.0, tempMax: 28.0,
    rhMin: 70.0, co2Max: 5000,
    lightMode: LightMode.off,
    expectedDays: 14,
  ),
  GrowthStage.pinning: ThresholdProfile(
    tempMin: 18.0, tempMax: 22.0,
    rhMin: 90.0, co2Max: 1000,
    lightMode: LightMode.cycle,
    onMinutes: 960,  // 16h on
    offMinutes: 480, // 8h off
    expectedDays: 5,
  ),
  GrowthStage.fruiting: ThresholdProfile(
    tempMin: 15.0, tempMax: 20.0,
    rhMin: 85.0, co2Max: 800,
    lightMode: LightMode.cycle,
    onMinutes: 900,  // 15h on
    offMinutes: 540, // 9h off
    expectedDays: 0, // Ongoing until harvest
  ),
})
```

**2. Shiitake (Lentinula edodes)** - Species ID: 2
```dart
Species.shiitake(2, 'Shiitake', profiles: {
  GrowthStage.incubation: ThresholdProfile(
    tempMin: 21.0, tempMax: 27.0,
    rhMin: 75.0, co2Max: 5000,
    lightMode: LightMode.off,
    expectedDays: 21, // Longer colonization
  ),
  GrowthStage.pinning: ThresholdProfile(
    tempMin: 13.0, tempMax: 18.0, // Cooler shock
    rhMin: 85.0, co2Max: 1000,
    lightMode: LightMode.cycle,
    onMinutes: 720,  // 12h on
    offMinutes: 720, // 12h off
    expectedDays: 7,
  ),
  GrowthStage.fruiting: ThresholdProfile(
    tempMin: 13.0, tempMax: 21.0,
    rhMin: 80.0, co2Max: 1000,
    lightMode: LightMode.cycle,
    onMinutes: 720,
    offMinutes: 720,
    expectedDays: 0,
  ),
})
```

**3. Lion's Mane (Hericium erinaceus)** - Species ID: 3
```dart
Species.lionsMane(3, "Lion's Mane", profiles: {
  GrowthStage.incubation: ThresholdProfile(
    tempMin: 22.0, tempMax: 25.0,
    rhMin: 70.0, co2Max: 5000,
    lightMode: LightMode.off,
    expectedDays: 18,
  ),
  GrowthStage.pinning: ThresholdProfile(
    tempMin: 16.0, tempMax: 20.0,
    rhMin: 85.0, co2Max: 1200,
    lightMode: LightMode.cycle,
    onMinutes: 720,
    offMinutes: 720,
    expectedDays: 6,
  ),
  GrowthStage.fruiting: ThresholdProfile(
    tempMin: 16.0, tempMax: 20.0,
    rhMin: 85.0, co2Max: 1000,
    lightMode: LightMode.cycle,
    onMinutes: 720,
    offMinutes: 720,
    expectedDays: 0,
  ),
})
```

**4. Custom Species** - Species ID: 99
```dart
Species.custom(99, 'Custom', profiles: {
  // User-defined thresholds
  // All values editable
  // No stage advancement automation
})
```

### Threshold Management System

#### Threshold Profile Data Model
```dart
@freezed
class ThresholdProfile with _$ThresholdProfile {
  const factory ThresholdProfile({
    required double tempMin,        // Celsius
    required double tempMax,        // Celsius
    required double rhMin,          // Percentage (0-100)
    required int co2Max,            // PPM
    required LightMode lightMode,   // OFF, ON, CYCLE
    @Default(0) int onMinutes,      // For CYCLE mode
    @Default(0) int offMinutes,     // For CYCLE mode
    @Default(0) int expectedDays,   // Stage duration
    String? notes,                  // Optional user notes
  }) = _ThresholdProfile;
  
  factory ThresholdProfile.fromJson(Map<String, dynamic> json) =>
      _$ThresholdProfileFromJson(json);
  
  // Convert to BLE ControlTargets format (backward compatible)
  ControlTargets toControlTargets() {
    return ControlTargets(
      tempMin: tempMin,
      tempMax: tempMax,
      rhMin: rhMin,
      co2Max: co2Max,
      lightMode: lightMode,
      onMinutes: onMinutes,
      offMinutes: offMinutes,
    );
  }
  
  // Validate threshold ranges
  bool isValid() {
    return tempMin >= -20.0 && tempMin < tempMax && tempMax <= 60.0 &&
           rhMin >= 0.0 && rhMin <= 100.0 &&
           co2Max >= 0 && co2Max <= 10000 &&
           (lightMode != LightMode.cycle || 
            (onMinutes > 0 && offMinutes > 0 && 
             onMinutes + offMinutes <= 1440));
  }
}

@freezed
class FarmThresholds with _$FarmThresholds {
  const factory FarmThresholds({
    required String farmId,
    required Species species,
    required Map<GrowthStage, ThresholdProfile> profiles,
    DateTime? lastModified,
    bool? isCustom,  // True if user modified from defaults
  }) = _FarmThresholds;
  
  factory FarmThresholds.fromJson(Map<String, dynamic> json) =>
      _$FarmThresholdsFromJson(json);
  
  // Load from species template
  factory FarmThresholds.fromSpecies(String farmId, Species species) {
    return FarmThresholds(
      farmId: farmId,
      species: species,
      profiles: species.defaultProfiles,
      lastModified: DateTime.now(),
      isCustom: false,
    );
  }
}
```

#### Species Selection During Farm Creation

**User Flow**:
```
1. Add Farm → Scan Device → Device Found
2. Farm Setup Screen:
   ┌─────────────────────────────────────┐
   │ Create New Farm                     │
   ├─────────────────────────────────────┤
   │ Farm Name *                         │
   │ [Basement Farm          ]           │
   │                                     │
   │ Mushroom Species *                  │
   │ ┌─────────┬─────────┬─────────┐    │
   │ │ Oyster  │Shiitake │ Lion's  │    │
   │ │   🍄    │   🍄    │  Mane   │    │
   │ │ [✓]    │ [ ]     │ [ ]     │    │
   │ └─────────┴─────────┴─────────┘    │
   │ ┌─────────┐                        │
   │ │ Custom  │                        │
   │ │   ⚙️     │                        │
   │ │ [ ]     │                        │
   │ └─────────┘                        │
   │                                     │
   │ Location (optional)                 │
   │ [Portland, OR           ]           │
   │                                     │
   │ Starting Stage                      │
   │ [Incubation ▼]                     │
   │                                     │
   │ ℹ️ Oyster thresholds will be       │
   │    applied automatically            │
   │                                     │
   │    [Cancel]  [Create Farm]         │
   └─────────────────────────────────────┘

3. Farm Created → Thresholds auto-loaded → Stage state synced to device
```

#### Threshold Editing UI

**Per-Stage Threshold Editor**:
```
┌─────────────────────────────────────┐
│ ← Edit Thresholds - Basement Farm   │
├─────────────────────────────────────┤
│ Species: Oyster 🍄                  │
│ Current Stage: Pinning              │
│                                     │
│ [Incubation] [Pinning] [Fruiting]  │
│              ────────                │
├─────────────────────────────────────┤
│ 🌡️ Temperature Range                │
│ Min: [18.0°C    ●━━━━━━] 30.0°C    │
│ Max: [18.0°C ━━━━●━━━━] 30.0°C     │
│                                     │
│ 💧 Humidity Minimum                 │
│ Min: [90.0%  ━━━━━━━━●━] 100%      │
│                                     │
│ 💨 CO₂ Maximum                      │
│ Max: [1000   ━●━━━━━━━━] 5000ppm   │
│                                     │
│ 💡 Light Schedule                   │
│ Mode: [⦿ Cycle  ○ On  ○ Off]       │
│ On:   [16 hrs ━━━●━━━━] 24h        │
│ Off:  [8 hrs  ━━●━━━━━] 24h        │
│                                     │
│ 📅 Expected Duration                │
│ Days: [5      ] days                │
│                                     │
│ ⚠️ Modified from Oyster defaults    │
│                                     │
│ [Reset to Defaults]  [Save Changes] │
└─────────────────────────────────────┘
```

### Automation Mode Selection

**Automation Settings Screen**:
```
┌─────────────────────────────────────┐
│ ← Automation Settings               │
├─────────────────────────────────────┤
│ Farm: Basement Farm                 │
│ Species: Oyster                     │
│                                     │
│ Automation Mode                     │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⦿ FULL AUTO                     │ │
│ │   Complete automation           │ │
│ │   • Auto environmental control  │ │
│ │   • Auto stage advancement      │ │
│ │   • Hands-free operation        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ○ SEMI-AUTO (Recommended)       │ │
│ │   Assisted control              │ │
│ │   • Auto environmental control  │ │
│ │   • Manual stage confirmation   │ │
│ │   • Notifications for stages    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ○ MANUAL                        │ │
│ │   Full manual control           │ │
│ │   • Manual relay control        │ │
│ │   • No automation               │ │
│ │   • For experienced users       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Current Stage: Pinning (Day 3/5)    │
│                                     │
│ ✅ Will sync to device on save      │
│                                     │
│         [Cancel]  [Apply]           │
└─────────────────────────────────────┘
```

### Backward Compatibility Strategy

#### 1. BLE Protocol Compatibility
**Ensures existing MushPi devices work without firmware updates**

```dart
class BackwardCompatibilityLayer {
  // Handle devices that don't report species ID
  static Species detectSpeciesFromAdvertising(String deviceName) {
    // MushPi-OysterPinning → Oyster
    // MushPi-ShiitakeFruit → Shiitake
    // MushPi-LionIncub → Lion's Mane
    final regex = RegExp(r'MushPi-(Oyster|Shiitake|Lion)');
    final match = regex.firstMatch(deviceName);
    
    if (match != null) {
      switch (match.group(1)) {
        case 'Oyster': return Species.oyster;
        case 'Shiitake': return Species.shiitake;
        case 'Lion': return Species.lionsMane;
      }
    }
    
    return Species.oyster; // Default fallback
  }
  
  // Handle legacy control targets (without species info)
  static ControlTargets parseLegacyControlTargets(List<int> data) {
    // Parse standard 15-byte format
    // Species info derived from farm record, not BLE data
    return BLEDataSerializer.parseControlTargets(data);
  }
  
  // Sync farm species to device advertising name
  static Future<void> syncSpeciesToDevice(
    Farm farm,
    BLERepository ble,
  ) async {
    final stageState = StageState(
      mode: farm.automationMode,
      species: farm.primarySpecies ?? Species.oyster,
      stage: farm.currentStage ?? GrowthStage.incubation,
      stageStartTime: farm.stageStartTime ?? DateTime.now(),
      expectedDays: farm.currentStageExpectedDays ?? 14,
    );
    
    await ble.writeStageState(stageState);
    // Device updates advertising name: MushPi-OysterIncub
  }
}
```

#### 2. Threshold File Compatibility
**Reads existing MushPi `thresholds.json` format**

```dart
class ThresholdMigration {
  // Import from MushPi thresholds.json format
  static FarmThresholds importFromMushPiJson(
    String farmId,
    Map<String, dynamic> json,
  ) {
    // json format: { "Oyster": { "Incubation": {...}, ... } }
    
    final speciesName = json.keys.first;
    final species = _parseSpeciesName(speciesName);
    final stageData = json[speciesName] as Map<String, dynamic>;
    
    final profiles = <GrowthStage, ThresholdProfile>{};
    
    for (final entry in stageData.entries) {
      final stage = _parseStageN ame(entry.key);
      final data = entry.value as Map<String, dynamic>;
      
      profiles[stage] = ThresholdProfile(
        tempMin: (data['temp_min'] as num).toDouble(),
        tempMax: (data['temp_max'] as num).toDouble(),
        rhMin: (data['rh_min'] as num).toDouble(),
        co2Max: data['co2_max'] as int,
        lightMode: _parseLightMode(data['light']['mode'] as String),
        onMinutes: data['light']['on_min'] as int? ?? 0,
        offMinutes: data['light']['off_min'] as int? ?? 0,
        expectedDays: data['expected_days'] as int? ?? 0,
      );
    }
    
    return FarmThresholds(
      farmId: farmId,
      species: species,
      profiles: profiles,
      lastModified: DateTime.now(),
      isCustom: false,
    );
  }
  
  // Export to MushPi thresholds.json format
  static Map<String, dynamic> exportToMushPiJson(FarmThresholds thresholds) {
    final stageData = <String, dynamic>{};
    
    for (final entry in thresholds.profiles.entries) {
      final stage = entry.key;
      final profile = entry.value;
      
      stageData[stage.displayName] = {
        'temp_min': profile.tempMin,
        'temp_max': profile.tempMax,
        'rh_min': profile.rhMin,
        'co2_max': profile.co2Max,
        'light': {
          'mode': profile.lightMode.name,
          'on_min': profile.onMinutes,
          'off_min': profile.offMinutes,
        },
        'expected_days': profile.expectedDays,
      };
    }
    
    return {thresholds.species.displayName: stageData};
  }
}
```

#### 3. Database Migration
**Handles apps upgrading from single-device to multi-farm**

```dart
class DatabaseMigration {
  // Migrate from v1 (single device) to v2 (multi-farm)
  static Future<void> migrateToMultiFarm(AppDatabase db) async {
    // Check if migration needed
    final existingDevices = await db.devicesDao.getAllDevices();
    final existingFarms = await db.farmsDao.getAllFarms();
    
    if (existingDevices.isNotEmpty && existingFarms.isEmpty) {
      // Create farm for each orphaned device
      for (final device in existingDevices) {
        if (device.farmId == null) {
          // Detect species from device name
          final species = BackwardCompatibilityLayer
              .detectSpeciesFromAdvertising(device.name);
          
          // Create farm
          final farm = Farm(
            id: uuid.v4(),
            name: '${species.displayName} Farm',
            deviceId: device.deviceId,
            createdAt: device.lastConnected,
            lastActive: device.lastConnected,
            primarySpecies: species,
          );
          
          await db.farmsDao.insertFarm(farm);
          
          // Update device with farm link
          await db.devicesDao.updateDevice(
            device.copyWith(farmId: farm.id),
          );
          
          // Migrate readings
          await db.readingsDao.updateFarmIdForDevice(
            device.deviceId,
            farm.id,
          );
          
          // Load species default thresholds
          final thresholds = FarmThresholds.fromSpecies(farm.id, species);
          await db.settingsDao.saveFarmThresholds(thresholds);
        }
      }
    }
  }
}
```

### Advanced Threshold Features

#### 1. Threshold Templates Library
```dart
class ThresholdTemplates {
  static final Map<String, FarmThresholds> templates = {
    'oyster_aggressive': FarmThresholds(...),  // Faster fruiting
    'oyster_conservative': FarmThresholds(...), // Slower, safer
    'shiitake_warm': FarmThresholds(...),      // Warmer temps
    'shiitake_cold': FarmThresholds(...),      // Cooler shock
    // ... more templates
  };
  
  static List<String> getTemplatesForSpecies(Species species) {
    return templates.keys
        .where((k) => k.startsWith(species.name.toLowerCase()))
        .toList();
  }
}
```

#### 2. Threshold Comparison & Recommendations
```dart
class ThresholdAnalyzer {
  // Compare farm's thresholds against top performers
  static ThresholdRecommendations analyzeAndRecommend(
    FarmThresholds current,
    List<FarmAnalytics> topPerformers,
  ) {
    // Analyze what top performers use
    // Suggest adjustments
    // Show impact predictions
  }
  
  // Detect if thresholds are too tight (causing alerts)
  static List<ThresholdWarning> detectIssues(
    FarmThresholds thresholds,
    List<Alert> recentAlerts,
  ) {
    // If many temp alerts → suggest wider range
    // If many CO2 alerts → suggest higher max
  }
}
```

#### 3. Seasonal Adjustments
```dart
class SeasonalThresholds {
  // Suggest adjustments based on season
  static ThresholdProfile adjustForSeason(
    ThresholdProfile base,
    Season season,
  ) {
    // Summer: Lower temp targets slightly
    // Winter: Higher humidity targets (dry air)
    // Fall/Spring: Standard
  }
}
```

---

## Multi-Farm Architecture

### Core Concept
**One Device = One Farm**
- Each MushPi device represents a unique mushroom cultivation farm
- Users can own and manage multiple farms (home setup, commercial operations, etc.)
- Each farm has its own environmental history, control settings, and production records
- The app provides both individual farm views and cross-farm analytics

### Farm Entity Model
```dart
@freezed
class Farm with _$Farm {
  const factory Farm({
    required String id,                    // Unique farm ID (UUID)
    required String name,                  // User-defined name (e.g., "Basement Farm", "Greenhouse A")
    required String deviceId,              // Linked MushPi device ID (one-to-one)
    String? location,                      // Optional location (e.g., "Portland, OR")
    String? notes,                         // Farm notes/description
    required DateTime createdAt,           // Farm creation date
    DateTime? lastActive,                  // Last time device connected
    @Default(0) int totalHarvests,         // Total number of harvests
    @Default(0.0) double totalYieldKg,     // Total yield in kilograms
    Species? primarySpecies,               // Primary mushroom species grown
    String? imageUrl,                      // Farm photo (local path)
    @Default(true) bool isActive,          // Farm status (active/archived)
    Map<String, dynamic>? metadata,        // Additional metadata
  }) = _Farm;
  
  factory Farm.fromJson(Map<String, dynamic> json) => _$FarmFromJson(json);
}

@freezed
class FarmAnalytics with _$FarmAnalytics {
  const factory FarmAnalytics({
    required String farmId,
    required String farmName,
    
    // Environmental performance
    required double avgTemperature,
    required double avgHumidity,
    required double avgCO2,
    required double tempCompliancePercent,   // % time within target range
    required double humidityCompliancePercent,
    required double co2CompliancePercent,
    
    // Production metrics
    required int harvestCount,
    required double totalYieldKg,
    required double avgYieldPerHarvest,
    required int daysInProduction,
    required double yieldPerDay,
    
    // Stage tracking
    GrowthStage? currentStage,
    required int daysInCurrentStage,
    required int stageTransitions,
    
    // System health
    required int totalAlerts,
    required int criticalAlerts,
    required double uptimePercent,
    DateTime? lastConnection,
    
    // Time period
    required DateTime periodStart,
    required DateTime periodEnd,
  }) = _FarmAnalytics;
  
  factory FarmAnalytics.fromJson(Map<String, dynamic> json) => 
      _$FarmAnalyticsFromJson(json);
}

@freezed
class HarvestRecord with _$HarvestRecord {
  const factory HarvestRecord({
    required String id,
    required String farmId,
    required DateTime harvestDate,
    required Species species,
    required GrowthStage stage,
    required double yieldKg,
    int? flushNumber,                      // Which flush (1st, 2nd, etc.)
    double? qualityScore,                  // 0-10 quality rating
    String? notes,
    List<String>? photoUrls,               // Harvest photos
    Map<String, dynamic>? metadata,
  }) = _HarvestRecord;
  
  factory HarvestRecord.fromJson(Map<String, dynamic> json) => 
      _$HarvestRecordFromJson(json);
}

@freezed
class CrossFarmComparison with _$CrossFarmComparison {
  const factory CrossFarmComparison({
    required List<FarmAnalytics> farms,
    required FarmAnalytics averages,       // Average across all farms
    required FarmAnalytics topPerformer,   // Best performing farm
    required FarmAnalytics bottomPerformer, // Lowest performing farm
    required Map<String, double> speciesBreakdown, // % by species
    required Map<String, int> stageDistribution,   // Farms per stage
  }) = _CrossFarmComparison;
  
  factory CrossFarmComparison.fromJson(Map<String, dynamic> json) => 
      _$CrossFarmComparisonFromJson(json);
}
```

### Database Schema Updates
```dart
// New Farms table
class Farms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get deviceId => text().unique()();  // One device per farm
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActive => dateTime().nullable()();
  IntColumn get totalHarvests => integer().withDefault(const Constant(0))();
  RealColumn get totalYieldKg => real().withDefault(const Constant(0.0))();
  IntColumn get primarySpecies => integer().nullable()();  // Species enum
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get metadata => text().nullable()();  // JSON
  
  @override
  Set<Column> get primaryKey => {id};
}

// New Harvests table
class Harvests extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  DateTimeColumn get harvestDate => dateTime()();
  IntColumn get species => integer()();
  IntColumn get stage => integer()();
  RealColumn get yieldKg => real()();
  IntColumn get flushNumber => integer().nullable()();
  RealColumn get qualityScore => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrls => text().nullable()();  // JSON array
  TextColumn get metadata => text().nullable()();   // JSON
  
  @override
  Set<Column> get primaryKey => {id};
}

// Updated Devices table (add farm relationship)
class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get farmId => text().nullable().references(Farms, #id)();  // NEW
  DateTimeColumn get lastConnected => dateTime()();
  
  @override
  Set<Column> get primaryKey => {deviceId};
}

// Updated Readings table (add farm relationship)
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get farmId => text().references(Farms, #id)();  // NEW
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get co2Ppm => integer()();
  RealColumn get temperatureC => real()();
  RealColumn get relativeHumidity => real()();
  IntColumn get lightRaw => integer()();
}
```

### Multi-Farm State Management
```dart
// Farms provider - manages all farms
@riverpod
class Farms extends _$Farms {
  @override
  Future<List<Farm>> build() async {
    // Load all farms from database
    return await ref.read(farmRepositoryProvider).getAllFarms();
  }
  
  Future<void> addFarm(Farm farm) async {
    await ref.read(farmRepositoryProvider).createFarm(farm);
    ref.invalidateSelf();  // Reload farms list
  }
  
  Future<void> updateFarm(Farm farm) async {
    await ref.read(farmRepositoryProvider).updateFarm(farm);
    ref.invalidateSelf();
  }
  
  Future<void> deleteFarm(String farmId) async {
    await ref.read(farmRepositoryProvider).deleteFarm(farmId);
    ref.invalidateSelf();
  }
  
  Future<void> linkDeviceToFarm(String farmId, String deviceId) async {
    await ref.read(farmRepositoryProvider).linkDevice(farmId, deviceId);
    ref.invalidateSelf();
  }
}

// Current farm provider - tracks selected farm
@riverpod
class CurrentFarm extends _$CurrentFarm {
  @override
  String? build() {
    // Load last selected farm from preferences
    return ref.read(settingsRepositoryProvider).getLastSelectedFarmId();
  }
  
  void selectFarm(String farmId) {
    state = farmId;
    ref.read(settingsRepositoryProvider).saveLastSelectedFarmId(farmId);
  }
  
  void clearSelection() {
    state = null;
  }
}

// Farm analytics provider
@riverpod
class FarmAnalyticsProvider extends _$FarmAnalyticsProvider {
  @override
  Future<FarmAnalytics> build(String farmId, {Duration period = const Duration(days: 30)}) async {
    final repo = ref.read(analyticsRepositoryProvider);
    return await repo.calculateFarmAnalytics(
      farmId, 
      DateTime.now().subtract(period),
      DateTime.now(),
    );
  }
}

// Cross-farm analytics provider
@riverpod
class CrossFarmAnalyticsProvider extends _$CrossFarmAnalyticsProvider {
  @override
  Future<CrossFarmComparison> build({Duration period = const Duration(days: 30)}) async {
    final farms = await ref.watch(farmsProvider.future);
    final repo = ref.read(analyticsRepositoryProvider);
    
    final analytics = await Future.wait(
      farms.map((farm) => repo.calculateFarmAnalytics(
        farm.id,
        DateTime.now().subtract(period),
        DateTime.now(),
      )),
    );
    
    return repo.generateCrossFarmComparison(analytics);
  }
}

// Updated AppState for multi-farm context
@freezed
class AppStateData with _$AppStateData {
  const factory AppStateData({
    required ConnectionStatus connectionStatus,
    String? currentFarmId,                 // NEW: Currently viewing farm
    DeviceInfo? connectedDevice,
    EnvironmentalData? environmentalData,
    ControlTargets? controlTargets,
    StageState? stageState,
    List<EnvironmentalData> historicalData,
    int? statusFlags,
    DateTime? lastUpdate,
    @Default([]) List<Farm> allFarms,      // NEW: All user farms
  }) = _AppStateData;
  
  factory AppStateData.initial() => const AppStateData(
    connectionStatus: ConnectionStatus.disconnected,
    historicalData: [],
    allFarms: [],
  );
}
```

### Farm Analytics Repository
```dart
class AnalyticsRepository {
  final AppDatabase _db;
  
  /// Calculate comprehensive analytics for a single farm
  Future<FarmAnalytics> calculateFarmAnalytics(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get all readings for farm in period
    final readings = await _db.readingsDao.getReadingsByFarmAndPeriod(
      farmId, startDate, endDate,
    );
    
    // Get all harvests for farm in period
    final harvests = await _db.harvestsDao.getHarvestsByFarmAndPeriod(
      farmId, startDate, endDate,
    );
    
    // Get control targets for compliance calculation
    final targets = await _db.settingsDao.getControlTargetsForFarm(farmId);
    
    // Calculate environmental averages
    final avgTemp = readings.map((r) => r.temperatureC).average;
    final avgHumidity = readings.map((r) => r.relativeHumidity).average;
    final avgCO2 = readings.map((r) => r.co2Ppm).average;
    
    // Calculate compliance percentages
    final tempCompliance = _calculateCompliance(
      readings.map((r) => r.temperatureC),
      targets.tempMin,
      targets.tempMax,
    );
    
    final humidityCompliance = _calculateCompliance(
      readings.map((r) => r.relativeHumidity),
      targets.rhMin,
      100.0,
    );
    
    final co2Compliance = readings
        .where((r) => r.co2Ppm <= targets.co2Max)
        .length / readings.length * 100;
    
    // Calculate production metrics
    final totalYield = harvests.map((h) => h.yieldKg).sum;
    final avgYield = harvests.isEmpty ? 0.0 : totalYield / harvests.length;
    final daysInProduction = endDate.difference(startDate).inDays;
    final yieldPerDay = daysInProduction == 0 ? 0.0 : totalYield / daysInProduction;
    
    // Get current stage info
    final stageState = await _db.settingsDao.getStageStateForFarm(farmId);
    final daysInStage = stageState != null
        ? DateTime.now().difference(stageState.stageStartTime).inDays
        : 0;
    
    // Count alerts
    final alerts = await _db.alertsDao.getAlertsByFarmAndPeriod(
      farmId, startDate, endDate,
    );
    final criticalAlerts = alerts.where((a) => a.severity == 'critical').length;
    
    // Calculate uptime
    final uptimePercent = _calculateUptime(readings, startDate, endDate);
    
    return FarmAnalytics(
      farmId: farmId,
      farmName: (await _db.farmsDao.getFarmById(farmId))!.name,
      avgTemperature: avgTemp,
      avgHumidity: avgHumidity,
      avgCO2: avgCO2,
      tempCompliancePercent: tempCompliance,
      humidityCompliancePercent: humidityCompliance,
      co2CompliancePercent: co2Compliance,
      harvestCount: harvests.length,
      totalYieldKg: totalYield,
      avgYieldPerHarvest: avgYield,
      daysInProduction: daysInProduction,
      yieldPerDay: yieldPerDay,
      currentStage: stageState?.stage,
      daysInCurrentStage: daysInStage,
      stageTransitions: await _countStageTransitions(farmId, startDate, endDate),
      totalAlerts: alerts.length,
      criticalAlerts: criticalAlerts,
      uptimePercent: uptimePercent,
      lastConnection: (await _db.farmsDao.getFarmById(farmId))!.lastActive,
      periodStart: startDate,
      periodEnd: endDate,
    );
  }
  
  /// Generate cross-farm comparison
  Future<CrossFarmComparison> generateCrossFarmComparison(
    List<FarmAnalytics> farmAnalytics,
  ) async {
    if (farmAnalytics.isEmpty) {
      throw StateError('No farms to compare');
    }
    
    // Calculate averages across all farms
    final averages = FarmAnalytics(
      farmId: 'average',
      farmName: 'All Farms Average',
      avgTemperature: farmAnalytics.map((f) => f.avgTemperature).average,
      avgHumidity: farmAnalytics.map((f) => f.avgHumidity).average,
      avgCO2: farmAnalytics.map((f) => f.avgCO2).average,
      tempCompliancePercent: farmAnalytics.map((f) => f.tempCompliancePercent).average,
      humidityCompliancePercent: farmAnalytics.map((f) => f.humidityCompliancePercent).average,
      co2CompliancePercent: farmAnalytics.map((f) => f.co2CompliancePercent).average,
      harvestCount: farmAnalytics.map((f) => f.harvestCount).sum,
      totalYieldKg: farmAnalytics.map((f) => f.totalYieldKg).sum,
      avgYieldPerHarvest: farmAnalytics.map((f) => f.avgYieldPerHarvest).average,
      daysInProduction: farmAnalytics.first.daysInProduction,
      yieldPerDay: farmAnalytics.map((f) => f.yieldPerDay).average,
      currentStage: null,
      daysInCurrentStage: 0,
      stageTransitions: farmAnalytics.map((f) => f.stageTransitions).sum,
      totalAlerts: farmAnalytics.map((f) => f.totalAlerts).sum,
      criticalAlerts: farmAnalytics.map((f) => f.criticalAlerts).sum,
      uptimePercent: farmAnalytics.map((f) => f.uptimePercent).average,
      lastConnection: null,
      periodStart: farmAnalytics.first.periodStart,
      periodEnd: farmAnalytics.first.periodEnd,
    );
    
    // Find top and bottom performers (by yield per day)
    final sorted = List<FarmAnalytics>.from(farmAnalytics)
      ..sort((a, b) => b.yieldPerDay.compareTo(a.yieldPerDay));
    
    // Species breakdown
    final allFarms = await _db.farmsDao.getAllFarms();
    final speciesBreakdown = <String, double>{};
    for (final species in Species.values) {
      final count = allFarms.where((f) => f.primarySpecies == species).length;
      speciesBreakdown[species.displayName] = count / allFarms.length * 100;
    }
    
    // Stage distribution
    final stageDistribution = <String, int>{};
    for (final farm in farmAnalytics) {
      if (farm.currentStage != null) {
        final stage = farm.currentStage!.displayName;
        stageDistribution[stage] = (stageDistribution[stage] ?? 0) + 1;
      }
    }
    
    return CrossFarmComparison(
      farms: farmAnalytics,
      averages: averages,
      topPerformer: sorted.first,
      bottomPerformer: sorted.last,
      speciesBreakdown: speciesBreakdown,
      stageDistribution: stageDistribution,
    );
  }
  
  double _calculateCompliance(
    Iterable<double> values,
    double min,
    double max,
  ) {
    final inRange = values.where((v) => v >= min && v <= max).length;
    return values.isEmpty ? 0.0 : inRange / values.length * 100;
  }
  
  double _calculateUptime(
    List<Reading> readings,
    DateTime start,
    DateTime end,
  ) {
    if (readings.isEmpty) return 0.0;
    
    final expectedReadings = end.difference(start).inMinutes / 5; // Every 5 min
    return (readings.length / expectedReadings * 100).clamp(0, 100);
  }
}
```

---

## Detailed Feature Specifications

### 1. Device Discovery & Connection with Farm Setup
**Priority**: Critical  
**Complexity**: Medium  

#### Features:
- Automatic BLE device scanning for MushPi devices
- Device list with signal strength indicators and detected species
- Farm creation wizard with species selection
- One-tap connection with automatic pairing
- Connection status monitoring with auto-reconnect
- Device information display (name, address, services)
- Automatic threshold loading based on selected species

#### Technical Details:
- Use `flutter_blue_plus` for BLE operations
- **Scan for devices advertising MushPi service UUID:** `12345678-1234-5678-1234-56789abcdef0`
- **Parse advertising name format:** `MushPi-<species><stage>`
  - Examples: `MushPi-OysterPinning`, `MushPi-ShiitakeFruiting`, `MushPi-LionIncub`
  - Auto-detect species from advertising name for pre-selection
  - Format changes automatically when device stage transitions
- **Required BLE Permissions:**
  - Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`
  - iOS: `NSBluetoothAlwaysUsageDescription`
- Implement connection state management with proper error handling
- Store last connected device for automatic reconnection
- **Service Discovery:** After connection, verify service UUID `12345678-1234-5678-1234-56789abcdef0`
- **Characteristic Discovery:** Locate all 5 characteristics (env, control, stage, override, status)

#### Farm Setup Flow:
```
1. Scan for devices → Found: MushPi-OysterPinning
2. User taps device → Farm Setup Wizard opens
3. Auto-fills:
   - Detected Species: Oyster (from device name)
   - Current Stage: Pinning (from device name)
4. User customizes:
   - Farm Name: [Basement Farm]
   - Location: [Portland, OR] (optional)
   - Confirms species or changes to Custom
   - Selects automation mode: FULL/SEMI/MANUAL
5. App loads:
   - Species default thresholds
   - Current stage profile
   - Expected days remaining
6. Syncs to device:
   - Writes stage_state with species ID
   - Writes control_targets from threshold profile
   - Device updates advertising name if species changed
7. Farm created → Navigate to Farm Detail
```

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

### 3. Control System Management with Automation Modes
**Priority**: Critical  
**Complexity**: Medium  

#### Features:
- Automation mode selection (FULL/SEMI/MANUAL)
- Species-aware threshold management
- Threshold adjustment sliders/inputs with species templates
- Target range visualization with compliance indicators
- Threshold profile switching per growth stage
- Emergency stop functionality
- Threshold reset to species defaults
- Custom threshold saving and export

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
- Auto-load thresholds when species or stage changes

#### Automation Mode Integration:
```dart
// When automation mode changes
Future<void> onAutomationModeChanged(ControlMode newMode) async {
  // 1. Update stage_state characteristic with new mode
  final currentStage = await repo.getCurrentStageState();
  final updatedStage = currentStage.copyWith(mode: newMode);
  await ble.writeStageState(updatedStage);
  
  // 2. Update UI to reflect mode
  switch (newMode) {
    case ControlMode.full:
      // Show "Auto control active" indicator
      // Hide stage advancement button
      // Show compliance metrics
      break;
    case ControlMode.semi:
      // Show "Auto control active" indicator
      // Show "Ready to advance" when applicable
      // Enable manual stage button
      break;
    case ControlMode.manual:
      // Show "Manual mode" warning
      // Enable all override controls
      // Disable auto-advancement UI
      break;
  }
  
  // 3. Save to farm record
  await farmRepo.updateAutomationMode(farmId, newMode);
}
```

#### Species Threshold Loading:
```dart
// When species changes or farm created
Future<void> loadSpeciesThresholds(Species species, String farmId) async {
  // 1. Get species default profiles
  final thresholds = FarmThresholds.fromSpecies(farmId, species);
  
  // 2. Save to database
  await db.settingsDao.saveFarmThresholds(thresholds);
  
  // 3. Load current stage profile
  final currentStage = await getCurrentStage();
  final profile = thresholds.profiles[currentStage]!;
  
  // 4. Convert to BLE format and write
  final controlTargets = profile.toControlTargets();
  await ble.writeControlTargets(controlTargets);
  
  // 5. Update UI
  setState(() {
    this.thresholds = thresholds;
    this.currentProfile = profile;
  });
}
```

#### UI Design:
- Automation mode selector (radio buttons with descriptions)
- Species badge showing active species
- Stage tabs for switching between threshold profiles
- Sliders with species default indicators
- Visual range selectors for min/max values
- Color-coded status indicators (green=good, yellow=warning, red=critical)
- "Reset to [Species] Defaults" button
- "Apply to Device" confirmation with summary of changes
- Compliance percentage display per metric

### 4. Growth Stage Management with Automation
**Priority**: High  
**Complexity**: Medium  

#### Features:
- Current stage display with progress indicators and compliance metrics
- Stage transition controls (auto in FULL mode, manual in SEMI/MANUAL modes)
- Species and stage selection with automatic threshold updates
- Timeline view of stage progression with expected vs actual duration
- Stage-specific threshold auto-loading
- Stage readiness indicator (age + compliance ratio)
- Automation mode impact on stage management

#### Automation Behavior by Mode:

**FULL AUTO Mode**:
- ✅ Automatically advances stages when criteria met:
  - Minimum age reached (e.g., 14 days in Incubation)
  - Compliance ratio > 85% (time within thresholds)
- ✅ Sends notification before advancement (30 min warning)
- ✅ Updates thresholds to next stage automatically
- ❌ No user confirmation required
- 📱 User can still override or revert manually

**SEMI-AUTO Mode**:
- ✅ Monitors stage readiness (age + compliance)
- 📱 Sends notification when ready: "Basement Farm ready for Pinning"
- ✅ Shows "Ready to Advance" banner in UI
- ❌ Does NOT auto-advance without confirmation
- ✅ User taps "Advance to Pinning" → Confirmation dialog → Stage advanced
- ✅ Thresholds updated after confirmation

**MANUAL Mode**:
- ❌ No automatic monitoring or advancement
- ✅ User can change stage anytime
- ⚠️ Warning shown if changing too early
- ✅ Thresholds updated when user changes stage
- ℹ️ Expected days shown as reference only

#### BLE Integration:
- **Read/Write** `stage_state` characteristic
  - **UUID:** `12345678-1234-5678-1234-56789abcdef3`
  - **Properties:** Read + Write
  - **Data Size:** 10 bytes
  - **Binary Format (little-endian):**
    - Byte 0: Mode (unsigned 8-bit): 0=FULL, 1=SEMI, 2=MANUAL
    - Byte 1: Species ID (unsigned 8-bit): 1=Oyster, 2=Shiitake, 3=Lion's Mane, 99=Custom
    - Byte 2: Stage ID (unsigned 8-bit): 1=Incubation, 2=Pinning, 3=Fruiting
    - Bytes 3-6: Stage start timestamp (unsigned 32-bit, Unix epoch seconds)
    - Bytes 7-8: Expected days (unsigned 16-bit)
    - Byte 9: Reserved (unsigned 8-bit, always 0)
- Handle stage transitions with automatic threshold updates
- Update advertising name when stage changes (device-side automatic)
- Sync species selection to device

#### Stage Advancement Flow (SEMI-AUTO):
```
1. App monitors stage:
   - Days in stage: 14 / 14 (Incubation)
   - Compliance: 92% (last 7 days within thresholds)
   
2. Readiness detected:
   - Age >= expected days ✓
   - Compliance >= 85% ✓
   
3. Notification sent:
   - Title: "Ready for Next Stage"
   - Body: "Basement Farm completed Incubation (92% compliance)"
   - Action: "Review"
   
4. User opens app:
   - Banner shows: "✓ Ready for Pinning"
   - Details: "Incubation: 14 days, 92% compliance"
   - Button: "Advance to Pinning"
   
5. User taps button:
   - Dialog shows:
     ┌─────────────────────────────────┐
     │ Advance to Pinning?             │
     ├─────────────────────────────────┤
     │ Current Stage: Incubation       │
     │ Completed: 14 days (92% comp.)  │
     │                                 │
     │ Next Stage: Pinning             │
     │ Expected: 5 days                │
     │                                 │
     │ Threshold Changes:              │
     │ • Temp: 24-28°C → 18-22°C ❄️    │
     │ • RH: 70% → 90% 💧              │
     │ • CO₂: 5000 → 1000 ppm 💨       │
     │ • Light: OFF → CYCLE (16h) 💡   │
     │                                 │
     │ [Cancel]  [Advance Stage]       │
     └─────────────────────────────────┘
   
6. User confirms:
   - StageState written to device (new stage, new timestamp)
   - ControlTargets written (Pinning thresholds)
   - Device updates advertising: MushPi-OysterPinning
   - Database updated
   - UI refreshed
   - Success notification
```

#### Species & Stages (Updated with Actual IDs):
```dart
enum Species {
  oyster(1, 'Oyster', icon: '🍄'),
  shiitake(2, 'Shiitake', icon: '🍄'),
  lionsMane(3, "Lion's Mane", icon: '🍄'),
  custom(99, 'Custom', icon: '⚙️');
  
  const Species(this.id, this.displayName, {required this.icon});
  final int id;
  final String displayName;
  final String icon;
  
  // Get default threshold profiles for this species
  Map<GrowthStage, ThresholdProfile> get defaultProfiles;
}

enum GrowthStage {
  incubation(1, 'Incubation', icon: '🥚'),
  pinning(2, 'Pinning', icon: '📍'),
  fruiting(3, 'Fruiting', icon: '🍄');
  
  const GrowthStage(this.id, this.displayName, {required this.icon});
  final int id;
  final String displayName;
  final String icon;
  
  GrowthStage? get next {
    switch (this) {
      case incubation: return pinning;
      case pinning: return fruiting;
      case fruiting: return null; // No automatic advancement from fruiting
    }
  }
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

#### Stage Readiness Calculation:
```dart
class StageReadinessChecker {
  static bool isReadyToAdvance(
    StageState current,
    FarmAnalytics analytics,
    ControlMode mode,
  ) {
    // Manual mode: never auto-ready
    if (mode == ControlMode.manual) return false;
    
    // Fruiting stage: no next stage
    if (current.stage == GrowthStage.fruiting) return false;
    
    // Check age requirement
    final daysInStage = DateTime.now()
        .difference(current.stageStartTime)
        .inDays;
    if (daysInStage < current.expectedDays) return false;
    
    // Check compliance (average of all metrics)
    final avgCompliance = (
      analytics.tempCompliancePercent +
      analytics.humidityCompliancePercent +
      analytics.co2CompliancePercent
    ) / 3;
    
    if (avgCompliance < 85.0) return false; // Threshold: 85%
    
    return true;
  }
  
  static Future<void> checkAndNotify(
    String farmId,
    Farm farm,
    FarmAnalytics analytics,
  ) async {
    if (!isReadyToAdvance(farm.stageState, analytics, farm.automationMode)) {
      return;
    }
    
    // Check if we already notified
    final lastNotification = await db.getLastStageReadyNotification(farmId);
    if (lastNotification != null && 
        DateTime.now().difference(lastNotification).inHours < 24) {
      return; // Don't spam notifications
    }
    
    // Send notification
    await NotificationService.send(
      title: 'Ready for Next Stage',
      body: '${farm.name} completed ${farm.stageState.stage.displayName}',
      data: {'farmId': farmId, 'action': 'stage_ready'},
    );
    
    // Record notification
    await db.recordStageReadyNotification(farmId);
    
    // If FULL mode, auto-advance after 30 min delay
    if (farm.automationMode == ControlMode.full) {
      await scheduleAutoAdvancement(farmId, Duration(minutes: 30));
    }
  }
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

#### 1. Farm Dashboard Screen (Cross-Farm Overview)
```
┌─────────────────────────────────────┐
│ ≡  My Farms               [+] [⚙️]  │
├─────────────────────────────────────┤
│ 📊 Total Production (30 days)       │
│ 24.5 kg  •  12 harvests  •  3 farms │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Basement Farm        🔵 Live │ │
│ │ Oyster • Fruiting • Day 12      │ │
│ │ ━━━━━━━━━━━━━━ 92% compliance   │ │
│ │ 8.2kg this month • 4 harvests   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Greenhouse A         🔴 Off  │ │
│ │ Shiitake • Pinning • Day 3      │ │
│ │ ━━━━━━━━━━━━━━ 87% compliance   │ │
│ │ 12.1kg this month • 5 harvests  │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Garage Setup         🔵 Live │ │
│ │ Lion's Mane • Incubation • D 8  │ │
│ │ ━━━━━━━━━━━━━━ 95% compliance   │ │
│ │ 4.2kg this month • 3 harvests   │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 📈 Performance Comparison           │
│ [Charts comparing all farms]        │
│ ┌─────┬─────┬─────┐                 │
│ │Temp │ RH  │ CO₂ │ across farms   │
│ └─────┴─────┴─────┘                 │
├─────────────────────────────────────┤
│ 🏆 Top Performer: Greenhouse A      │
│ 📉 Needs Attention: Basement Farm   │
└─────────────────────────────────────┘
```

#### 2. Farm Detail Screen (Single Farm - was Dashboard Screen)
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

#### 2. Farm Detail Screen (Single Farm - was Dashboard Screen)
```
┌─────────────────────────────────────┐
│ ←  Basement Farm           🔵 [📋]  │
├─────────────────────────────────────┤
│ 🍄 Oyster - Fruiting (Day 12/21)   │
│ 📍 Portland, OR • Started Oct 15    │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │   🌡️    │ │   💧    │ │   💨    │ │
│ │  22.5°C │ │  92.1%  │ │ 1200ppm │ │
│ │ ━━━━━┅━ │ │ ━━━━━━━ │ │ ━━━━┅━━ │ │
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│ 📊 Environmental Trends (24h)       │
│ [Chart showing temp/RH/CO2]         │
├─────────────────────────────────────┤
│ 📦 Production This Month            │
│ 8.2 kg • 4 harvests • Avg 2.05 kg  │
│ [Record Harvest] button             │
├─────────────────────────────────────┤
│ ⚙️  Controls  📋 Stage  🔧 Override │
└─────────────────────────────────────┘
```

#### 3. Farm List & Management Screen
```
┌─────────────────────────────────────┐
│ ←  Manage Farms            [+] [?]  │
├─────────────────────────────────────┤
│ Active Farms (3)                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Basement Farm        🔵      │ │
│ │ Device: MushPi-OysterFruit     │ │
│ │ Created: Oct 1, 2025           │ │
│ │ [View] [Edit] [Archive]        │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Greenhouse A         🔵      │ │
│ │ Device: MushPi-ShiitakePin     │ │
│ │ Created: Sep 15, 2025          │ │
│ │ [View] [Edit] [Archive]        │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🍄 Garage Setup         🔴      │ │
│ │ Device: MushPi-LionIncub       │ │
│ │ Created: Oct 20, 2025          │ │
│ │ [View] [Edit] [Archive]        │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Archived Farms (1)                  │
│ [Show archived farms]               │
└─────────────────────────────────────┘
```

#### 4. Cross-Farm Analytics Screen
```
┌─────────────────────────────────────┐
│ ←  Analytics (Last 30 Days)    [⚙️] │
├─────────────────────────────────────┤
│ 📊 Overall Performance              │
│                                     │
│ Total Production: 24.5 kg           │
│ Total Harvests: 12                  │
│ Active Farms: 3                     │
│ Avg Compliance: 91%                 │
├─────────────────────────────────────┤
│ 🏆 Performance Ranking              │
│ 1. Greenhouse A    - 95% (12.1kg)  │
│ 2. Basement Farm   - 92% (8.2kg)   │
│ 3. Garage Setup    - 87% (4.2kg)   │
├─────────────────────────────────────┤
│ 📈 Comparison Charts                │
│ ┌─────────────────────────────────┐ │
│ │ Compliance by Farm              │ │
│ │ [Bar chart]                     │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Yield per Day                   │ │
│ │ [Line chart showing trends]     │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Species Distribution            │ │
│ │ [Pie chart: 40% Oyster, etc.]  │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ ⚠️  Alerts Across All Farms         │
│ • Basement: High CO₂ (3 times)     │
│ • Greenhouse: Low humidity (1x)    │
└─────────────────────────────────────┘
```

#### 5. Harvest Recording Screen
```
┌─────────────────────────────────────┐
│ ←  Record Harvest              [?]  │
├─────────────────────────────────────┤
│ Farm: Basement Farm                 │
│ Species: Oyster                     │
│ Stage: Fruiting                     │
│ Date: Nov 4, 2025                   │
├─────────────────────────────────────┤
│ Yield (kg) *                        │
│ [2.3        ]                       │
│                                     │
│ Flush Number                        │
│ [2nd ▼]                             │
│                                     │
│ Quality (0-10)                      │
│ ★★★★★★★★☆☆  8/10                   │
│                                     │
│ Notes (optional)                    │
│ [Good size, nice color, ...]       │
│                                     │
│ Photos (optional)                   │
│ [📷 Add Photos] (0)                 │
├─────────────────────────────────────┤
│         [Cancel]  [Save Harvest]    │
└─────────────────────────────────────┘
```

#### 6. Environmental Details Screen
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

### Linear Navigation Path (Multi-Farm)
```
1. Splash Screen
   ↓
2. Home Screen (Farm Overview)
   ├─→ No farms? → Device Scan → Create First Farm
   ├─→ Has farms → Show All Farms Dashboard
   └─→ Tap farm card → Farm Detail Screen
   
3. Farm Dashboard Screen (Cross-Farm Analytics)
   ├─→ View all farms at once
   ├─→ Compare performance metrics
   ├─→ See total production
   ├─→ Manage farms (add/edit/delete)
   └─→ Tap specific farm → Farm Detail Screen
   
4. Farm Detail Screen (Single Farm Monitoring)
   ├─→ Environmental monitoring (real-time)
   ├─→ Control adjustments (slide-up panel)
   ├─→ Stage management (tap stage card)
   ├─→ Manual overrides (emergency FAB)
   ├─→ Harvest recording (harvest button)
   └─→ Farm settings (edit farm)
   
5. Additional Screens
   ├─→ Farm List (manage all farms)
   ├─→ Settings (app preferences)
   ├─→ History (per farm or all farms)
   └─→ Harvest History (production tracking)
```

### User Journey

**First Time User (No Farms):**
```
Splash → Home → "Add Your First Farm" 
       → Scan for Device → Select Device 
       → Name Farm → Farm Detail → Done!
```

**First Time User (Has Unlinked Device):**
```
Splash → Home → Farm Dashboard → "Add Farm"
       → Scan for Device → Link to New Farm
       → Farm Detail → Done!
```

**Returning User (Single Farm):**
```
Splash → Home → Auto-show Farm Detail → Monitor!
```

**Returning User (Multiple Farms):**
```
Splash → Home → Farm Dashboard
       → See all farms at once
       → Tap farm to drill down → Farm Detail
```

**Adding Additional Farm:**
```
Farm Dashboard → FAB "+" → Scan Device
               → Name Farm → Link Device → Done!
```

**Comparing Farms:**
```
Farm Dashboard → View comparison charts
               → See top/bottom performers
               → Identify optimization opportunities
```

**Recording Harvest:**
```
Farm Detail → "Record Harvest" button
            → Enter weight, quality, notes
            → Add photos (optional)
            → Save → Updated analytics!
```

**Viewing Analytics:**
```
Farm Dashboard → See cross-farm metrics
               → Total production
               → Average compliance
               → Best/worst performers
               → Species distribution
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

## Development Timeline (Updated for Multi-Farm Architecture)

### Phase 1: Foundation + Multi-Farm Data Layer (Week 1)
**Deliverables:**
- [x] Project setup with Riverpod + Drift
- [x] Database schema with farms, harvests, and relationships
- [x] Core data models (Freezed) including Farm, FarmAnalytics, HarvestRecord
- [x] BLE serialization utilities
- [x] Basic theme configuration
- [x] Farm repository and analytics repository

**Tasks:**
1. Create Flutter project with proper structure (multi-farm architecture)
2. Add essential dependencies (Riverpod, Drift, flutter_blue_plus, go_router, fl_chart)
3. Define database schema with Drift (5 tables: farms, harvests, readings, settings, devices)
4. Create Freezed data models (7 models: Farm, FarmAnalytics, HarvestRecord, + existing 4)
5. Implement BLE serialization utilities
6. Set up Material Design 3 theming
7. Configure code generation (build_runner)
8. Implement FarmRepository and AnalyticsRepository

### Phase 2: Core Features + Farm Management (Week 2)
**Deliverables:**
- [x] Device scanning and connection
- [x] Farm creation and management
- [x] Multi-farm state providers
- [x] Environmental data monitoring (per farm)
- [x] Automatic persistence
- [x] Farm dashboard (overview of all farms)

**Tasks:**
1. Implement BLE repository (scan, connect, read/write)
2. Create farms provider (manage all farms)
3. Create current farm provider (track selected farm)
4. Create analytics provider (calculate farm analytics)
5. Build device scan screen with farm linking
6. Build home screen with farm overview
7. Build farm dashboard screen (all farms view)
8. Build farm detail screen (single farm monitoring)
9. Implement automatic database persistence
10. Add connection state management per farm

### Phase 3: Analytics + Control & Management (Week 3)
**Deliverables:**
- [x] Cross-farm analytics and comparisons
- [x] Harvest tracking functionality
- [x] Control panel (slide-up, per farm)
- [x] Stage management (per farm)
- [x] Manual overrides
- [x] Settings screen
- [x] Historical data view (per farm and all farms)

**Tasks:**
1. Implement cross-farm analytics calculations
2. Create harvest recording screen and functionality
3. Build farm comparison charts and visualizations
4. Create draggable control panel (per farm)
5. Implement control targets adjustment
6. Add stage selector and management
7. Create manual override dialog
8. Build settings screen
9. Build history screen with farm filtering
10. Add data export functionality (per farm and all farms)
11. Implement farm list/management screen

### Phase 4: Polish, Testing & Multi-Farm Features (Week 4)
**Deliverables:**
- [x] Production metrics and insights
- [x] Farm performance ranking
- [x] UI/UX refinements
- [x] Comprehensive testing
- [x] Error handling
- [x] Documentation
- [x] Release preparation

**Tasks:**
1. Add production tracking and yield analytics
2. Implement farm performance ranking and insights
3. Add farm comparison and recommendations
4. UI/UX improvements and animations
5. Comprehensive unit tests (providers, serialization, analytics)
6. Widget tests (screens, components, farm cards)
7. Integration tests with mock BLE (multi-device scenarios)
8. Error handling and edge cases (farm deletion, device re-linking)
9. Performance optimization (analytics calculations, chart rendering)
10. Prepare for deployment

### Phase 5: Advanced Features (Optional - Week 5)
**Deliverables:**
- [ ] Photo management for farms and harvests
- [ ] Export/import farm data
- [ ] Farm templates for quick setup
- [ ] Advanced analytics (predictive, seasonal patterns)
- [ ] Cloud backup (optional)

**Tasks:**
1. Implement photo capture and management
2. Add data export/import functionality
3. Create farm templates system
4. Build advanced analytics engine
5. Add cloud sync option (if desired)

**Total Duration:** 4-5 weeks

---

## Testing Strategy

### Unit Tests
```dart
// Example test for farm analytics calculations
group('Farm Analytics', () {
  test('should calculate farm analytics correctly', () async {
    // Arrange - Create test farm with readings and harvests
    final farm = Farm(
      id: 'test-farm-1',
      name: 'Test Farm',
      deviceId: 'device-1',
      createdAt: DateTime(2025, 10, 1),
      lastActive: DateTime.now(),
    );
    
    final readings = List.generate(100, (i) => Reading(
      id: i,
      farmId: farm.id,
      timestamp: DateTime.now().subtract(Duration(hours: i)),
      co2Ppm: 800 + (i % 200),
      temperatureC: 20.0 + (i % 5),
      relativeHumidity: 85.0 + (i % 10),
      lightRaw: 400,
    ));
    
    final harvests = [
      HarvestRecord(
        id: 'h1',
        farmId: farm.id,
        harvestDate: DateTime.now(),
        species: Species.oyster,
        stage: GrowthStage.fruiting,
        yieldKg: 2.5,
      ),
      HarvestRecord(
        id: 'h2',
        farmId: farm.id,
        harvestDate: DateTime.now().subtract(Duration(days: 7)),
        species: Species.oyster,
        stage: GrowthStage.fruiting,
        yieldKg: 3.0,
      ),
    ];
    
    // Mock database responses
    when(mockDb.readingsDao.getReadingsByFarmAndPeriod(any, any, any))
      .thenAnswer((_) async => readings);
    when(mockDb.harvestsDao.getHarvestsByFarmAndPeriod(any, any, any))
      .thenAnswer((_) async => harvests);
    
    // Act
    final analytics = await analyticsRepo.calculateFarmAnalytics(
      farm.id,
      DateTime.now().subtract(Duration(days: 30)),
      DateTime.now(),
    );
    
    // Assert
    expect(analytics.farmId, equals(farm.id));
    expect(analytics.harvestCount, equals(2));
    expect(analytics.totalYieldKg, equals(5.5));
    expect(analytics.avgYieldPerHarvest, equals(2.75));
    expect(analytics.avgTemperature, greaterThan(20.0));
    expect(analytics.avgTemperature, lessThan(25.0));
    expect(analytics.tempCompliancePercent, greaterThan(0));
    expect(analytics.tempCompliancePercent, lessThanOrEqualTo(100));
  });
  
  test('should generate cross-farm comparison correctly', () async {
    // Arrange - Multiple farm analytics
    final farmAnalytics = [
      FarmAnalytics(
        farmId: 'farm1',
        farmName: 'Farm 1',
        avgTemperature: 22.0,
        avgHumidity: 90.0,
        avgCO2: 900.0,
        tempCompliancePercent: 95.0,
        humidityCompliancePercent: 92.0,
        co2CompliancePercent: 88.0,
        harvestCount: 5,
        totalYieldKg: 12.5,
        avgYieldPerHarvest: 2.5,
        daysInProduction: 30,
        yieldPerDay: 0.42,
        currentStage: GrowthStage.fruiting,
        daysInCurrentStage: 15,
        stageTransitions: 3,
        totalAlerts: 2,
        criticalAlerts: 0,
        uptimePercent: 98.5,
        lastConnection: DateTime.now(),
        periodStart: DateTime.now().subtract(Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
      FarmAnalytics(
        farmId: 'farm2',
        farmName: 'Farm 2',
        avgTemperature: 20.0,
        avgHumidity: 88.0,
        avgCO2: 950.0,
        tempCompliancePercent: 90.0,
        humidityCompliancePercent: 85.0,
        co2CompliancePercent: 82.0,
        harvestCount: 3,
        totalYieldKg: 8.0,
        avgYieldPerHarvest: 2.67,
        daysInProduction: 30,
        yieldPerDay: 0.27,
        currentStage: GrowthStage.pinning,
        daysInCurrentStage: 5,
        stageTransitions: 2,
        totalAlerts: 5,
        criticalAlerts: 1,
        uptimePercent: 95.0,
        lastConnection: DateTime.now(),
        periodStart: DateTime.now().subtract(Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
    ];
    
    // Act
    final comparison = await analyticsRepo.generateCrossFarmComparison(
      farmAnalytics,
    );
    
    // Assert
    expect(comparison.farms.length, equals(2));
    expect(comparison.averages.avgTemperature, equals(21.0)); // (22+20)/2
    expect(comparison.averages.totalYieldKg, equals(20.5)); // 12.5+8.0
    expect(comparison.topPerformer.farmId, equals('farm1')); // Higher yield/day
    expect(comparison.bottomPerformer.farmId, equals('farm2'));
    expect(comparison.averages.harvestCount, equals(8)); // 5+3
  });
});

// Example test for BLE data parsing (existing, still valid)
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
});
```

### Widget Tests
```dart
// Example widget test for farm card
testWidgets('FarmCard displays farm data correctly', (tester) async {
  // Arrange
  final farm = Farm(
    id: 'test-farm',
    name: 'Test Farm',
    deviceId: 'device-1',
    location: 'Portland, OR',
    createdAt: DateTime(2025, 10, 1),
    lastActive: DateTime.now(),
    totalHarvests: 5,
    totalYieldKg: 12.5,
    primarySpecies: Species.oyster,
  );
  
  final analytics = FarmAnalytics(
    farmId: farm.id,
    farmName: farm.name,
    avgTemperature: 22.0,
    avgHumidity: 90.0,
    avgCO2: 900.0,
    tempCompliancePercent: 95.0,
    humidityCompliancePercent: 92.0,
    co2CompliancePercent: 88.0,
    harvestCount: 5,
    totalYieldKg: 12.5,
    avgYieldPerHarvest: 2.5,
    daysInProduction: 30,
    yieldPerDay: 0.42,
    currentStage: GrowthStage.fruiting,
    daysInCurrentStage: 15,
    stageTransitions: 3,
    totalAlerts: 2,
    criticalAlerts: 0,
    uptimePercent: 98.5,
    lastConnection: DateTime.now(),
    periodStart: DateTime.now().subtract(Duration(days: 30)),
    periodEnd: DateTime.now(),
  );
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FarmCard(
          farm: farm,
          analytics: analytics,
          onTap: () {},
        ),
      ),
    ),
  );
  
  // Assert
  expect(find.text('Test Farm'), findsOneWidget);
  expect(find.text('Portland, OR'), findsOneWidget);
  expect(find.text('Oyster'), findsOneWidget);
  expect(find.text('12.5kg this month'), findsOneWidget);
  expect(find.text('5 harvests'), findsOneWidget);
  expect(find.text('95% compliance'), findsOneWidget);
});

// Example widget test for environmental card (existing, still valid)
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
// Example integration test for multi-farm flow
void main() {
  group('Multi-Farm Management Flow', () {
    testWidgets('user can add multiple farms and switch between them', (tester) async {
      // Mock BLE service and database
      final mockBLEService = MockBLEService();
      final mockDatabase = MockDatabase();
      
      when(mockBLEService.scanForDevices()).thenAnswer(
        (_) => Stream.fromIterable([
          MockBLEDevice('MushPi-OysterPinning', 'device1'),
          MockBLEDevice('MushPi-ShiitakeFruit', 'device2'),
        ]),
      );
      
      // App with dependency injection
      await tester.pumpWidget(MyApp(
        bleService: mockBLEService,
        database: mockDatabase,
      ));
      
      // Start: Home screen shows "Add First Farm"
      expect(find.text('Add Your First Farm'), findsOneWidget);
      
      // Tap to add farm
      await tester.tap(find.text('Add Your First Farm'));
      await tester.pumpAndSettle();
      
      // Should show device scan
      expect(find.text('Scanning for devices...'), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Select first device
      await tester.tap(find.text('MushPi-OysterPinning'));
      await tester.pumpAndSettle();
      
      // Name the farm
      expect(find.text('Name Your Farm'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Basement Farm');
      await tester.tap(find.text('Create Farm'));
      await tester.pumpAndSettle();
      
      // Should navigate to farm detail
      expect(find.text('Basement Farm'), findsOneWidget);
      
      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Add second farm
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Select second device
      await tester.tap(find.text('MushPi-ShiitakeFruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Greenhouse A');
      await tester.tap(find.text('Create Farm'));
      await tester.pumpAndSettle();
      
      // Go back to home - should show both farms
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      expect(find.text('Basement Farm'), findsOneWidget);
      expect(find.text('Greenhouse A'), findsOneWidget);
      expect(find.text('My Farms'), findsOneWidget);
      
      // Tap on first farm to switch
      await tester.tap(find.text('Basement Farm'));
      await tester.pumpAndSettle();
      
      // Should show farm detail for Basement Farm
      expect(find.text('Basement Farm'), findsOneWidget);
      expect(find.text('Oyster'), findsOneWidget);
    });
    
    testWidgets('cross-farm analytics displays correctly', (tester) async {
      // Setup app with 2 farms already created
      final mockDatabase = MockDatabase();
      when(mockDatabase.farmsDao.getAllFarms()).thenAnswer(
        (_) async => [
          Farm(id: 'f1', name: 'Farm 1', deviceId: 'd1', createdAt: DateTime.now()),
          Farm(id: 'f2', name: 'Farm 2', deviceId: 'd2', createdAt: DateTime.now()),
        ],
      );
      
      await tester.pumpWidget(MyApp(database: mockDatabase));
      await tester.pumpAndSettle();
      
      // Should show farm dashboard
      expect(find.text('My Farms'), findsOneWidget);
      expect(find.text('Total Production'), findsOneWidget);
      
      // Should show both farms
      expect(find.text('Farm 1'), findsOneWidget);
      expect(find.text('Farm 2'), findsOneWidget);
      
      // Tap analytics section
      await tester.tap(find.text('Performance Comparison'));
      await tester.pumpAndSettle();
      
      // Should show comparison charts
      expect(find.byType(ComparisonChart), findsWidgets);
      expect(find.text('Top Performer'), findsOneWidget);
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