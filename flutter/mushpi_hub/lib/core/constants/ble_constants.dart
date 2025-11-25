/// BLE GATT Service and Characteristic UUIDs
///
/// These UUIDs must match exactly with the MushPi Raspberry Pi BLE GATT server.
/// Service UUID: 12345678-1234-5678-1234-56789abcdef0 (ENV-CONTROL)
library;

class BLEConstants {
  BLEConstants._();

  /// Main MushPi BLE GATT Service UUID
  static const String serviceUUID = '12345678-1234-5678-1234-56789abcdef0';

  /// Environmental Measurements Characteristic
  /// Properties: Read + Notify
  /// Data: 12 bytes (CO₂, temperature, humidity, light, uptime)
  static const String envMeasurementsUUID =
      '12345678-1234-5678-1234-56789abcdef1';

  /// Control Targets Characteristic
  /// Properties: Read + Write
  /// Data: 15 bytes (temp min/max, humidity min, CO₂ max, light mode, timing)
  static const String controlTargetsUUID =
      '12345678-1234-5678-1234-56789abcdef2';

  /// Stage State Characteristic
  /// Properties: Read + Write
  /// Data: 10 bytes (mode, species, stage, start time, expected days)
  static const String stageStateUUID = '12345678-1234-5678-1234-56789abcdef3';

  /// Override Bits Characteristic
  /// Properties: Write only
  /// Data: 2 bytes (relay override flags)
  static const String overrideBitsUUID = '12345678-1234-5678-1234-56789abcdef4';

  /// Status Flags Characteristic
  /// Properties: Read + Notify
  /// Data: 4 bytes (system status flags)
  static const String statusFlagsUUID = '12345678-1234-5678-1234-56789abcdef5';

  /// Stage Thresholds Characteristic
  /// Properties: Read + Write
  /// Data: JSON format (species, stage, thresholds)
  static const String stageThresholdsUUID =
      '12345678-1234-5678-1234-56789abcdef9';

  /// Actuator Status Characteristic
  /// Properties: Read + Notify
  /// Data: 2 bytes (relay ON/OFF state bitfield)
  static const String actuatorStatusUUID =
      '12345678-1234-5678-1234-56789abcdef6';

  /// Expected data sizes in bytes
  static const int envDataSize = 12;
  static const int controlDataSize = 15;
  static const int stageDataSize = 10;
  static const int overrideDataSize = 2;
  static const int statusDataSize = 4;
  static const int actuatorDataSize =
      6; // 2 bytes status bits + 4 bytes reason codes

  /// Device advertising name format: MushPi-<species><stage>
  /// Examples: "MushPi-OysterPinning", "MushPi-ShiitakeFruit"
  static const String deviceNamePrefix = 'MushPi';

  /// BLE scan timeout (seconds)
  static const int scanTimeoutSeconds = 30;

  /// Connection timeout (seconds)
  static const int connectionTimeoutSeconds = 10;

  /// Notification subscription timeout (seconds)
  static const int notificationTimeoutSeconds = 5;
}

/// Light control modes
enum LightMode {
  off(0, 'Off'),
  on(1, 'On'),
  cycle(2, 'Cycle');

  const LightMode(this.value, this.displayName);

  final int value;
  final String displayName;

  static LightMode fromValue(int value) {
    return LightMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => LightMode.off,
    );
  }
}

/// Control automation modes
enum ControlMode {
  full(0, 'Full Auto', 'Automatic targets + automatic stage progression'),
  semi(1, 'Semi-Auto', 'Automatic targets, manual stage confirmation'),
  manual(2, 'Manual', 'Manual control only, no automation');

  const ControlMode(this.id, this.displayName, this.description);

  final int id;
  final String displayName;
  final String description;

  static ControlMode fromId(int id) {
    return ControlMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => ControlMode.semi,
    );
  }
}

/// Mushroom species with default threshold profiles
enum Species {
  oyster(1, 'Oyster', '🍄'),
  shiitake(2, 'Shiitake', '🍄'),
  lionsMane(3, "Lion's Mane", '🍄'),
  custom(99, 'Custom', '⚙️');

  const Species(this.id, this.displayName, this.icon);

  final int id;
  final String displayName;
  final String icon;

  static Species fromId(int id) {
    return Species.values.firstWhere(
      (species) => species.id == id,
      orElse: () => Species.oyster,
    );
  }

  /// Parse species from device advertising name
  /// Format: "MushPi-OysterPinning" -> Species.oyster
  static Species? fromAdvertisingName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('oyster')) return Species.oyster;
    if (lowerName.contains('shiitake')) return Species.shiitake;
    if (lowerName.contains('lion')) return Species.lionsMane;
    return null;
  }
}

/// Growth stages
enum GrowthStage {
  incubation(1, 'Incubation', '🥚'),
  pinning(2, 'Pinning', '📍'),
  fruiting(3, 'Fruiting', '🍄');

  const GrowthStage(this.id, this.displayName, this.icon);

  final int id;
  final String displayName;
  final String icon;

  static GrowthStage fromId(int id) {
    return GrowthStage.values.firstWhere(
      (stage) => stage.id == id,
      orElse: () => GrowthStage.incubation,
    );
  }

  /// Get next stage in progression
  GrowthStage? get next {
    switch (this) {
      case GrowthStage.incubation:
        return GrowthStage.pinning;
      case GrowthStage.pinning:
        return GrowthStage.fruiting;
      case GrowthStage.fruiting:
        return null; // No automatic advancement from fruiting
    }
  }

  /// Parse stage from device advertising name
  /// Format: "MushPi-OysterPinning" -> GrowthStage.pinning
  static GrowthStage? fromAdvertisingName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('incub')) return GrowthStage.incubation;
    if (lowerName.contains('pin')) return GrowthStage.pinning;
    if (lowerName.contains('fruit')) return GrowthStage.fruiting;
    return null;
  }
}

/// Override bit flags for manual relay control
class OverrideBits {
  OverrideBits._();

  static const int light = 1 << 0; // Bit 0
  static const int fan = 1 << 1; // Bit 1
  static const int mist = 1 << 2; // Bit 2
  static const int heater = 1 << 3; // Bit 3
  static const int disableAuto = 1 << 7; // Bit 7
}

/// Status flag bits for system status
class StatusFlags {
  StatusFlags._();

  static const int sensorError = 1 << 0; // Bit 0
  static const int controlError = 1 << 1; // Bit 1
  static const int stageReady = 1 << 2; // Bit 2
  static const int thresholdAlarm = 1 << 3; // Bit 3
  static const int connectivity = 1 << 4; // Bit 4
  // Actuator live state bits (Option A extension of status flags)
  static const int lightOn = 1 << 5; // Bit 5 - Grow light relay ON
  static const int fanOn = 1 << 6; // Bit 6 - Fan relay ON
  static const int mistOn = 1 << 8; // Bit 8 - Humidifier/mister ON
  static const int heaterOn = 1 << 9; // Bit 9 - Heater relay ON
  static const int simulation = 1 << 7; // Bit 7
}

/// Actuator status bit flags for real-time relay states
class ActuatorBits {
  ActuatorBits._();

  static const int light = 1 << 0; // Bit 0 - Grow light relay state
  static const int fan = 1 << 1; // Bit 1 - Exhaust fan relay state
  static const int mist = 1 << 2; // Bit 2 - Humidifier/mister relay state
  static const int heater = 1 << 3; // Bit 3 - Heater relay state
}
