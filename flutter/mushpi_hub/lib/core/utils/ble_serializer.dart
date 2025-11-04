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

    return StageStateData(
      mode: ControlMode.fromId(buffer.getUint8(0)),
      species: Species.fromId(buffer.getUint8(1)),
      stage: GrowthStage.fromId(buffer.getUint8(2)),
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
  /// - Bit 7: SIMULATION - Device in simulation mode
  static int parseStatusFlags(List<int> data) {
    if (data.length != BLEConstants.statusDataSize) {
      throw ArgumentError(
        'Status flags data must be exactly ${BLEConstants.statusDataSize} bytes, got ${data.length}',
      );
    }

    final buffer = ByteData.sublistView(Uint8List.fromList(data));
    return buffer.getUint32(0, Endian.little);
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
