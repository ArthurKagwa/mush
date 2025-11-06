import 'dart:developer' as developer;
import '../database/app_database.dart';
import '../models/farm.dart' as models;
import '../models/threshold_profile.dart';
import '../../core/constants/ble_constants.dart';

/// Analytics Repository for Farm Performance and Cross-Farm Analysis
///
/// Handles all analytics operations including:
/// - Farm environmental compliance calculations
/// - Production metrics and yield analysis
/// - Cross-farm performance comparisons
/// - Performance rankings
/// - Analytics data export
/// - Uptime and system health tracking
class AnalyticsRepository {
  final AppDatabase _database;

  AnalyticsRepository(this._database);

  // ========================
  // FARM ANALYTICS
  // ========================

  /// Calculate comprehensive analytics for a single farm
  Future<models.FarmAnalytics> calculateFarmAnalytics(
    String farmId, {
    required DateTime startDate,
    required DateTime endDate,
    ControlTargets? thresholds,
  }) async {
    try {
      developer.log(
        'Calculating analytics for farm $farmId (${startDate.toIso8601String()} - ${endDate.toIso8601String()})',
        name: 'AnalyticsRepository',
      );

      final farm = await _database.farmsDao.getFarmById(farmId);
      if (farm == null) {
        throw AnalyticsException('Farm not found: $farmId');
      }

      // Get environmental readings for period
      final readings = await _database.readingsDao
          .getReadingsByFarmAndPeriod(farmId, startDate, endDate);

      // Get harvests for period
      final harvests = await _database.harvestsDao
          .getHarvestsByFarmAndPeriod(farmId, startDate, endDate);

      // Calculate environmental metrics
      final envMetrics = _calculateEnvironmentalMetrics(readings);

      // Calculate compliance percentages
      final compliance = thresholds != null
          ? _calculateCompliance(readings, thresholds)
          : ComplianceMetrics.zero();

      // Calculate production metrics
      final production = _calculateProductionMetrics(
        harvests,
        farm.createdAt,
        endDate,
      );

      // Calculate stage tracking
      final stageTracking = await _calculateStageTracking(farmId);

      // Calculate system health
      final systemHealth = _calculateSystemHealth(readings, farm.lastActive);

      return models.FarmAnalytics(
        farmId: farmId,
        farmName: farm.name,
        // Environmental performance
        avgTemperature: envMetrics.avgTemperature,
        avgHumidity: envMetrics.avgHumidity,
        avgCO2: envMetrics.avgCO2,
        tempCompliancePercent: compliance.temperatureCompliance,
        humidityCompliancePercent: compliance.humidityCompliance,
        co2CompliancePercent: compliance.co2Compliance,
        // Production metrics
        harvestCount: production.harvestCount,
        totalYieldKg: production.totalYieldKg,
        avgYieldPerHarvest: production.avgYieldPerHarvest,
        daysInProduction: production.daysInProduction,
        yieldPerDay: production.yieldPerDay,
        // Stage tracking
        currentStage: stageTracking.currentStage,
        daysInCurrentStage: stageTracking.daysInCurrentStage,
        stageTransitions: stageTracking.stageTransitions,
        // System health
        totalAlerts: systemHealth.totalAlerts,
        criticalAlerts: systemHealth.criticalAlerts,
        uptimePercent: systemHealth.uptimePercent,
        lastConnection: farm.lastActive,
        // Time period
        periodStart: startDate,
        periodEnd: endDate,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to calculate farm analytics',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // CROSS-FARM COMPARISON
  // ========================

  /// Generate cross-farm comparison analytics
  Future<models.CrossFarmComparison> generateCrossFarmComparison({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      developer.log(
        'Generating cross-farm comparison',
        name: 'AnalyticsRepository',
      );

      // Get all active farms
      final farms = await _database.farmsDao.getActiveFarms();

      if (farms.isEmpty) {
        throw AnalyticsException('No active farms found');
      }

      // Calculate analytics for each farm
      final List<models.FarmAnalytics> farmAnalyticsList = [];
      for (final farm in farms) {
        final analytics = await calculateFarmAnalytics(
          farm.id,
          startDate: startDate,
          endDate: endDate,
        );
        farmAnalyticsList.add(analytics);
      }

      // Calculate averages
      final averages = _calculateAverages(farmAnalyticsList);

      // Find top and bottom performers
      final topPerformer = _findTopPerformer(farmAnalyticsList);
      final bottomPerformer = _findBottomPerformer(farmAnalyticsList);

      // Calculate species breakdown
      final speciesBreakdown = _calculateSpeciesBreakdown(farms);

      // Calculate stage distribution
      final stageDistribution = _calculateStageDistribution(farmAnalyticsList);

      return models.CrossFarmComparison(
        farms: farmAnalyticsList,
        averages: averages,
        topPerformer: topPerformer,
        bottomPerformer: bottomPerformer,
        speciesBreakdown: speciesBreakdown,
        stageDistribution: stageDistribution,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to generate cross-farm comparison',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // PERFORMANCE RANKINGS
  // ========================

  /// Rank farms by yield performance
  Future<List<FarmRanking>> rankFarmsByYield({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final farms = await _database.farmsDao.getActiveFarms();
      final rankings = <FarmRanking>[];

      for (final farm in farms) {
        final harvests = await _database.harvestsDao
            .getHarvestsByFarmAndPeriod(farm.id, startDate, endDate);

        final totalYield = harvests.fold<double>(
          0.0,
          (sum, harvest) => sum + harvest.yieldKg,
        );

        rankings.add(FarmRanking(
          farmId: farm.id,
          farmName: farm.name,
          value: totalYield,
          metric: 'Total Yield (kg)',
        ));
      }

      // Sort by yield descending
      rankings.sort((a, b) => b.value.compareTo(a.value));

      // Assign ranks
      for (var i = 0; i < rankings.length; i++) {
        rankings[i] = rankings[i].copyWith(rank: i + 1);
      }

      return rankings;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to rank farms by yield',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Rank farms by compliance
  Future<List<FarmRanking>> rankFarmsByCompliance({
    required DateTime startDate,
    required DateTime endDate,
    required ControlTargets thresholds,
  }) async {
    try {
      final farms = await _database.farmsDao.getActiveFarms();
      final rankings = <FarmRanking>[];

      for (final farm in farms) {
        final readings = await _database.readingsDao
            .getReadingsByFarmAndPeriod(farm.id, startDate, endDate);

        final compliance = _calculateCompliance(readings, thresholds);
        final avgCompliance = (compliance.temperatureCompliance +
                compliance.humidityCompliance +
                compliance.co2Compliance) /
            3;

        rankings.add(FarmRanking(
          farmId: farm.id,
          farmName: farm.name,
          value: avgCompliance,
          metric: 'Average Compliance (%)',
        ));
      }

      // Sort by compliance descending
      rankings.sort((a, b) => b.value.compareTo(a.value));

      // Assign ranks
      for (var i = 0; i < rankings.length; i++) {
        rankings[i] = rankings[i].copyWith(rank: i + 1);
      }

      return rankings;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to rank farms by compliance',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // EXPORT ANALYTICS
  // ========================

  /// Export farm analytics data for external use
  Future<Map<String, dynamic>> exportFarmAnalytics(
    String farmId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final analytics = await calculateFarmAnalytics(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );

      return analytics.toJson();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to export farm analytics',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Export cross-farm comparison data
  Future<Map<String, dynamic>> exportCrossFarmComparison({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final comparison = await generateCrossFarmComparison(
        startDate: startDate,
        endDate: endDate,
      );

      return comparison.toJson();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to export cross-farm comparison',
        name: 'AnalyticsRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // HELPER METHODS
  // ========================

  /// Calculate environmental metrics from readings
  EnvironmentalMetrics _calculateEnvironmentalMetrics(List<Reading> readings) {
    if (readings.isEmpty) {
      return EnvironmentalMetrics.zero();
    }

    final avgTemp = readings.fold<double>(
            0.0, (sum, r) => sum + r.temperatureC) /
        readings.length;

    final avgHumidity = readings.fold<double>(
            0.0, (sum, r) => sum + r.relativeHumidity) /
        readings.length;

    final avgCO2 =
        readings.fold<double>(0.0, (sum, r) => sum + r.co2Ppm) /
            readings.length;

    return EnvironmentalMetrics(
      avgTemperature: avgTemp,
      avgHumidity: avgHumidity,
      avgCO2: avgCO2,
    );
  }

  /// Calculate compliance percentages
  ComplianceMetrics _calculateCompliance(
    List<Reading> readings,
    ControlTargets thresholds,
  ) {
    if (readings.isEmpty) {
      return ComplianceMetrics.zero();
    }

    int tempCompliant = 0;
    int humidityCompliant = 0;
    int co2Compliant = 0;

    for (final reading in readings) {
      // Temperature compliance
      if (reading.temperatureC >= thresholds.tempMin &&
          reading.temperatureC <= thresholds.tempMax) {
        tempCompliant++;
      }

      // Humidity compliance
      if (reading.relativeHumidity >= thresholds.rhMin) {
        humidityCompliant++;
      }

      // CO2 compliance
      if (reading.co2Ppm <= thresholds.co2Max) {
        co2Compliant++;
      }
    }

    final totalReadings = readings.length;
    return ComplianceMetrics(
      temperatureCompliance: (tempCompliant / totalReadings) * 100,
      humidityCompliance: (humidityCompliant / totalReadings) * 100,
      co2Compliance: (co2Compliant / totalReadings) * 100,
    );
  }

  /// Calculate production metrics
  ProductionMetrics _calculateProductionMetrics(
    List<Harvest> harvests,
    DateTime farmCreatedAt,
    DateTime endDate,
  ) {
    final harvestCount = harvests.length;
    final totalYieldKg =
        harvests.fold<double>(0.0, (sum, h) => sum + h.yieldKg);
    final avgYieldPerHarvest = harvestCount > 0 ? totalYieldKg / harvestCount : 0.0;
    
    final daysInProduction = endDate.difference(farmCreatedAt).inDays;
    final yieldPerDay = daysInProduction > 0 ? totalYieldKg / daysInProduction : 0.0;

    return ProductionMetrics(
      harvestCount: harvestCount,
      totalYieldKg: totalYieldKg,
      avgYieldPerHarvest: avgYieldPerHarvest,
      daysInProduction: daysInProduction,
      yieldPerDay: yieldPerDay,
    );
  }

  /// Calculate stage tracking metrics
  Future<StageTrackingMetrics> _calculateStageTracking(String farmId) async {
    // In a real implementation, this would query stage state from database
    // For now, return placeholder data
    return StageTrackingMetrics(
      currentStage: null,
      daysInCurrentStage: 0,
      stageTransitions: 0,
    );
  }

  /// Calculate system health metrics
  SystemHealthMetrics _calculateSystemHealth(
    List<Reading> readings,
    DateTime? lastConnection,
  ) {
    // Calculate expected readings (every 5 minutes for the period)
    if (readings.isEmpty) {
      return SystemHealthMetrics(
        totalAlerts: 0,
        criticalAlerts: 0,
        uptimePercent: 0.0,
      );
    }

    final firstReading = readings.first.timestamp;
    final lastReading = readings.last.timestamp;
    final periodDuration = lastReading.difference(firstReading);
    final expectedReadings = (periodDuration.inMinutes / 5).ceil();

    final uptimePercent = expectedReadings > 0
        ? (readings.length / expectedReadings) * 100
        : 0.0;

    // TODO: Calculate actual alerts from readings
    return SystemHealthMetrics(
      totalAlerts: 0,
      criticalAlerts: 0,
      uptimePercent: uptimePercent.clamp(0.0, 100.0),
    );
  }

  /// Calculate averages across all farms
  models.FarmAnalytics _calculateAverages(List<models.FarmAnalytics> farmAnalyticsList) {
    if (farmAnalyticsList.isEmpty) {
      throw AnalyticsException('No farm analytics to calculate averages from');
    }

    final count = farmAnalyticsList.length;

    return models.FarmAnalytics(
      farmId: 'average',
      farmName: 'Average',
      avgTemperature: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.avgTemperature) /
          count,
      avgHumidity:
          farmAnalyticsList.fold<double>(0.0, (sum, f) => sum + f.avgHumidity) /
              count,
      avgCO2: farmAnalyticsList.fold<double>(0.0, (sum, f) => sum + f.avgCO2) /
          count,
      tempCompliancePercent: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.tempCompliancePercent) /
          count,
      humidityCompliancePercent: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.humidityCompliancePercent) /
          count,
      co2CompliancePercent: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.co2CompliancePercent) /
          count,
      harvestCount: (farmAnalyticsList.fold<int>(
              0, (sum, f) => sum + f.harvestCount) /
          count).round(),
      totalYieldKg: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.totalYieldKg) /
          count,
      avgYieldPerHarvest: farmAnalyticsList.fold<double>(
              0.0, (sum, f) => sum + f.avgYieldPerHarvest) /
          count,
      daysInProduction: (farmAnalyticsList.fold<int>(
              0, (sum, f) => sum + f.daysInProduction) /
          count).round(),
      yieldPerDay:
          farmAnalyticsList.fold<double>(0.0, (sum, f) => sum + f.yieldPerDay) /
              count,
      currentStage: null,
      daysInCurrentStage: 0,
      stageTransitions: 0,
      totalAlerts: 0,
      criticalAlerts: 0,
      uptimePercent:
          farmAnalyticsList.fold<double>(0.0, (sum, f) => sum + f.uptimePercent) /
              count,
      lastConnection: null,
      periodStart: farmAnalyticsList.first.periodStart,
      periodEnd: farmAnalyticsList.first.periodEnd,
    );
  }

  /// Find top performing farm by yield
  models.FarmAnalytics _findTopPerformer(List<models.FarmAnalytics> farmAnalyticsList) {
    return farmAnalyticsList.reduce(
      (current, next) =>
          current.totalYieldKg > next.totalYieldKg ? current : next,
    );
  }

  /// Find bottom performing farm by yield
  models.FarmAnalytics _findBottomPerformer(List<models.FarmAnalytics> farmAnalyticsList) {
    return farmAnalyticsList.reduce(
      (current, next) =>
          current.totalYieldKg < next.totalYieldKg ? current : next,
    );
  }

  /// Calculate species breakdown
  Map<String, double> _calculateSpeciesBreakdown(List<Farm> farms) {
    final speciesCount = <String, int>{};

    for (final farm in farms) {
      if (farm.primarySpecies != null) {
        final speciesName = Species.fromId(farm.primarySpecies!).name;
        speciesCount[speciesName] = (speciesCount[speciesName] ?? 0) + 1;
      }
    }

    final total = farms.length;
    return speciesCount.map(
      (species, count) => MapEntry(species, (count / total) * 100),
    );
  }

  /// Calculate stage distribution
  Map<String, int> _calculateStageDistribution(
    List<models.FarmAnalytics> farmAnalyticsList,
  ) {
    final stageCount = <String, int>{};

    for (final farm in farmAnalyticsList) {
      if (farm.currentStage != null) {
        final stageName = farm.currentStage!.name;
        stageCount[stageName] = (stageCount[stageName] ?? 0) + 1;
      }
    }

    return stageCount;
  }
}

// ========================
// HELPER CLASSES
// ========================

/// Environmental metrics
class EnvironmentalMetrics {
  final double avgTemperature;
  final double avgHumidity;
  final double avgCO2;

  EnvironmentalMetrics({
    required this.avgTemperature,
    required this.avgHumidity,
    required this.avgCO2,
  });

  factory EnvironmentalMetrics.zero() {
    return EnvironmentalMetrics(
      avgTemperature: 0.0,
      avgHumidity: 0.0,
      avgCO2: 0.0,
    );
  }
}

/// Compliance metrics
class ComplianceMetrics {
  final double temperatureCompliance;
  final double humidityCompliance;
  final double co2Compliance;

  ComplianceMetrics({
    required this.temperatureCompliance,
    required this.humidityCompliance,
    required this.co2Compliance,
  });

  factory ComplianceMetrics.zero() {
    return ComplianceMetrics(
      temperatureCompliance: 0.0,
      humidityCompliance: 0.0,
      co2Compliance: 0.0,
    );
  }
}

/// Production metrics
class ProductionMetrics {
  final int harvestCount;
  final double totalYieldKg;
  final double avgYieldPerHarvest;
  final int daysInProduction;
  final double yieldPerDay;

  ProductionMetrics({
    required this.harvestCount,
    required this.totalYieldKg,
    required this.avgYieldPerHarvest,
    required this.daysInProduction,
    required this.yieldPerDay,
  });
}

/// Stage tracking metrics
class StageTrackingMetrics {
  final GrowthStage? currentStage;
  final int daysInCurrentStage;
  final int stageTransitions;

  StageTrackingMetrics({
    required this.currentStage,
    required this.daysInCurrentStage,
    required this.stageTransitions,
  });
}

/// System health metrics
class SystemHealthMetrics {
  final int totalAlerts;
  final int criticalAlerts;
  final double uptimePercent;

  SystemHealthMetrics({
    required this.totalAlerts,
    required this.criticalAlerts,
    required this.uptimePercent,
  });
}

/// Farm ranking
class FarmRanking {
  final int? rank;
  final String farmId;
  final String farmName;
  final double value;
  final String metric;

  FarmRanking({
    this.rank,
    required this.farmId,
    required this.farmName,
    required this.value,
    required this.metric,
  });

  FarmRanking copyWith({
    int? rank,
    String? farmId,
    String? farmName,
    double? value,
    String? metric,
  }) {
    return FarmRanking(
      rank: rank ?? this.rank,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      value: value ?? this.value,
      metric: metric ?? this.metric,
    );
  }
}

/// Analytics exception
class AnalyticsException implements Exception {
  final String message;

  AnalyticsException(this.message);

  @override
  String toString() => 'AnalyticsException: $message';
}
