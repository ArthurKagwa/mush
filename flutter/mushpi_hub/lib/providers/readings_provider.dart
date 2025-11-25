// lib/providers/readings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/data/database/app_database.dart';
import 'package:mushpi_hub/data/repositories/thingspeak_repository.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'package:mushpi_hub/providers/current_farm_provider.dart';
import 'dart:developer' as developer;

/// Provider for fetching readings from the last 24 hours for the selected farm.
///
/// Automatically watches the selected monitoring farm and fetches readings
/// from the past 24 hours. Returns an empty list if no farm is selected
/// or if an error occurs.
///
/// Usage:
/// ```dart
/// final readingsAsync = ref.watch(last24HoursReadingsProvider);
/// readingsAsync.when(
///   data: (readings) => ChartWidget(readings: readings),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
/// );
/// ```
final last24HoursReadingsProvider = FutureProvider<List<Reading>>((ref) async {
  final readingsDao = ref.watch(readingsDaoProvider);
  final selectedFarmId = ref.watch(selectedMonitoringFarmIdProvider);

  if (selectedFarmId == null) {
    developer.log(
      'No farm selected - returning empty readings list',
      name: 'mushpi.providers.readings',
    );
    return [];
  }

  try {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    developer.log(
      'Fetching readings for farm $selectedFarmId from last 24 hours (local DB)',
      name: 'mushpi.providers.readings',
    );

    final localReadings = await readingsDao.getReadingsByFarmAndPeriod(
      selectedFarmId,
      twentyFourHoursAgo,
      now,
    );

    developer.log(
      'Fetched ${localReadings.length} readings from local DB for last 24 hours',
      name: 'mushpi.providers.readings',
    );

    // Attempt to backfill gaps from ThingSpeak if configured.
    // If integration is disabled or fails, we simply return local readings.
    final tsRepo = ThingSpeakRepository();

    if (!tsRepo.isEnabled) {
      return localReadings;
    }

    developer.log(
      'Attempting ThingSpeak backfill for farm $selectedFarmId (last 24 hours)',
      name: 'mushpi.providers.readings',
    );

    final remoteReadings = await tsRepo.fetchReadingsForPeriod(
      farmId: selectedFarmId,
      start: twentyFourHoursAgo,
      end: now,
    );

    // If no remote data available, return local only (which may be empty)
    if (remoteReadings.isEmpty) {
      developer.log(
        'No ThingSpeak readings available for backfill',
        name: 'mushpi.providers.readings',
      );
      return localReadings;
    }

    // Special case: if no local data exists (e.g., away from device),
    // return remote data directly to show ThingSpeak-only readings.
    if (localReadings.isEmpty) {
      developer.log(
        'No local readings - returning ThingSpeak-only data (${remoteReadings.length} readings)',
        name: 'mushpi.providers.readings',
      );
      return remoteReadings;
    }

    // Merge remote readings only where local data appears to have gaps.
    // A remote point is kept if there is no local reading within +/- 2.5 minutes.
    final merged = <Reading>[];
    merged.addAll(localReadings);

    for (final remote in remoteReadings) {
      final hasNearbyLocal = localReadings.any((local) {
        final diff = local.timestamp.difference(remote.timestamp).abs();
        return diff <= const Duration(minutes: 2, seconds: 30);
      });

      if (!hasNearbyLocal) {
        merged.add(remote);
      }
    }

    // Sort by timestamp ascending for chart rendering
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    developer.log(
      'After ThingSpeak backfill, total readings: ${merged.length} '
      '(local: ${localReadings.length}, remote used: ${merged.length - localReadings.length})',
      name: 'mushpi.providers.readings',
    );

    return merged;
  } catch (e, stackTrace) {
    developer.log(
      'Error fetching 24-hour readings (with ThingSpeak backfill)',
      name: 'mushpi.providers.readings',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
    return [];
  }
});

/// Provider for fetching readings from a custom time period for a specific farm.
///
/// Supports ThingSpeak backfill similar to last24HoursReadingsProvider.
///
/// Usage:
/// ```dart
/// final readingsAsync = ref.watch(
///   readingsByPeriodProvider((farmId: 'farm123', start: startDate, end: endDate))
/// );
/// ```
final readingsByPeriodProvider = FutureProvider.family<
    List<Reading>,
    ({String farmId, DateTime start, DateTime end})>((ref, params) async {
  final readingsDao = ref.watch(readingsDaoProvider);

  try {
    developer.log(
      'Fetching readings for farm ${params.farmId} from ${params.start} to ${params.end}',
      name: 'mushpi.providers.readings',
    );

    final localReadings = await readingsDao.getReadingsByFarmAndPeriod(
      params.farmId,
      params.start,
      params.end,
    );

    developer.log(
      'Fetched ${localReadings.length} readings from local DB for custom period',
      name: 'mushpi.providers.readings',
    );

    // Attempt to backfill gaps from ThingSpeak if configured.
    final tsRepo = ThingSpeakRepository();

    if (!tsRepo.isEnabled) {
      return localReadings;
    }

    developer.log(
      'Attempting ThingSpeak backfill for farm ${params.farmId} (custom period)',
      name: 'mushpi.providers.readings',
    );

    final remoteReadings = await tsRepo.fetchReadingsForPeriod(
      farmId: params.farmId,
      start: params.start,
      end: params.end,
    );

    if (remoteReadings.isEmpty) {
      developer.log(
        'No ThingSpeak readings available for backfill',
        name: 'mushpi.providers.readings',
      );
      return localReadings;
    }

    // Special case: if no local data exists, return remote data directly
    if (localReadings.isEmpty) {
      developer.log(
        'No local readings - returning ThingSpeak-only data (${remoteReadings.length} readings)',
        name: 'mushpi.providers.readings',
      );
      return remoteReadings;
    }

    // Merge remote readings only where local data appears to have gaps.
    // A remote point is kept if there is no local reading within +/- 2.5 minutes.
    final merged = <Reading>[];
    merged.addAll(localReadings);

    for (final remote in remoteReadings) {
      final hasNearbyLocal = localReadings.any((local) {
        final diff = local.timestamp.difference(remote.timestamp).abs();
        return diff <= const Duration(minutes: 2, seconds: 30);
      });

      if (!hasNearbyLocal) {
        merged.add(remote);
      }
    }

    // Sort by timestamp ascending for chart rendering
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    developer.log(
      'After ThingSpeak backfill, total readings: ${merged.length} '
      '(local: ${localReadings.length}, remote used: ${merged.length - localReadings.length})',
      name: 'mushpi.providers.readings',
    );

    return merged;
  } catch (e, stackTrace) {
    developer.log(
      'Error fetching readings for custom period',
      name: 'mushpi.providers.readings',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
    return [];
  }
});

/// Provider for fetching recent readings for a farm (limited count).
///
/// Useful for showing a preview or summary without loading all historical data.
///
/// Usage:
/// ```dart
/// final readingsAsync = ref.watch(
///   recentReadingsProvider((farmId: 'farm123', limit: 100))
/// );
/// ```
final recentReadingsProvider = FutureProvider.family<
    List<Reading>,
    ({String farmId, int limit})>((ref, params) async {
  final readingsDao = ref.watch(readingsDaoProvider);

  try {
    developer.log(
      'Fetching ${params.limit} recent readings for farm ${params.farmId}',
      name: 'mushpi.providers.readings',
    );

    final readings = await readingsDao.getRecentReadingsByFarm(
      params.farmId,
      params.limit,
    );

    developer.log(
      'Fetched ${readings.length} recent readings',
      name: 'mushpi.providers.readings',
    );

    return readings;
  } catch (e, stackTrace) {
    developer.log(
      'Error fetching recent readings',
      name: 'mushpi.providers.readings',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
    rethrow;
  }
});
