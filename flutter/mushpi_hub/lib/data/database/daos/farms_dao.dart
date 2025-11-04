import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'farms_dao.g.dart';

/// Data Access Object for Farms table
@DriftAccessor(tables: [Farms])
class FarmsDao extends DatabaseAccessor<AppDatabase> with _$FarmsDaoMixin {
  FarmsDao(AppDatabase db) : super(db);

  /// Get all farms
  Future<List<Farm>> getAllFarms() {
    return select(farms).get();
  }

  /// Get active farms only
  Future<List<Farm>> getActiveFarms() {
    return (select(farms)..where((f) => f.isActive.equals(true))).get();
  }

  /// Get farm by ID
  Future<Farm?> getFarmById(String id) {
    return (select(farms)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Get farm by device ID
  Future<Farm?> getFarmByDeviceId(String deviceId) {
    return (select(farms)..where((f) => f.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  /// Insert new farm
  Future<int> insertFarm(FarmsCompanion farm) {
    return into(farms).insert(farm);
  }

  /// Update farm
  Future<bool> updateFarm(FarmsCompanion farm) {
    return update(farms).replace(farm);
  }

  /// Update farm's last active timestamp
  Future<int> updateLastActive(String farmId, DateTime timestamp) {
    return (update(farms)..where((f) => f.id.equals(farmId)))
        .write(FarmsCompanion(lastActive: Value(timestamp)));
  }

  /// Update farm production metrics
  Future<int> updateProductionMetrics(
    String farmId,
    int totalHarvests,
    double totalYieldKg,
  ) {
    return (update(farms)..where((f) => f.id.equals(farmId))).write(
      FarmsCompanion(
        totalHarvests: Value(totalHarvests),
        totalYieldKg: Value(totalYieldKg),
      ),
    );
  }

  /// Archive/unarchive farm
  Future<int> setFarmActive(String farmId, bool isActive) {
    return (update(farms)..where((f) => f.id.equals(farmId)))
        .write(FarmsCompanion(isActive: Value(isActive)));
  }

  /// Delete farm
  Future<int> deleteFarm(String farmId) {
    return (delete(farms)..where((f) => f.id.equals(farmId))).go();
  }

  /// Link device to farm
  Future<int> linkDeviceToFarm(String farmId, String deviceId) {
    return (update(farms)..where((f) => f.id.equals(farmId)))
        .write(FarmsCompanion(deviceId: Value(deviceId)));
  }
}
