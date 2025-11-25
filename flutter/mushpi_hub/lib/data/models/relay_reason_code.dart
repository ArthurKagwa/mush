/// Relay reason codes for BLE transmission
///
/// Mirrors the Python RelayReasonCode IntEnum from mushpi/app/core/control.py
/// Each code is 1 byte (0-255) for efficient BLE transmission.
///
/// These codes are packed in the actuator_status characteristic (6 bytes total):
/// - Bytes 0-1: Status bits (u16)
/// - Byte 2: Fan reason code
/// - Byte 3: Mist reason code
/// - Byte 4: Light reason code
/// - Byte 5: Heater reason code
enum RelayReasonCode {
  // System States (0-9)
  unknown(0, 'Unknown state'),
  systemStartup(1, 'System initializing'),
  manualOverride(2, 'Manual control active'),
  condensationGuardActive(3, 'Condensation prevention active'),

  // Temperature Control (10-29)
  tempTooHigh(10, 'Temperature too high, cooling'),
  tempNormalHigh(11, 'Temperature normalized, cooling stopped'),
  tempTooLow(12, 'Temperature too low, heating'),
  tempNormalLow(13, 'Temperature normalized, heating stopped'),
  tempHysteresisZone(14, 'Temperature in hysteresis zone'),
  tempCoolingLimitReached(15, 'Cooling duty cycle limit'),
  tempHeatingLimitReached(16, 'Heating duty cycle limit'),

  // Humidity Control (30-49)
  humidityTooLow(30, 'Humidity too low, misting'),
  humidityNormal(31, 'Humidity normalized, misting stopped'),
  humidityHysteresisZone(32, 'Humidity in hysteresis zone'),
  humidityTooHigh(33, 'Humidity too high'),
  humidityDutyCycleLimit(34, 'Mist duty cycle limit'),

  // CO2 Control (50-69)
  co2TooHigh(50, 'CO2 too high, ventilating'),
  co2Normal(51, 'CO2 levels normal, ventilation stopped'),
  co2HysteresisZone(52, 'CO2 in hysteresis zone'),
  co2VentilationLimit(53, 'Ventilation duty cycle limit'),

  // Light Control (70-89)
  lightScheduleOn(70, 'Light on per schedule'),
  lightScheduleOff(71, 'Light off per schedule'),
  lightAlwaysOn(72, 'Light always on mode'),
  lightAlwaysOff(73, 'Light always off mode'),
  lightVerificationFailed(74, 'Light verification failed'),

  // Duty Cycle Limits (90-109)
  dutyLimitReached(90, 'Duty cycle limit reached'),
  dutyCooldownActive(91, 'Duty cycle cooldown active'),
  dutyTrackerReset(92, 'Duty cycle tracker reset'),

  // Safety/Error States (110-129)
  sensorReadingInvalid(110, 'Invalid sensor reading'),
  controllerDisabled(111, 'Controller disabled'),
  gpioWriteFailed(112, 'GPIO write failed'),
  bleConnectionLost(113, 'BLE connection lost'),
  configurationError(114, 'Configuration error'),

  // Manual Control (130-149)
  manualOn(130, 'Manually turned on'),
  manualOff(131, 'Manually turned off'),
  appControl(132, 'App control override'),

  // Stage Transitions (150-169)
  stageTransition(150, 'Growth stage transition'),
  thresholdsUpdated(151, 'Control thresholds updated');

  const RelayReasonCode(this.code, this.description);

  final int code;
  final String description;

  /// Get reason code from integer value
  static RelayReasonCode fromCode(int code) {
    return RelayReasonCode.values.firstWhere(
      (reason) => reason.code == code,
      orElse: () => RelayReasonCode.unknown,
    );
  }

  /// Get category of the reason code
  String get category {
    if (code < 10) return 'System';
    if (code < 30) return 'Temperature';
    if (code < 50) return 'Humidity';
    if (code < 70) return 'CO2';
    if (code < 90) return 'Light';
    if (code < 110) return 'Duty Cycle';
    if (code < 130) return 'Safety';
    if (code < 150) return 'Manual';
    if (code < 170) return 'Stage';
    return 'Unknown';
  }

  /// Check if this is an error/warning state
  bool get isWarning {
    return code >= 90 && code < 130; // Duty cycle limits and safety/errors
  }

  /// Get a short display string (for compact UI)
  String get shortDisplay {
    switch (this) {
      // Temperature
      case RelayReasonCode.tempTooHigh:
        return 'Cooling';
      case RelayReasonCode.tempNormalHigh:
        return 'Temp OK';
      case RelayReasonCode.tempTooLow:
        return 'Heating';
      case RelayReasonCode.tempNormalLow:
        return 'Temp OK';

      // Humidity
      case RelayReasonCode.humidityTooLow:
        return 'Misting';
      case RelayReasonCode.humidityNormal:
        return 'Humidity OK';

      // CO2
      case RelayReasonCode.co2TooHigh:
        return 'Ventilating';
      case RelayReasonCode.co2Normal:
        return 'CO2 OK';

      // Light
      case RelayReasonCode.lightScheduleOn:
        return 'Schedule On';
      case RelayReasonCode.lightScheduleOff:
        return 'Schedule Off';
      case RelayReasonCode.lightAlwaysOn:
        return 'Always On';
      case RelayReasonCode.lightAlwaysOff:
        return 'Always Off';

      // Condensation
      case RelayReasonCode.condensationGuardActive:
        return 'Anti-Condensation';

      // Manual
      case RelayReasonCode.manualOn:
      case RelayReasonCode.manualOff:
      case RelayReasonCode.appControl:
        return 'Manual';

      // Defaults
      case RelayReasonCode.systemStartup:
        return 'Starting...';
      default:
        return category;
    }
  }
}

/// Extension to get display colors for reason codes
extension RelayReasonCodeColors on RelayReasonCode {
  /// Get appropriate color for this reason code
  /// Returns color value as 0xAARRGGBB
  int get displayColor {
    if (isWarning) {
      return 0xFFFFA726; // Orange for warnings
    }

    switch (category) {
      case 'Temperature':
        return code == 10
            ? 0xFF42A5F5
            : 0xFF66BB6A; // Blue for cooling, green for normal
      case 'Humidity':
        return code == 30
            ? 0xFF29B6F6
            : 0xFF66BB6A; // Cyan for misting, green for normal
      case 'CO2':
        return code == 50
            ? 0xFF7E57C2
            : 0xFF66BB6A; // Purple for ventilating, green for normal
      case 'Light':
        return 0xFFFFEE58; // Yellow for light states
      case 'Manual':
        return 0xFF78909C; // Grey for manual control
      default:
        return 0xFF9E9E9E; // Default grey
    }
  }
}
