import 'dart:developer' as developer;
import 'dart:typed_data';
import '../constants/ble_constants.dart';

/// BLE Data Serialization Utilities
///
/// Handles binary packing and unpacking for all BLE GATT characteristics.
/// All data uses little-endian byte order to match the MushPi Python implementation.
class BLEDataSerializer {
  BLEDataSerializer._();

  /// Parse environmental measurements (12 bytes)
  ///
  /// Format (little-endian):
  /// - Bytes 0-1: CO₂ ppm (unsigned 16-bit)
  /// - Bytes 2-3: Temperature × 10 (signed 16-bit, divide by 10 for °C)
  /// - Bytes 4-5: Humidity × 10 (unsigned 16-bit, divide by 10 for %)
  /// - Bytes 6-7: Light raw value (unsigned 16-bit)
  /// - Bytes 8-11: Uptime milliseconds (unsigned 32-bit)
  static EnvironmentalReading parseEnvironmentalData(List<int> data) {
    if (data.length != BLEConstants.envDataSize) {
      throw ArgumentError(
        'Environmental data must be exactly ${BLEConstants.envDataSize} bytes, got ${data.length}',
      );
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));

    return EnvironmentalReading(
      co2Ppm: buffer.getUint16(0, Endian.little),
      temperatureC: buffer.getInt16(2, Endian.little) / 10.0,
      relativeHumidity: buffer.getUint16(4, Endian.little) / 10.0,
      lightRaw: buffer.getUint16(6, Endian.little),
      uptimeMs: buffer.getUint32(8, Endian.little),
      timestamp: DateTime.now(),
    );
  }

  /// Serialize control targets (15 bytes)
  ///
  /// Format (little-endian):
  /// - Bytes 0-1: Temperature min × 10 (signed 16-bit)
  /// - Bytes 2-3: Temperature max × 10 (signed 16-bit)
  /// - Bytes 4-5: Humidity min × 10 (unsigned 16-bit)
  /// - Bytes 6-7: CO₂ max ppm (unsigned 16-bit)
  /// - Byte 8: Light mode (unsigned 8-bit): 0=OFF, 1=ON, 2=CYCLE
  /// - Bytes 9-10: On minutes (unsigned 16-bit)
  /// - Bytes 11-12: Off minutes (unsigned 16-bit)
  /// - Bytes 13-14: Reserved (unsigned 16-bit, always 0)
  static List<int> serializeControlTargets(ControlTargetsData targets) {
    final buffer = ByteData(BLEConstants.controlDataSize);

    buffer.setInt16(0, (targets.tempMin * 10).round(), Endian.little);
    buffer.setInt16(2, (targets.tempMax * 10).round(), Endian.little);
    buffer.setUint16(4, (targets.rhMin * 10).round(), Endian.little);
    buffer.setUint16(6, targets.co2Max, Endian.little);
    buffer.setUint8(8, targets.lightMode.value);
    buffer.setUint16(9, targets.onMinutes, Endian.little);
    buffer.setUint16(11, targets.offMinutes, Endian.little);
    buffer.setUint16(13, 0, Endian.little); // Reserved

    return buffer.buffer.asUint8List();
  }

  /// Parse control targets (15 bytes)
  static ControlTargetsData parseControlTargets(List<int> data) {
    if (data.length != BLEConstants.controlDataSize) {
      throw ArgumentError(
        'Control targets data must be exactly ${BLEConstants.controlDataSize} bytes, got ${data.length}',
      );
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));

    return ControlTargetsData(
      tempMin: buffer.getInt16(0, Endian.little) / 10.0,
      tempMax: buffer.getInt16(2, Endian.little) / 10.0,
      rhMin: buffer.getUint16(4, Endian.little) / 10.0,
      co2Max: buffer.getUint16(6, Endian.little),
      lightMode: LightMode.fromValue(buffer.getUint8(8)),
      onMinutes: buffer.getUint16(9, Endian.little),
      offMinutes: buffer.getUint16(11, Endian.little),
    );
  }

  /// Serialize stage state (10 bytes)
  ///
  /// Format (little-endian):
  /// - Byte 0: Mode (unsigned 8-bit): 0=FULL, 1=SEMI, 2=MANUAL
  /// - Byte 1: Species ID (unsigned 8-bit): 1=Oyster, 2=Shiitake, 3=Lion's Mane, 99=Custom
  /// - Byte 2: Stage ID (unsigned 8-bit): 1=Incubation, 2=Pinning, 3=Fruiting
  /// - Bytes 3-6: Stage start timestamp (unsigned 32-bit, Unix epoch seconds)
  /// - Bytes 7-8: Expected days (unsigned 16-bit)
  /// - Byte 9: Reserved (unsigned 8-bit, always 0)
  static List<int> serializeStageState(StageStateData state) {
    final buffer = ByteData(BLEConstants.stageDataSize);

    buffer.setUint8(0, state.mode.id);
    buffer.setUint8(1, state.species.id);
    buffer.setUint8(2, state.stage.id);
    buffer.setUint32(
      3,
      state.stageStartTime.millisecondsSinceEpoch ~/ 1000,
      Endian.little,
    );
    buffer.setUint16(7, state.expectedDays, Endian.little);
    buffer.setUint8(9, 0); // Reserved

    return buffer.buffer.asUint8List();
  }

  /// Parse stage state (10 bytes)
  static StageStateData parseStageState(List<int> data) {
    if (data.length != BLEConstants.stageDataSize) {
      throw ArgumentError(
        'Stage state data must be exactly ${BLEConstants.stageDataSize} bytes, got ${data.length}',
      );
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));

    final modeId = buffer.getUint8(0);
    final speciesId = buffer.getUint8(1);
    final stageId = buffer.getUint8(2);

    developer.log(
      '📥 STAGE STATE PARSE: Raw byte[0]=$modeId (0=FULL, 1=SEMI, 2=MANUAL)',
      name: 'BLEDataSerializer.parseStageState',
    );

    final parsedMode = ControlMode.fromId(modeId);

    developer.log(
      '🔍 MODE MAPPING: modeId=$modeId → ${parsedMode.name} (displayName="${parsedMode.displayName}")',
      name: 'BLEDataSerializer.parseStageState',
    );

    return StageStateData(
      mode: parsedMode,
      species: Species.fromId(speciesId),
      stage: GrowthStage.fromId(stageId),
      stageStartTime: DateTime.fromMillisecondsSinceEpoch(
        buffer.getUint32(3, Endian.little) * 1000,
      ),
      expectedDays: buffer.getUint16(7, Endian.little),
    );
  }

  /// Serialize override bits (2 bytes)
  ///
  /// Format (little-endian):
  /// - Bytes 0-1: Override bits (unsigned 16-bit bit field)
  /// - Bit 0: LIGHT override
  /// - Bit 1: FAN override
  /// - Bit 2: MIST override
  /// - Bit 3: HEATER override
  /// - Bit 7: DISABLE_AUTO (disable all automation)
  static List<int> serializeOverrideBits(int bits) {
    final buffer = ByteData(BLEConstants.overrideDataSize);
    buffer.setUint16(0, bits, Endian.little);
    return buffer.buffer.asUint8List();
  }

  /// Parse status flags (4 bytes)
  ///
  /// Format (little-endian):
  /// - Bytes 0-3: Status flags (unsigned 32-bit bit field)
  /// - Bit 0: SENSOR_ERROR - Sensor read failure
  /// - Bit 1: CONTROL_ERROR - Control system error
  /// - Bit 2: STAGE_READY - Ready for stage advancement
  /// - Bit 3: THRESHOLD_ALARM - Environmental threshold violation
  /// - Bit 4: CONNECTIVITY - BLE connected status
  /// - Bit 5: LIGHT_ON - Grow light relay currently ON
  /// - Bit 6: FAN_ON - Fan relay currently ON
  /// - Bit 8: MIST_ON - Humidifier/mister relay ON
  /// - Bit 9: HEATER_ON - Heater relay ON
  /// - Bit 7: SIMULATION - Device in simulation mode
  static int parseStatusFlags(List<int> data) {
    // Handle invalid data gracefully - return 0x0000 (all flags disabled)
    if (data.isEmpty) {
      developer.log(
        '⚠️ Status flags: empty data received, returning default 0x0000',
        name: 'BLEDataSerializer.parseStatusFlags',
      );
      return 0x0000;
    }

    if (data.length != BLEConstants.statusDataSize) {
      developer.log(
        '⚠️ Status flags: invalid length ${data.length} bytes '
        '(expected ${BLEConstants.statusDataSize}), returning default 0x0000',
        name: 'BLEDataSerializer.parseStatusFlags',
        level: 900, // WARNING
      );
      return 0x0000;
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    return buffer.getUint32(0, Endian.little);
  }

  /// Parse actuator status (2 bytes)
  ///
  /// Real-time relay states from the control system.
  /// These reflect the ACTUAL hardware relay positions, not target states.
  ///
  /// Format (little-endian): <H4B (6 bytes total)
  /// - Bytes 0-1: Actuator status bits (unsigned 16-bit bit field)
  /// - Bit 0: LIGHT - Grow light relay ON
  /// - Bit 1: FAN - Exhaust fan relay ON
  /// - Bit 2: MIST - Humidifier/mister relay ON
  /// - Bit 3: HEATER - Heater relay ON
  /// - Byte 2: FAN reason code (0-255)
  /// - Byte 3: MIST reason code (0-255)
  /// - Byte 4: LIGHT reason code (0-255)
  /// - Byte 5: HEATER reason code (0-255)
  static ActuatorStatusData parseActuatorStatus(List<int> data) {
    // Handle invalid data gracefully - return all relays OFF
    if (data.isEmpty) {
      developer.log(
        '⚠️ Actuator status: empty data received, returning default (all OFF)',
        name: 'BLEDataSerializer.parseActuatorStatus',
      );
      return const ActuatorStatusData(
        lightOn: false,
        fanOn: false,
        mistOn: false,
        heaterOn: false,
      );
    }

    if (data.length != BLEConstants.actuatorDataSize) {
      developer.log(
        '⚠️ Actuator status: invalid length ${data.length} bytes '
        '(expected ${BLEConstants.actuatorDataSize}), returning default (all OFF)',
        name: 'BLEDataSerializer.parseActuatorStatus',
        level: 900, // WARNING
      );
      return const ActuatorStatusData(
        lightOn: false,
        fanOn: false,
        mistOn: false,
        heaterOn: false,
      );
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    final status = buffer.getUint16(0, Endian.little);

    // Extract reason codes from bytes 2-5
    final fanReasonCode = buffer.getUint8(2);
    final mistReasonCode = buffer.getUint8(3);
    final lightReasonCode = buffer.getUint8(4);
    final heaterReasonCode = buffer.getUint8(5);

    developer.log(
      '✓ Actuator status parsed: bits=0x${status.toRadixString(16).padLeft(4, '0')}, '
      'reasons=[fan:$fanReasonCode, mist:$mistReasonCode, light:$lightReasonCode, heater:$heaterReasonCode]',
      name: 'BLEDataSerializer.parseActuatorStatus',
    );

    return ActuatorStatusData(
      lightOn: (status & ActuatorBits.light) != 0,
      fanOn: (status & ActuatorBits.fan) != 0,
      mistOn: (status & ActuatorBits.mist) != 0,
      heaterOn: (status & ActuatorBits.heater) != 0,
      fanReasonCode: fanReasonCode,
      mistReasonCode: mistReasonCode,
      lightReasonCode: lightReasonCode,
      heaterReasonCode: heaterReasonCode,
    );
  }
}

/// Environmental reading data class
class EnvironmentalReading {
  final int co2Ppm;
  final double temperatureC;
  final double relativeHumidity;
  final int lightRaw;
  final int uptimeMs;
  final DateTime timestamp;

  const EnvironmentalReading({
    required this.co2Ppm,
    required this.temperatureC,
    required this.relativeHumidity,
    required this.lightRaw,
    required this.uptimeMs,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'EnvironmentalReading('
        'co2: $co2Ppm ppm, '
        'temp: ${temperatureC.toStringAsFixed(1)}°C, '
        'rh: ${relativeHumidity.toStringAsFixed(1)}%, '
        'light: $lightRaw, '
        'uptime: ${uptimeMs}ms)';
  }
}

/// Control targets data class
class ControlTargetsData {
  final double tempMin;
  final double tempMax;
  final double rhMin;
  final int co2Max;
  final LightMode lightMode;
  final int onMinutes;
  final int offMinutes;

  const ControlTargetsData({
    required this.tempMin,
    required this.tempMax,
    required this.rhMin,
    required this.co2Max,
    required this.lightMode,
    required this.onMinutes,
    required this.offMinutes,
  });

  /// Validate threshold ranges
  bool isValid() {
    return tempMin >= -20.0 &&
        tempMin < tempMax &&
        tempMax <= 60.0 &&
        rhMin >= 0.0 &&
        rhMin <= 100.0 &&
        co2Max >= 0 &&
        co2Max <= 10000 &&
        (lightMode != LightMode.cycle ||
            (onMinutes > 0 &&
                offMinutes > 0 &&
                onMinutes + offMinutes <= 1440));
  }

  @override
  String toString() {
    return 'ControlTargets('
        'temp: $tempMin-$tempMax°C, '
        'rh: $rhMin%, '
        'co2: <$co2Max ppm, '
        'light: ${lightMode.displayName}, '
        'on: ${onMinutes}min, off: ${offMinutes}min)';
  }
}

/// Actuator status data class
///
/// Real-time relay states from the control system.
/// These reflect the ACTUAL hardware relay positions reported by the Pi,
/// not target states or override settings.
class ActuatorStatusData {
  final bool lightOn;
  final bool fanOn;
  final bool mistOn;
  final bool heaterOn;
  final int fanReasonCode;
  final int mistReasonCode;
  final int lightReasonCode;
  final int heaterReasonCode;

  const ActuatorStatusData({
    required this.lightOn,
    required this.fanOn,
    required this.mistOn,
    required this.heaterOn,
    this.fanReasonCode = 0,
    this.mistReasonCode = 0,
    this.lightReasonCode = 0,
    this.heaterReasonCode = 0,
  });

  /// Count active (ON) relays
  int get activeCount {
    int count = 0;
    if (lightOn) count++;
    if (fanOn) count++;
    if (mistOn) count++;
    if (heaterOn) count++;
    return count;
  }

  /// Check if all relays are OFF
  bool get allOff => !lightOn && !fanOn && !mistOn && !heaterOn;

  /// Check if any relay is ON
  bool get anyOn => lightOn || fanOn || mistOn || heaterOn;

  @override
  String toString() {
    return 'ActuatorStatus('
        'light: ${lightOn ? "ON" : "OFF"}(reason: $lightReasonCode), '
        'fan: ${fanOn ? "ON" : "OFF"}(reason: $fanReasonCode), '
        'mist: ${mistOn ? "ON" : "OFF"}(reason: $mistReasonCode), '
        'heater: ${heaterOn ? "ON" : "OFF"}(reason: $heaterReasonCode))';
  }
}

/// Stage state data class
class StageStateData {
  final ControlMode mode;
  final Species species;
  final GrowthStage stage;
  final DateTime stageStartTime;
  final int expectedDays;

  const StageStateData({
    required this.mode,
    required this.species,
    required this.stage,
    required this.stageStartTime,
    required this.expectedDays,
  });

  /// Calculate days in current stage
  int get daysInStage {
    final now = DateTime.now();
    final difference = now.difference(stageStartTime);
    return difference.inDays;
  }

  @override
  String toString() {
    return 'StageState('
        'mode: ${mode.displayName}, '
        'species: ${species.displayName}, '
        'stage: ${stage.displayName}, '
        'day: $daysInStage/$expectedDays)';
  }
}

/// Stage thresholds data class
///
/// Represents threshold configuration for a specific species/stage combination.
/// JSON format for BLE communication with stage_thresholds characteristic.
class StageThresholdsData {
  final Species species;
  final GrowthStage stage;
  final double? tempMin;
  final double? tempMax;
  final double? rhMin;
  final double? rhMax;
  final int? co2Max;
  final LightMode? lightMode;
  final int? lightOnMinutes;
  final int? lightOffMinutes;
  final int? expectedDays;
  final String? startTime; // ISO 8601 timestamp when this stage started

  const StageThresholdsData({
    required this.species,
    required this.stage,
    this.tempMin,
    this.tempMax,
    this.rhMin,
    this.rhMax,
    this.co2Max,
    this.lightMode,
    this.lightOnMinutes,
    this.lightOffMinutes,
    this.expectedDays,
    this.startTime,
  });

  /// Create from JSON (BLE read response)
  factory StageThresholdsData.fromJson(Map<String, dynamic> json) {
    // Parse species
    final speciesStr = json['species'] as String?;
    final species = Species.values.firstWhere(
      (s) => s.displayName.toLowerCase() == speciesStr?.toLowerCase(),
      orElse: () => Species.oyster,
    );

    // Parse stage
    final stageStr = json['stage'] as String?;
    final stage = GrowthStage.values.firstWhere(
      (s) => s.displayName.toLowerCase() == stageStr?.toLowerCase(),
      orElse: () => GrowthStage.incubation,
    );

    // Parse light settings
    LightMode? lightMode;
    int? lightOnMinutes;
    int? lightOffMinutes;
    if (json.containsKey('light') && json['light'] is Map) {
      final lightData = json['light'] as Map<String, dynamic>;
      final modeStr = lightData['mode'] as String?;
      if (modeStr != null) {
        lightMode = LightMode.values.firstWhere(
          (m) => m.displayName.toLowerCase() == modeStr.toLowerCase(),
          orElse: () => LightMode.off,
        );
      }
      // Handle num type from JSON (can be int or double from database)
      lightOnMinutes = (lightData['on_min'] as num?)?.toInt();
      lightOffMinutes = (lightData['off_min'] as num?)?.toInt();
    }

    return StageThresholdsData(
      species: species,
      stage: stage,
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      tempMax: (json['temp_max'] as num?)?.toDouble(),
      rhMin: (json['rh_min'] as num?)?.toDouble(),
      rhMax: (json['rh_max'] as num?)?.toDouble(),
      // Handle num type from JSON (can be int or double from database)
      co2Max: (json['co2_max'] as num?)?.toInt(),
      lightMode: lightMode,
      lightOnMinutes: lightOnMinutes,
      lightOffMinutes: lightOffMinutes,
      expectedDays: (json['expected_days'] as num?)?.toInt(),
      startTime: json['start_time'] as String?,
    );
  }

  /// Convert to JSON (BLE write request)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'species': species.displayName,
      'stage': stage.displayName,
    };

    if (tempMin != null) json['temp_min'] = tempMin;
    if (tempMax != null) json['temp_max'] = tempMax;
    if (rhMin != null) json['rh_min'] = rhMin;
    if (rhMax != null) json['rh_max'] = rhMax;
    if (co2Max != null) json['co2_max'] = co2Max;
    if (expectedDays != null) json['expected_days'] = expectedDays;
    if (startTime != null) json['start_time'] = startTime;

    if (lightMode != null ||
        lightOnMinutes != null ||
        lightOffMinutes != null) {
      json['light'] = <String, dynamic>{};
      if (lightMode != null) {
        json['light']['mode'] = lightMode!.displayName.toLowerCase();
      }
      if (lightOnMinutes != null) json['light']['on_min'] = lightOnMinutes;
      if (lightOffMinutes != null) json['light']['off_min'] = lightOffMinutes;
    }

    return json;
  }

  /// Create query request (species + stage only, for reading)
  Map<String, dynamic> toQueryJson() {
    return {
      'species': species.displayName,
      'stage': stage.displayName,
    };
  }

  /// Validate threshold ranges
  bool isValid() {
    if (tempMin != null && tempMax != null && tempMin! >= tempMax!) {
      return false;
    }
    if (tempMin != null && (tempMin! < -20.0 || tempMin! > 60.0)) return false;
    if (tempMax != null && (tempMax! < -20.0 || tempMax! > 60.0)) return false;
    if (rhMin != null && (rhMin! < 0.0 || rhMin! > 100.0)) return false;
    if (rhMax != null && (rhMax! < 0.0 || rhMax! > 100.0)) return false;
    if (co2Max != null && (co2Max! < 0 || co2Max! > 10000)) return false;
    if (lightMode == LightMode.cycle) {
      if (lightOnMinutes == null ||
          lightOffMinutes == null ||
          lightOnMinutes! <= 0 ||
          lightOffMinutes! <= 0) {
        return false;
      }
    }
    if (expectedDays != null && (expectedDays! < 0 || expectedDays! > 365)) {
      return false;
    }
    return true;
  }

  /// Create a copy with updated fields
  StageThresholdsData copyWith({
    Species? species,
    GrowthStage? stage,
    double? tempMin,
    double? tempMax,
    double? rhMin,
    double? rhMax,
    int? co2Max,
    LightMode? lightMode,
    int? lightOnMinutes,
    int? lightOffMinutes,
    int? expectedDays,
  }) {
    return StageThresholdsData(
      species: species ?? this.species,
      stage: stage ?? this.stage,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      rhMin: rhMin ?? this.rhMin,
      rhMax: rhMax ?? this.rhMax,
      co2Max: co2Max ?? this.co2Max,
      lightMode: lightMode ?? this.lightMode,
      lightOnMinutes: lightOnMinutes ?? this.lightOnMinutes,
      lightOffMinutes: lightOffMinutes ?? this.lightOffMinutes,
      expectedDays: expectedDays ?? this.expectedDays,
    );
  }

  @override
  String toString() {
    return 'StageThresholds('
        'species: ${species.displayName}, '
        'stage: ${stage.displayName}, '
        'temp: ${tempMin ?? "??"}-${tempMax ?? "??"}°C, '
        'rh: ${rhMin ?? "??"}${rhMax != null ? "-$rhMax" : "+"}%, '
        'co2: <${co2Max ?? "??"}ppm, '
        'light: ${lightMode?.displayName ?? "??"}${lightMode == LightMode.cycle ? " (${lightOnMinutes ?? 0}m/${lightOffMinutes ?? 0}m)" : ""}, '
        'days: ${expectedDays ?? "??"})';
  }
}
