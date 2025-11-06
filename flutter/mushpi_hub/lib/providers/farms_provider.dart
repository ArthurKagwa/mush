// lib/providers/farms_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/data/repositories/farm_repository.dart';
import 'package:mushpi_hub/data/models/farm.dart';
import 'package:mushpi_hub/core/constants/ble_constants.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'dart:developer' as developer;

/// Farm Repository provider - manages the FarmRepository instance
///
/// This provider creates and maintains a single instance of [FarmRepository]
/// with database integration.
///
/// Usage:
/// ```dart
/// final farmRepo = ref.watch(farmRepositoryProvider);
/// await farmRepo.createFarm(...);
/// ```
final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  final database = ref.watch(databaseProvider);
  
  developer.log(
    'Initializing FarmRepository',
    name: 'mushpi.providers.farms',
  );

  return FarmRepository(database);
});

/// All farms list provider
///
/// Provides a reactive list of all farms (active and archived).
/// Automatically refetches when farms are modified.
///
/// Usage:
/// ```dart
/// final farmsAsync = ref.watch(allFarmsProvider);
/// farmsAsync.when(
///   data: (farms) => ListView(children: farms.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final allFarmsProvider = FutureProvider<List<Farm>>((ref) async {
  final repository = ref.watch(farmRepositoryProvider);
  
  developer.log(
    'Fetching all farms',
    name: 'mushpi.providers.farms',
  );
  
  return await repository.getAllFarms();
});

/// Active farms list provider
///
/// Provides a reactive list of active farms only (excludes archived).
///
/// Usage:
/// ```dart
/// final activeFarms = ref.watch(activeFarmsProvider);
/// activeFarms.when(
///   data: (farms) => Text('Active farms: ${farms.length}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final activeFarmsProvider = FutureProvider<List<Farm>>((ref) async {
  final repository = ref.watch(farmRepositoryProvider);
  
  developer.log(
    'Fetching active farms',
    name: 'mushpi.providers.farms',
  );
  
  return await repository.getActiveFarms();
});

/// Archived farms list provider
///
/// Provides a reactive list of archived farms only.
///
/// Usage:
/// ```dart
/// final archivedFarms = ref.watch(archivedFarmsProvider);
/// ```
final archivedFarmsProvider = FutureProvider<List<Farm>>((ref) async {
  final allFarms = await ref.watch(allFarmsProvider.future);
  
  // Filter for archived farms (isActive = false)
  return allFarms.where((farm) => !farm.isActive).toList();
});

/// Single farm provider by ID
///
/// Provides a specific farm by its ID.
///
/// Usage:
/// ```dart
/// final farm = ref.watch(farmByIdProvider('farm-123'));
/// farm.when(
///   data: (f) => f != null ? Text(f.name) : Text('Not found'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final farmByIdProvider = FutureProvider.family<Farm?, String>((ref, farmId) async {
  final repository = ref.watch(farmRepositoryProvider);
  
  developer.log(
    '🔍 [farmByIdProvider] Fetching farm by ID: $farmId',
    name: 'mushpi.providers.farms',
  );
  
  try {
    final farm = await repository.getFarmById(farmId);
    
    if (farm != null) {
      developer.log(
        '✅ [farmByIdProvider] Found farm: ${farm.name} (ID: ${farm.id}, Device: ${farm.deviceId})',
        name: 'mushpi.providers.farms',
      );
    } else {
      developer.log(
        '⚠️ [farmByIdProvider] Farm not found in database: $farmId',
        name: 'mushpi.providers.farms',
        level: 900,
      );
      
      // Debug: Log all farms to help diagnose
      final allFarms = await repository.getAllFarms();
      developer.log(
        '📊 [farmByIdProvider] Total farms in database: ${allFarms.length}',
        name: 'mushpi.providers.farms',
      );
      for (final f in allFarms) {
        developer.log(
          '  - Farm: ${f.name} (ID: ${f.id})',
          name: 'mushpi.providers.farms',
        );
      }
    }
    
    return farm;
  } catch (error, stackTrace) {
    developer.log(
      '❌ [farmByIdProvider] Error fetching farm $farmId',
      name: 'mushpi.providers.farms',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    rethrow;
  }
});

/// Farm by device ID provider
///
/// Finds a farm associated with a specific BLE device ID.
///
/// Usage:
/// ```dart
/// final farm = ref.watch(farmByDeviceIdProvider('AA:BB:CC:DD:EE:FF'));
/// ```
final farmByDeviceIdProvider = FutureProvider.family<Farm?, String>((ref, deviceId) async {
  final repository = ref.watch(farmRepositoryProvider);
  
  developer.log(
    'Fetching farm by device ID: $deviceId',
    name: 'mushpi.providers.farms',
  );
  
  return await repository.getFarmByDeviceId(deviceId);
});

/// Farm operations provider - provides methods for farm operations
///
/// This provider offers convenient methods for common farm operations:
/// - Create, update, delete farms
/// - Archive/restore farms
/// - Record harvests
/// - Link devices
/// - Update production metrics
///
/// Usage:
/// ```dart
/// final farmOps = ref.read(farmOperationsProvider);
/// await farmOps.createFarm(name: 'My Farm', ...);
/// ```
final farmOperationsProvider = Provider<FarmOperations>((ref) {
  final repository = ref.watch(farmRepositoryProvider);
  return FarmOperations(repository: repository, ref: ref);
});

/// Farm Operations wrapper class
///
/// Provides high-level farm operations with automatic state refresh.
class FarmOperations {
  FarmOperations({
    required this.repository,
    required this.ref,
  });

  final FarmRepository repository;
  final Ref ref;

  /// Create a new farm
  ///
  /// Creates a new farm and refreshes the farms list.
  Future<String> createFarm({
    required String id,
    required String name,
    required String deviceId,
    String? location,
    String? notes,
    Species? primarySpecies,
    String? imageUrl,
  }) async {
    try {
      developer.log(
        '🏗️ [FarmOperations] Creating farm...\n'
        '  Name: $name\n'
        '  ID: $id\n'
        '  Device: $deviceId\n'
        '  Species: ${primarySpecies?.displayName ?? "None"}\n'
        '  Location: ${location ?? "None"}',
        name: 'mushpi.providers.farms.ops',
      );

      final farmId = await repository.createFarm(
        id: id,
        name: name,
        deviceId: deviceId,
        location: location,
        notes: notes,
        primarySpecies: primarySpecies,
        imageUrl: imageUrl,
      );

      // Refresh farms list
      developer.log(
        '🔄 [FarmOperations] Refreshing farm providers after creation',
        name: 'mushpi.providers.farms.ops',
      );
      _refreshFarms();

      developer.log(
        '✅ [FarmOperations] Successfully created farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      // Verify farm was created by fetching it
      final createdFarm = await repository.getFarmById(farmId);
      if (createdFarm != null) {
        developer.log(
          '✅ [FarmOperations] Verified farm exists in database: ${createdFarm.name}',
          name: 'mushpi.providers.farms.ops',
        );
      } else {
        developer.log(
          '⚠️ [FarmOperations] Warning: Farm created but not found in database!',
          name: 'mushpi.providers.farms.ops',
          level: 900,
        );
      }

      return farmId;
    } catch (error, stackTrace) {
      developer.log(
        '❌ [FarmOperations] Failed to create farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Update an existing farm
  Future<void> updateFarm({
    required String id,
    String? name,
    String? location,
    String? notes,
    Species? primarySpecies,
    String? imageUrl,
  }) async {
    try {
      developer.log(
        'Updating farm: $id',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.updateFarm(
        id: id,
        name: name,
        location: location,
        notes: notes,
        primarySpecies: primarySpecies,
        imageUrl: imageUrl,
      );

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully updated farm: $id',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to update farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Delete a farm
  Future<void> deleteFarm(String farmId) async {
    try {
      developer.log(
        'Deleting farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.deleteFarm(farmId);

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully deleted farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Archive a farm (soft delete)
  Future<void> archiveFarm(String farmId) async {
    try {
      developer.log(
        'Archiving farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.archiveFarm(farmId);

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully archived farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to archive farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Restore an archived farm
  Future<void> restoreFarm(String farmId) async {
    try {
      developer.log(
        'Restoring farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.restoreFarm(farmId);

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully restored farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to restore farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Link a device to a farm
  Future<void> linkDeviceToFarm(String farmId, String deviceId) async {
    try {
      developer.log(
        'Linking device $deviceId to farm $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.linkDeviceToFarm(farmId, deviceId);

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully linked device to farm',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to link device to farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Update farm's last active timestamp
  Future<void> updateLastActive(String farmId) async {
    try {
      await repository.updateLastActive(farmId);

      // Refresh farms list
      _refreshFarms();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to update last active',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Record a harvest for a farm
  Future<String> recordHarvest({
    required String id,
    required String farmId,
    required DateTime harvestDate,
    required Species species,
    required GrowthStage stage,
    required double yieldKg,
    int? flushNumber,
    double? qualityScore,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      developer.log(
        'Recording harvest for farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      final harvestId = await repository.recordHarvest(
        id: id,
        farmId: farmId,
        harvestDate: harvestDate,
        species: species,
        stage: stage,
        yieldKg: yieldKg,
        flushNumber: flushNumber,
        qualityScore: qualityScore,
        notes: notes,
        photoUrls: photoUrls,
      );

      // Refresh farms list to update production metrics
      _refreshFarms();

      developer.log(
        'Successfully recorded harvest: $harvestId',
        name: 'mushpi.providers.farms.ops',
      );

      return harvestId;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to record harvest',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get harvests for a farm
  Future<List<HarvestRecord>> getHarvestsForFarm(String farmId) async {
    try {
      return await repository.getHarvestsForFarm(farmId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get harvests for farm',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Get harvests for a specific time period
  Future<List<HarvestRecord>> getHarvestsForPeriod({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await repository.getHarvestsForPeriod(
        farmId,
        startDate,
        endDate,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get harvests for period',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Get farm statistics
  Future<FarmStats?> getFarmStats(String farmId) async {
    try {
      return await repository.getFarmStats(farmId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get farm stats',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Recalculate production metrics for a farm
  Future<void> recalculateProductionMetrics(String farmId) async {
    try {
      developer.log(
        'Recalculating production metrics for farm: $farmId',
        name: 'mushpi.providers.farms.ops',
      );

      await repository.recalculateProductionMetrics(farmId);

      // Refresh farms list
      _refreshFarms();

      developer.log(
        'Successfully recalculated production metrics',
        name: 'mushpi.providers.farms.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to recalculate production metrics',
        name: 'mushpi.providers.farms.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Refresh all farm providers
  void _refreshFarms() {
    ref.invalidate(allFarmsProvider);
    ref.invalidate(activeFarmsProvider);
    ref.invalidate(archivedFarmsProvider);
  }
}

/// Harvests for farm provider
///
/// Provides all harvests for a specific farm.
///
/// Usage:
/// ```dart
/// final harvests = ref.watch(harvestsForFarmProvider('farm-123'));
/// harvests.when(
///   data: (list) => ListView(children: list.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final harvestsForFarmProvider = FutureProvider.family<List<HarvestRecord>, String>(
  (ref, farmId) async {
    final farmOps = ref.watch(farmOperationsProvider);
    return await farmOps.getHarvestsForFarm(farmId);
  },
);

/// Farm stats provider
///
/// Provides statistics for a specific farm including days active,
/// current conditions, and yield per day.
///
/// Usage:
/// ```dart
/// final stats = ref.watch(farmStatsProvider('farm-123'));
/// stats.when(
///   data: (s) => s != null ? Text('Yield/day: ${s.yieldPerDay}') : Text('N/A'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final farmStatsProvider = FutureProvider.family<FarmStats?, String>(
  (ref, farmId) async {
    final farmOps = ref.watch(farmOperationsProvider);
    return await farmOps.getFarmStats(farmId);
  },
);
