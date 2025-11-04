import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/ble_constants.dart';

part 'threshold_profile.freezed.dart';
part 'threshold_profile.g.dart';

/// Threshold profile for a specific growth stage
@freezed
class ThresholdProfile with _$ThresholdProfile {
  const factory ThresholdProfile({
    required double tempMin, // Celsius
    required double tempMax, // Celsius
    required double rhMin, // Percentage (0-100)
    required int co2Max, // PPM
    required LightMode lightMode, // OFF, ON, CYCLE
    @Default(0) int onMinutes, // For CYCLE mode
    @Default(0) int offMinutes, // For CYCLE mode
    @Default(0) int expectedDays, // Stage duration
    String? notes, // Optional user notes
  }) = _ThresholdProfile;

  factory ThresholdProfile.fromJson(Map<String, dynamic> json) =>
      _$ThresholdProfileFromJson(json);
}

/// Farm-specific thresholds for all growth stages
@freezed
class FarmThresholds with _$FarmThresholds {
  const factory FarmThresholds({
    required String farmId,
    required Species species,
    required Map<GrowthStage, ThresholdProfile> profiles,
    DateTime? lastModified,
    @Default(false) bool? isCustom, // True if user modified from defaults
  }) = _FarmThresholds;

  factory FarmThresholds.fromJson(Map<String, dynamic> json) =>
      _$FarmThresholdsFromJson(json);
}

/// Environmental data reading
@freezed
class EnvironmentalData with _$EnvironmentalData {
  const factory EnvironmentalData({
    required int co2Ppm,
    required double temperatureC,
    required double relativeHumidity,
    required int lightRaw,
    required DateTime timestamp,
  }) = _EnvironmentalData;

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalDataFromJson(json);
}

/// Control targets for environmental management
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

/// Stage state information
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

/// Connection status enumeration
enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}
