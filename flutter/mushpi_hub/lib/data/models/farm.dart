import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/ble_constants.dart';

part 'farm.freezed.dart';
part 'farm.g.dart';

/// Farm entity representing a mushroom cultivation farm
@freezed
class Farm with _$Farm {
  const factory Farm({
    required String id, // Unique farm ID (UUID)
    required String name, // User-defined name
    required String deviceId, // Linked MushPi device ID (one-to-one)
    String? location, // Optional location
    String? notes, // Farm notes/description
    required DateTime createdAt, // Farm creation date
    DateTime? lastActive, // Last time device connected
    @Default(0) int totalHarvests, // Total number of harvests
    @Default(0.0) double totalYieldKg, // Total yield in kilograms
    Species? primarySpecies, // Primary mushroom species grown
    String? imageUrl, // Farm photo (local path)
    @Default(true) bool isActive, // Farm status (active/archived)
    Map<String, dynamic>? metadata, // Additional metadata
  }) = _Farm;

  factory Farm.fromJson(Map<String, dynamic> json) => _$FarmFromJson(json);
}

/// Farm analytics data
@freezed
class FarmAnalytics with _$FarmAnalytics {
  const factory FarmAnalytics({
    required String farmId,
    required String farmName,
    
    // Environmental performance
    required double avgTemperature,
    required double avgHumidity,
    required double avgCO2,
    required double tempCompliancePercent,
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

/// Harvest record for production tracking
@freezed
class HarvestRecord with _$HarvestRecord {
  const factory HarvestRecord({
    required String id,
    required String farmId,
    required DateTime harvestDate,
    required Species species,
    required GrowthStage stage,
    required double yieldKg,
    int? flushNumber, // Which flush (1st, 2nd, etc.)
    double? qualityScore, // 0-10 quality rating
    String? notes,
    List<String>? photoUrls, // Harvest photos
    Map<String, dynamic>? metadata,
  }) = _HarvestRecord;

  factory HarvestRecord.fromJson(Map<String, dynamic> json) =>
      _$HarvestRecordFromJson(json);
}

/// Cross-farm comparison data
@freezed
class CrossFarmComparison with _$CrossFarmComparison {
  const factory CrossFarmComparison({
    required List<FarmAnalytics> farms,
    required FarmAnalytics averages,
    required FarmAnalytics topPerformer,
    required FarmAnalytics bottomPerformer,
    required Map<String, double> speciesBreakdown,
    required Map<String, int> stageDistribution,
  }) = _CrossFarmComparison;

  factory CrossFarmComparison.fromJson(Map<String, dynamic> json) =>
      _$CrossFarmComparisonFromJson(json);
}

/// Device information
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String deviceId,
    required String name,
    required String address,
    String? farmId,
    DateTime? lastConnected,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}
