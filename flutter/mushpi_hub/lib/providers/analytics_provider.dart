// lib/providers/analytics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/data/repositories/analytics_repository.dart';
import 'package:mushpi_hub/data/models/farm.dart';
import 'package:mushpi_hub/data/models/threshold_profile.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'dart:developer' as developer;

/// Analytics Repository provider - manages the AnalyticsRepository instance
///
/// This provider creates and maintains a single instance of [AnalyticsRepository]
/// with database integration.
///
/// Usage:
/// ```dart
/// final analyticsRepo = ref.watch(analyticsRepositoryProvider);
/// final analytics = await analyticsRepo.calculateFarmAnalytics(...);
/// ```
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  
  developer.log(
    'Initializing AnalyticsRepository',
    name: 'mushpi.providers.analytics',
  );

  return AnalyticsRepository(database);
});

/// Farm analytics provider
///
/// Provides comprehensive analytics for a specific farm within a date range.
///
/// Usage:
/// ```dart
/// final params = FarmAnalyticsParams(
///   farmId: 'farm-123',
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
/// );
/// final analytics = ref.watch(farmAnalyticsProvider(params));
/// analytics.when(
///   data: (a) => AnalyticsView(analytics: a),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final farmAnalyticsProvider = FutureProvider.family<FarmAnalytics, FarmAnalyticsParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    
    developer.log(
      'Calculating farm analytics: ${params.farmId}',
      name: 'mushpi.providers.analytics',
    );
    
    return await repository.calculateFarmAnalytics(
      params.farmId,
      startDate: params.startDate,
      endDate: params.endDate,
      thresholds: params.thresholds,
    );
  },
);

/// Cross-farm comparison provider
///
/// Provides aggregated analytics across all active farms.
///
/// Usage:
/// ```dart
/// final params = CrossFarmParams(
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
/// );
/// final comparison = ref.watch(crossFarmComparisonProvider(params));
/// comparison.when(
///   data: (c) => CrossFarmView(comparison: c),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final crossFarmComparisonProvider = FutureProvider.family<CrossFarmComparison, CrossFarmParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    
    developer.log(
      'Generating cross-farm comparison',
      name: 'mushpi.providers.analytics',
    );
    
    return await repository.generateCrossFarmComparison(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

/// Farms ranked by yield provider
///
/// Provides farms ranked by total yield in descending order.
///
/// Usage:
/// ```dart
/// final params = RankingParams(
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
///   limit: 10,
/// );
/// final rankings = ref.watch(farmsRankedByYieldProvider(params));
/// rankings.when(
///   data: (list) => RankingList(rankings: list),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final farmsRankedByYieldProvider = FutureProvider.family<List<FarmRanking>, RankingParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    
    developer.log(
      'Ranking farms by yield',
      name: 'mushpi.providers.analytics',
    );
    
    return await repository.rankFarmsByYield(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

/// Farms ranked by compliance provider
///
/// Provides farms ranked by environmental compliance percentage.
/// Requires thresholds for compliance calculation.
///
/// Usage:
/// ```dart
/// final params = ComplianceRankingParams(
///   startDate: DateTime.now().subtract(Duration(days: 7)),
///   endDate: DateTime.now(),
///   thresholds: ControlTargets(...),
/// );
/// final rankings = ref.watch(farmsRankedByComplianceProvider(params));
/// ```
final farmsRankedByComplianceProvider = FutureProvider.family<List<FarmRanking>, ComplianceRankingParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    
    developer.log(
      'Ranking farms by compliance',
      name: 'mushpi.providers.analytics',
    );
    
    return await repository.rankFarmsByCompliance(
      startDate: params.startDate,
      endDate: params.endDate,
      thresholds: params.thresholds,
    );
  },
);

/// Analytics operations provider
///
/// Provides convenient methods for analytics operations with state management.
///
/// Usage:
/// ```dart
/// final analyticsOps = ref.read(analyticsOperationsProvider);
/// await analyticsOps.exportFarmAnalytics('farm-123', startDate, endDate);
/// ```
final analyticsOperationsProvider = Provider<AnalyticsOperations>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsOperations(repository: repository);
});

/// Analytics Operations wrapper class
///
/// Provides high-level analytics operations.
class AnalyticsOperations {
  AnalyticsOperations({required this.repository});

  final AnalyticsRepository repository;

  /// Export farm analytics to JSON
  Future<Map<String, dynamic>> exportFarmAnalytics(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      developer.log(
        'Exporting farm analytics: $farmId',
        name: 'mushpi.providers.analytics.ops',
      );

      final data = await repository.exportFarmAnalytics(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );

      developer.log(
        'Successfully exported farm analytics',
        name: 'mushpi.providers.analytics.ops',
      );

      return data;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to export farm analytics',
        name: 'mushpi.providers.analytics.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Export cross-farm comparison to JSON
  Future<Map<String, dynamic>> exportCrossFarmComparison(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      developer.log(
        'Exporting cross-farm comparison',
        name: 'mushpi.providers.analytics.ops',
      );

      final data = await repository.exportCrossFarmComparison(
        startDate: startDate,
        endDate: endDate,
      );

      developer.log(
        'Successfully exported cross-farm comparison',
        name: 'mushpi.providers.analytics.ops',
      );

      return data;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to export cross-farm comparison',
        name: 'mushpi.providers.analytics.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get top performing farms by yield
  Future<List<FarmRanking>> getTopPerformers({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final allRankings = await repository.rankFarmsByYield(
        startDate: startDate,
        endDate: endDate,
      );

      return allRankings.take(limit).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get top performers',
        name: 'mushpi.providers.analytics.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Get bottom performing farms by yield
  Future<List<FarmRanking>> getBottomPerformers({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final allRankings = await repository.rankFarmsByYield(
        startDate: startDate,
        endDate: endDate,
      );

      // Return bottom performers (reverse order, limited)
      return allRankings.reversed.take(limit).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get bottom performers',
        name: 'mushpi.providers.analytics.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Get most compliant farms
  Future<List<FarmRanking>> getMostCompliantFarms({
    required DateTime startDate,
    required DateTime endDate,
    required ControlTargets thresholds,
    int limit = 5,
  }) async {
    try {
      final allRankings = await repository.rankFarmsByCompliance(
        startDate: startDate,
        endDate: endDate,
        thresholds: thresholds,
      );

      return allRankings.take(limit).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get most compliant farms',
        name: 'mushpi.providers.analytics.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }
}

/// Parameters for farm analytics calculation
class FarmAnalyticsParams {
  const FarmAnalyticsParams({
    required this.farmId,
    required this.startDate,
    required this.endDate,
    this.thresholds,
  });

  final String farmId;
  final DateTime startDate;
  final DateTime endDate;
  final ControlTargets? thresholds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmAnalyticsParams &&
          runtimeType == other.runtimeType &&
          farmId == other.farmId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          thresholds == other.thresholds;

  @override
  int get hashCode =>
      farmId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      thresholds.hashCode;
}

/// Parameters for cross-farm comparison
class CrossFarmParams {
  const CrossFarmParams({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrossFarmParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// Parameters for farm ranking
class RankingParams {
  const RankingParams({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      startDate.hashCode ^ endDate.hashCode;
}

/// Parameters for compliance ranking (requires thresholds)
class ComplianceRankingParams {
  const ComplianceRankingParams({
    required this.startDate,
    required this.endDate,
    required this.thresholds,
  });

  final DateTime startDate;
  final DateTime endDate;
  final ControlTargets thresholds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplianceRankingParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          thresholds == other.thresholds;

  @override
  int get hashCode =>
      startDate.hashCode ^ endDate.hashCode ^ thresholds.hashCode;
}

/// Default date range provider - last 30 days
final defaultAnalyticsDateRangeProvider = Provider<DateRange>((ref) {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  
  return DateRange(start: thirtyDaysAgo, end: now);
});

/// Date range model for analytics
class DateRange {
  const DateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
  int get days => duration.inDays;
}
