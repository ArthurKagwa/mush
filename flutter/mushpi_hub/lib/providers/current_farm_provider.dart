// lib/providers/current_farm_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/data/models/farm.dart';
import 'package:mushpi_hub/core/constants/ble_constants.dart';
import 'package:mushpi_hub/data/repositories/farm_repository.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'package:mushpi_hub/providers/farms_provider.dart';
import 'dart:developer' as developer;
import 'dart:async';

/// Selected farm ID for monitoring screen
///
/// Manages which farm is selected for viewing in the monitoring screen.
/// This is separate from the detail view selection and is not persisted.
///
/// Usage:
/// ```dart
/// final farmId = ref.watch(selectedMonitoringFarmIdProvider);
/// 
/// // To select a farm for monitoring:
/// ref.read(selectedMonitoringFarmIdProvider.notifier).state = 'farm-123';
/// ```
final selectedMonitoringFarmIdProvider = StateProvider<String?>((ref) => null);

/// Latest reading for selected monitoring farm provider
///
/// Provides the most recent environmental reading for the farm selected in monitoring screen.
///
/// Usage:
/// ```dart
/// final reading = ref.watch(selectedMonitoringFarmLatestReadingProvider);
/// reading.when(
///   data: (r) => r != null ? Text('Temp: ${r.temperatureC}°C') : null,
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final selectedMonitoringFarmLatestReadingProvider =
    FutureProvider<EnvironmentalReading?>((ref) async {
  final farmId = ref.watch(selectedMonitoringFarmIdProvider);
  
  if (farmId == null) {
    return null;
  }

  final readingsDao = ref.watch(readingsDaoProvider);
  
  try {
    final reading = await readingsDao.getLatestReadingByFarm(farmId);
    
    if (reading == null) {
      return null;
    }

    return EnvironmentalReading(
      co2Ppm: reading.co2Ppm,
      temperatureC: reading.temperatureC,
      relativeHumidity: reading.relativeHumidity,
      lightRaw: reading.lightRaw,
      timestamp: reading.timestamp,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get latest reading for monitoring',
      name: 'mushpi.providers.current_farm',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    return null;
  }
});

/// Current selected farm ID provider
///
/// Manages which farm is currently selected/active in the UI.
/// Persisted to settings database for restoration on app restart.
///
/// Usage:
/// ```dart
/// final farmId = ref.watch(currentFarmIdProvider);
/// if (farmId != null) {
///   // Farm is selected
/// }
/// 
/// // To select a farm:
/// ref.read(currentFarmIdProvider.notifier).selectFarm('farm-123');
/// ```
final currentFarmIdProvider =
    StateNotifierProvider<CurrentFarmIdNotifier, String?>((ref) {
  final settingsDao = ref.watch(settingsDaoProvider);
  return CurrentFarmIdNotifier(settingsDao);
});

/// Notifier for current farm ID state management
class CurrentFarmIdNotifier extends StateNotifier<String?> {
  CurrentFarmIdNotifier(this._settingsDao) : super(null) {
    _init();
  }

  final dynamic _settingsDao; // SettingsDao

  Future<void> _init() async {
    try {
      // Load last selected farm from settings
      final lastFarmId = await _settingsDao.getLastSelectedFarmId();
      
      if (lastFarmId != null) {
        developer.log(
          'Restored last selected farm: $lastFarmId',
          name: 'mushpi.providers.current_farm',
        );
        state = lastFarmId;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load last selected farm',
        name: 'mushpi.providers.current_farm',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Select a farm by ID
  Future<void> selectFarm(String? farmId) async {
    try {
      developer.log(
        'Selecting farm: $farmId',
        name: 'mushpi.providers.current_farm',
      );

      state = farmId;

      // Persist to settings
      if (farmId != null) {
        await _settingsDao.setLastSelectedFarmId(farmId);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to select farm',
        name: 'mushpi.providers.current_farm',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Clear current farm selection
  Future<void> clearSelection() async {
    await selectFarm(null);
  }
}

/// Current selected farm provider
///
/// Provides the full Farm object for the currently selected farm.
/// Returns null if no farm is selected or farm not found.
///
/// Usage:
/// ```dart
/// final farm = ref.watch(currentFarmProvider);
/// farm.when(
///   data: (f) => f != null ? Text(f.name) : Text('No farm selected'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentFarmProvider = FutureProvider<Farm?>((ref) async {
  final farmId = ref.watch(currentFarmIdProvider);
  
  developer.log(
    '🔍 [currentFarmProvider] Current farm ID: ${farmId ?? "null"}',
    name: 'mushpi.providers.current_farm',
  );
  
  if (farmId == null) {
    developer.log(
      '⚠️ [currentFarmProvider] No farm selected, returning null',
      name: 'mushpi.providers.current_farm',
    );
    return null;
  }

  try {
    // Watch the specific farm by ID
    final farm = await ref.watch(farmByIdProvider(farmId).future);
    
    if (farm != null) {
      developer.log(
        '✅ [currentFarmProvider] Loaded farm: ${farm.name} (ID: ${farm.id})',
        name: 'mushpi.providers.current_farm',
      );
    } else {
      developer.log(
        '⚠️ [currentFarmProvider] Farm not found: $farmId',
        name: 'mushpi.providers.current_farm',
        level: 900,
      );
    }
    
    return farm;
  } catch (error, stackTrace) {
    developer.log(
      '❌ [currentFarmProvider] Error loading farm $farmId',
      name: 'mushpi.providers.current_farm',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    rethrow;
  }
});

/// Current farm stats provider
///
/// Provides statistics for the currently selected farm.
///
/// Usage:
/// ```dart
/// final stats = ref.watch(currentFarmStatsProvider);
/// stats.when(
///   data: (s) => s != null ? Text('Yield/day: ${s.yieldPerDay}') : null,
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentFarmStatsProvider = FutureProvider<FarmStats?>((ref) async {
  final farmId = ref.watch(currentFarmIdProvider);
  
  if (farmId == null) {
    return null;
  }

  return await ref.watch(farmStatsProvider(farmId).future);
});

/// Current farm harvests provider
///
/// Provides all harvests for the currently selected farm.
///
/// Usage:
/// ```dart
/// final harvests = ref.watch(currentFarmHarvestsProvider);
/// harvests.when(
///   data: (list) => ListView(children: list.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentFarmHarvestsProvider =
    FutureProvider<List<HarvestRecord>>((ref) async {
  final farmId = ref.watch(currentFarmIdProvider);
  
  if (farmId == null) {
    return [];
  }

  return await ref.watch(harvestsForFarmProvider(farmId).future);
});

/// Latest reading for current farm provider
///
/// Provides the most recent environmental reading for the currently selected farm.
///
/// Usage:
/// ```dart
/// final reading = ref.watch(currentFarmLatestReadingProvider);
/// reading.when(
///   data: (r) => r != null ? Text('Temp: ${r.temperatureC}°C') : null,
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentFarmLatestReadingProvider =
    FutureProvider<EnvironmentalReading?>((ref) async {
  final farmId = ref.watch(currentFarmIdProvider);
  
  if (farmId == null) {
    return null;
  }

  final readingsDao = ref.watch(readingsDaoProvider);
  
  try {
    final reading = await readingsDao.getLatestReadingByFarm(farmId);
    
    if (reading == null) {
      return null;
    }

    return EnvironmentalReading(
      co2Ppm: reading.co2Ppm,
      temperatureC: reading.temperatureC,
      relativeHumidity: reading.relativeHumidity,
      lightRaw: reading.lightRaw,
      timestamp: reading.timestamp,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get latest reading',
      name: 'mushpi.providers.current_farm',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    return null;
  }
});

/// Recent readings for current farm provider
///
/// Provides the most recent N environmental readings for the currently selected farm.
///
/// Usage:
/// ```dart
/// final readings = ref.watch(currentFarmRecentReadingsProvider(24));
/// readings.when(
///   data: (list) => Chart(data: list),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final currentFarmRecentReadingsProvider =
    FutureProvider.family<List<EnvironmentalReading>, int>((ref, limit) async {
  final farmId = ref.watch(currentFarmIdProvider);
  
  if (farmId == null) {
    return [];
  }

  final readingsDao = ref.watch(readingsDaoProvider);
  
  try {
    final readings = await readingsDao.getRecentReadingsByFarm(farmId, limit);
    
    return readings.map((r) => EnvironmentalReading(
      co2Ppm: r.co2Ppm,
      temperatureC: r.temperatureC,
      relativeHumidity: r.relativeHumidity,
      lightRaw: r.lightRaw,
      timestamp: r.timestamp,
    )).toList();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get recent readings',
      name: 'mushpi.providers.current_farm',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    return [];
  }
});

/// Environmental reading model for UI
class EnvironmentalReading {
  const EnvironmentalReading({
    required this.co2Ppm,
    required this.temperatureC,
    required this.relativeHumidity,
    required this.lightRaw,
    required this.timestamp,
  });

  final int co2Ppm;
  final double temperatureC;
  final double relativeHumidity;
  final int lightRaw;
  final DateTime timestamp;
}

/// Current farm auto-refresh provider
///
/// Manages automatic data refresh for the current farm.
/// Periodically refetches farm data, stats, and readings.
///
/// Usage:
/// ```dart
/// // Start auto-refresh (e.g., when farm detail screen is shown)
/// ref.read(currentFarmAutoRefreshProvider.notifier).start();
/// 
/// // Stop auto-refresh (e.g., when screen is hidden)
/// ref.read(currentFarmAutoRefreshProvider.notifier).stop();
/// ```
final currentFarmAutoRefreshProvider =
    StateNotifierProvider<CurrentFarmAutoRefreshNotifier, bool>((ref) {
  return CurrentFarmAutoRefreshNotifier(ref);
});

/// Notifier for auto-refresh management
class CurrentFarmAutoRefreshNotifier extends StateNotifier<bool> {
  CurrentFarmAutoRefreshNotifier(this._ref) : super(false);

  final Ref _ref;
  Timer? _timer;
  static const _refreshInterval = Duration(seconds: 30);

  /// Start auto-refresh
  void start() {
    if (state) {
      developer.log(
        'Auto-refresh already running',
        name: 'mushpi.providers.current_farm.refresh',
      );
      return;
    }

    developer.log(
      'Starting auto-refresh (interval: ${_refreshInterval.inSeconds}s)',
      name: 'mushpi.providers.current_farm.refresh',
    );

    state = true;
    
    _timer = Timer.periodic(_refreshInterval, (_) {
      _refresh();
    });
  }

  /// Stop auto-refresh
  void stop() {
    if (!state) {
      return;
    }

    developer.log(
      'Stopping auto-refresh',
      name: 'mushpi.providers.current_farm.refresh',
    );

    state = false;
    _timer?.cancel();
    _timer = null;
  }

  void _refresh() {
    final farmId = _ref.read(currentFarmIdProvider);
    
    if (farmId == null) {
      developer.log(
        'No farm selected, stopping auto-refresh',
        name: 'mushpi.providers.current_farm.refresh',
      );
      stop();
      return;
    }

    developer.log(
      'Auto-refreshing farm data: $farmId',
      name: 'mushpi.providers.current_farm.refresh',
    );

    // Invalidate providers to trigger refresh
    _ref.invalidate(currentFarmProvider);
    _ref.invalidate(currentFarmStatsProvider);
    _ref.invalidate(currentFarmLatestReadingProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Current farm operations provider
///
/// Provides convenient methods for operations on the currently selected farm.
///
/// Usage:
/// ```dart
/// final ops = ref.read(currentFarmOperationsProvider);
/// await ops.recordHarvest(yieldKg: 2.5, species: Species.oyster);
/// ```
final currentFarmOperationsProvider =
    Provider<CurrentFarmOperations>((ref) {
  final farmOps = ref.watch(farmOperationsProvider);
  final currentFarmId = ref.watch(currentFarmIdProvider);
  
  return CurrentFarmOperations(
    farmOperations: farmOps,
    currentFarmId: currentFarmId,
  );
});

/// Operations wrapper for current farm
class CurrentFarmOperations {
  CurrentFarmOperations({
    required this.farmOperations,
    required this.currentFarmId,
  });

  final FarmOperations farmOperations;
  final String? currentFarmId;

  /// Record a harvest for the current farm
  Future<String?> recordHarvest({
    required String id,
    required DateTime harvestDate,
    required Species species,
    required GrowthStage stage,
    required double yieldKg,
    int? flushNumber,
    double? qualityScore,
    String? notes,
    List<String>? photoUrls,
  }) async {
    if (currentFarmId == null) {
      developer.log(
        'No farm selected, cannot record harvest',
        name: 'mushpi.providers.current_farm.ops',
        level: 900,
      );
      return null;
    }

    return await farmOperations.recordHarvest(
      id: id,
      farmId: currentFarmId!,
      harvestDate: harvestDate,
      species: species,
      stage: stage,
      yieldKg: yieldKg,
      flushNumber: flushNumber,
      qualityScore: qualityScore,
      notes: notes,
      photoUrls: photoUrls,
    );
  }

  /// Update current farm details
  Future<void> updateFarm({
    String? name,
    String? location,
    String? notes,
    Species? primarySpecies,
    String? imageUrl,
  }) async {
    if (currentFarmId == null) {
      developer.log(
        'No farm selected, cannot update',
        name: 'mushpi.providers.current_farm.ops',
        level: 900,
      );
      return;
    }

    await farmOperations.updateFarm(
      id: currentFarmId!,
      name: name,
      location: location,
      notes: notes,
      primarySpecies: primarySpecies,
      imageUrl: imageUrl,
    );
  }

  /// Archive current farm
  Future<void> archiveCurrentFarm() async {
    if (currentFarmId == null) {
      return;
    }

    await farmOperations.archiveFarm(currentFarmId!);
  }

  /// Delete current farm
  Future<void> deleteCurrentFarm() async {
    if (currentFarmId == null) {
      return;
    }

    await farmOperations.deleteFarm(currentFarmId!);
  }
}
