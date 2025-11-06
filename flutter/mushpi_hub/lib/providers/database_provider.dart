// lib/providers/database_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/data/database/app_database.dart';
import 'dart:developer' as developer;

/// Global database provider that manages the AppDatabase singleton instance.
///
/// This provider creates and maintains a single instance of [AppDatabase]
/// throughout the app lifecycle. The database is lazily initialized on first
/// access and properly disposed when the app closes.
///
/// Usage:
/// ```dart
/// final db = ref.watch(databaseProvider);
/// final farms = await db.farmsDao.getAllFarms();
/// ```
///
/// The database instance provides access to all DAOs:
/// - farmsDao: Farm CRUD operations
/// - harvestsDao: Harvest tracking
/// - readingsDao: Environmental readings
/// - devicesDao: BLE device management
/// - settingsDao: App settings and preferences
final databaseProvider = Provider<AppDatabase>((ref) {
  developer.log(
    'Initializing AppDatabase singleton',
    name: 'mushpi.providers.database',
  );

  final database = AppDatabase();

  // Register disposal callback to close database when provider is disposed
  ref.onDispose(() {
    developer.log(
      'Disposing AppDatabase - closing database connection',
      name: 'mushpi.providers.database',
    );
    database.close();
  });

  return database;
});

/// Provider for FarmsDao - provides easy access to farm operations
///
/// Usage:
/// ```dart
/// final farmsDao = ref.watch(farmsDaoProvider);
/// final allFarms = await farmsDao.getAllFarms();
/// ```
final farmsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.farmsDao;
});

/// Provider for HarvestsDao - provides easy access to harvest operations
///
/// Usage:
/// ```dart
/// final harvestsDao = ref.watch(harvestsDaoProvider);
/// final harvests = await harvestsDao.getHarvestsByFarmId(farmId);
/// ```
final harvestsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.harvestsDao;
});

/// Provider for ReadingsDao - provides easy access to sensor readings
///
/// Usage:
/// ```dart
/// final readingsDao = ref.watch(readingsDaoProvider);
/// final latest = await readingsDao.getLatestReadingByFarm(farmId);
/// ```
final readingsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.readingsDao;
});

/// Provider for DevicesDao - provides easy access to device operations
///
/// Usage:
/// ```dart
/// final devicesDao = ref.watch(devicesDaoProvider);
/// final devices = await devicesDao.getAllDevices();
/// ```
final devicesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.devicesDao;
});

/// Provider for SettingsDao - provides easy access to app settings
///
/// Usage:
/// ```dart
/// final settingsDao = ref.watch(settingsDaoProvider);
/// final themeMode = await settingsDao.getThemeMode();
/// ```
final settingsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao;
});
