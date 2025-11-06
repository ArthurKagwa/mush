import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/farm.dart' as models;
import '../../core/constants/ble_constants.dart';

/// Farm Repository for Farm and Harvest Management
///
/// Handles all farm-related operations including:
/// - CRUD operations for farms
/// - Device linking and farm-device relationships
/// - Production metrics tracking
/// - Harvest record management
/// - Farm statistics and calculations
/// - Archive/restore functionality
class FarmRepository {
  final AppDatabase _database;

  FarmRepository(this._database);

  // ========================
  // FARM CRUD OPERATIONS
  // ========================

  /// Get all farms (active and archived)
  Future<List<models.Farm>> getAllFarms() async {
    try {
      final farms = await _database.farmsDao.getAllFarms();
      return farms.map(_farmFromDrift).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get all farms',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get active farms only
  Future<List<models.Farm>> getActiveFarms() async {
    try {
      final farms = await _database.farmsDao.getActiveFarms();
      return farms.map(_farmFromDrift).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get active farms',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get farm by ID
  Future<models.Farm?> getFarmById(String id) async {
    try {
      final farm = await _database.farmsDao.getFarmById(id);
      return farm != null ? _farmFromDrift(farm) : null;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get farm by ID: $id',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get farm by device ID
  Future<models.Farm?> getFarmByDeviceId(String deviceId) async {
    try {
      final farm = await _database.farmsDao.getFarmByDeviceId(deviceId);
      return farm != null ? _farmFromDrift(farm) : null;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get farm by device ID: $deviceId',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Create a new farm
  Future<String> createFarm({
    required String id,
    required String name,
    required String deviceId,
    String? location,
    String? notes,
    Species? primarySpecies,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final companion = FarmsCompanion(
        id: Value(id),
        name: Value(name),
        deviceId: Value(deviceId),
        location: Value(location),
        notes: Value(notes),
        createdAt: Value(DateTime.now()),
        lastActive: Value(DateTime.now()),
        totalHarvests: const Value(0),
        totalYieldKg: const Value(0.0),
        primarySpecies: Value(primarySpecies?.id),
        imageUrl: Value(imageUrl),
        isActive: const Value(true),
        metadata: Value(metadata != null ? _encodeMetadata(metadata) : null),
      );

      await _database.farmsDao.insertFarm(companion);

      developer.log(
        'Farm created: $name (ID: $id, Device: $deviceId)',
        name: 'FarmRepository',
      );

      return id;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to create farm: $name',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Update farm details
  Future<void> updateFarm({
    required String id,
    String? name,
    String? location,
    String? notes,
    Species? primarySpecies,
    String? imageUrl,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final companion = FarmsCompanion(
        id: Value(id),
        name: name != null ? Value(name) : const Value.absent(),
        location: location != null ? Value(location) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        primarySpecies: primarySpecies != null
            ? Value(primarySpecies.id)
            : const Value.absent(),
        imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        metadata: metadata != null
            ? Value(_encodeMetadata(metadata))
            : const Value.absent(),
      );

      await _database.farmsDao.updateFarm(companion);

      developer.log(
        'Farm updated: $id',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update farm: $id',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Delete a farm
  Future<void> deleteFarm(String id) async {
    try {
      await _database.farmsDao.deleteFarm(id);

      developer.log(
        'Farm deleted: $id',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete farm: $id',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // DEVICE MANAGEMENT
  // ========================

  /// Link device to farm
  Future<void> linkDeviceToFarm(String farmId, String deviceId) async {
    try {
      await _database.farmsDao.linkDeviceToFarm(farmId, deviceId);

      developer.log(
        'Device $deviceId linked to farm $farmId',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to link device to farm',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Update farm's last active timestamp
  Future<void> updateLastActive(String farmId) async {
    try {
      await _database.farmsDao.updateLastActive(farmId, DateTime.now());

      developer.log(
        'Farm last active updated: $farmId',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update farm last active',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
      // Don't rethrow - this is a non-critical operation
    }
  }

  // ========================
  // PRODUCTION METRICS
  // ========================

  /// Update farm production metrics
  Future<void> updateProductionMetrics(
    String farmId, {
    required int totalHarvests,
    required double totalYieldKg,
  }) async {
    try {
      await _database.farmsDao.updateProductionMetrics(
        farmId,
        totalHarvests,
        totalYieldKg,
      );

      developer.log(
        'Production metrics updated for farm: $farmId',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update production metrics',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Recalculate and update farm production metrics from harvests
  Future<void> recalculateProductionMetrics(String farmId) async {
    try {
      final harvestCount =
          await _database.harvestsDao.getHarvestCountByFarm(farmId);
      final totalYield =
          await _database.harvestsDao.getTotalYieldByFarm(farmId);

      await updateProductionMetrics(
        farmId,
        totalHarvests: harvestCount,
        totalYieldKg: totalYield,
      );

      developer.log(
        'Recalculated production metrics: $harvestCount harvests, ${totalYield.toStringAsFixed(2)}kg',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to recalculate production metrics',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // FARM STATISTICS
  // ========================

  /// Get farm statistics summary
  Future<FarmStats> getFarmStats(String farmId) async {
    try {
      final farm = await _database.farmsDao.getFarmById(farmId);
      if (farm == null) {
        throw FarmRepositoryException('Farm not found: $farmId');
      }

      final harvestCount =
          await _database.harvestsDao.getHarvestCountByFarm(farmId);
      final totalYield =
          await _database.harvestsDao.getTotalYieldByFarm(farmId);
      final avgYield =
          await _database.harvestsDao.getAverageYieldByFarm(farmId);

      final latestReading =
          await _database.readingsDao.getLatestReadingByFarm(farmId);

      final daysActive = DateTime.now().difference(farm.createdAt).inDays;

      return FarmStats(
        farmId: farmId,
        farmName: farm.name,
        harvestCount: harvestCount,
        totalYieldKg: totalYield,
        averageYieldKg: avgYield,
        daysActive: daysActive,
        yieldPerDay: daysActive > 0 ? totalYield / daysActive : 0.0,
        lastConnection: farm.lastActive,
        currentTemperature: latestReading?.temperatureC,
        currentHumidity: latestReading?.relativeHumidity,
        currentCO2: latestReading?.co2Ppm,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get farm stats',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // ARCHIVE/RESTORE
  // ========================

  /// Archive a farm (soft delete)
  Future<void> archiveFarm(String farmId) async {
    try {
      await _database.farmsDao.setFarmActive(farmId, false);

      developer.log(
        'Farm archived: $farmId',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to archive farm',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Restore an archived farm
  Future<void> restoreFarm(String farmId) async {
    try {
      await _database.farmsDao.setFarmActive(farmId, true);

      developer.log(
        'Farm restored: $farmId',
        name: 'FarmRepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to restore farm',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // HARVEST OPERATIONS
  // ========================

  /// Record a harvest
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
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final companion = HarvestsCompanion(
        id: Value(id),
        farmId: Value(farmId),
        harvestDate: Value(harvestDate),
        species: Value(species.id),
        stage: Value(stage.id),
        yieldKg: Value(yieldKg),
        flushNumber: Value(flushNumber),
        qualityScore: Value(qualityScore),
        notes: Value(notes),
        photoUrls: Value(photoUrls != null ? _encodePhotoUrls(photoUrls) : null),
        metadata: Value(metadata != null ? _encodeMetadata(metadata) : null),
      );

      await _database.harvestsDao.insertHarvest(companion);

      // Recalculate farm production metrics
      await recalculateProductionMetrics(farmId);

      developer.log(
        'Harvest recorded: ${yieldKg.toStringAsFixed(2)}kg for farm $farmId',
        name: 'FarmRepository',
      );

      return id;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to record harvest',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get harvests for a farm
  Future<List<models.HarvestRecord>> getHarvestsForFarm(String farmId) async {
    try {
      final harvests =
          await _database.harvestsDao.getHarvestsByFarmId(farmId);
      return harvests.map(_harvestFromDrift).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get harvests for farm',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get harvests for a farm within a period
  Future<List<models.HarvestRecord>> getHarvestsForPeriod(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final harvests = await _database.harvestsDao
          .getHarvestsByFarmAndPeriod(farmId, startDate, endDate);
      return harvests.map(_harvestFromDrift).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get harvests for period',
        name: 'FarmRepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  // ========================
  // VALIDATION
  // ========================

  /// Validate farm creation
  void validateFarm({
    required String name,
    required String deviceId,
  }) {
    if (name.trim().isEmpty) {
      throw FarmValidationException('Farm name cannot be empty');
    }

    if (deviceId.trim().isEmpty) {
      throw FarmValidationException('Device ID cannot be empty');
    }
  }

  /// Validate harvest record
  void validateHarvest({
    required double yieldKg,
    double? qualityScore,
  }) {
    if (yieldKg <= 0) {
      throw FarmValidationException('Yield must be greater than 0');
    }

    if (qualityScore != null && (qualityScore < 0 || qualityScore > 10)) {
      throw FarmValidationException('Quality score must be between 0 and 10');
    }
  }

  // ========================
  // HELPER METHODS
  // ========================

  /// Convert Drift Farm to model Farm
  models.Farm _farmFromDrift(Farm farm) {
    return models.Farm(
      id: farm.id,
      name: farm.name,
      deviceId: farm.deviceId,
      location: farm.location,
      notes: farm.notes,
      createdAt: farm.createdAt,
      lastActive: farm.lastActive,
      totalHarvests: farm.totalHarvests,
      totalYieldKg: farm.totalYieldKg,
      primarySpecies:
          farm.primarySpecies != null ? Species.fromId(farm.primarySpecies!) : null,
      imageUrl: farm.imageUrl,
      isActive: farm.isActive,
      metadata: farm.metadata != null ? _decodeMetadata(farm.metadata!) : null,
    );
  }

  /// Convert Drift Harvest to model HarvestRecord
  models.HarvestRecord _harvestFromDrift(Harvest harvest) {
    return models.HarvestRecord(
      id: harvest.id,
      farmId: harvest.farmId,
      harvestDate: harvest.harvestDate,
      species: Species.fromId(harvest.species),
      stage: GrowthStage.fromId(harvest.stage),
      yieldKg: harvest.yieldKg,
      flushNumber: harvest.flushNumber,
      qualityScore: harvest.qualityScore,
      notes: harvest.notes,
      photoUrls: harvest.photoUrls != null ? _decodePhotoUrls(harvest.photoUrls!) : null,
      metadata: harvest.metadata != null ? _decodeMetadata(harvest.metadata!) : null,
    );
  }

  /// Encode metadata to string (JSON)
  String _encodeMetadata(Map<String, dynamic> metadata) {
    // In production, use json.encode()
    return metadata.toString();
  }

  /// Decode metadata from string
  Map<String, dynamic> _decodeMetadata(String metadata) {
    // In production, use json.decode()
    return {};
  }

  /// Encode photo URLs to string (JSON array)
  String _encodePhotoUrls(List<String> photoUrls) {
    // In production, use json.encode()
    return photoUrls.join(',');
  }

  /// Decode photo URLs from string
  List<String> _decodePhotoUrls(String photoUrls) {
    // In production, use json.decode()
    return photoUrls.split(',');
  }
}

/// Farm statistics summary
class FarmStats {
  final String farmId;
  final String farmName;
  final int harvestCount;
  final double totalYieldKg;
  final double averageYieldKg;
  final int daysActive;
  final double yieldPerDay;
  final DateTime? lastConnection;
  final double? currentTemperature;
  final double? currentHumidity;
  final int? currentCO2;

  FarmStats({
    required this.farmId,
    required this.farmName,
    required this.harvestCount,
    required this.totalYieldKg,
    required this.averageYieldKg,
    required this.daysActive,
    required this.yieldPerDay,
    this.lastConnection,
    this.currentTemperature,
    this.currentHumidity,
    this.currentCO2,
  });
}

/// Farm repository exception
class FarmRepositoryException implements Exception {
  final String message;

  FarmRepositoryException(this.message);

  @override
  String toString() => 'FarmRepositoryException: $message';
}

/// Farm validation exception
class FarmValidationException implements Exception {
  final String message;

  FarmValidationException(this.message);

  @override
  String toString() => 'FarmValidationException: $message';
}
