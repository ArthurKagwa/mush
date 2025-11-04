import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'harvests_dao.g.dart';

@DriftAccessor(tables: [Harvests])
class HarvestsDao extends DatabaseAccessor<AppDatabase> with _$HarvestsDaoMixin {
  HarvestsDao(AppDatabase db) : super(db);

  /// Get all harvests
  Future<List<Harvest>> getAllHarvests() => select(harvests).get();

  /// Get harvest by ID
  Future<Harvest?> getHarvestById(String id) {
    return (select(harvests)..where((h) => h.id.equals(id))).getSingleOrNull();
  }

  /// Get harvests by farm ID
  Future<List<Harvest>> getHarvestsByFarmId(String farmId) {
    return (select(harvests)..where((h) => h.farmId.equals(farmId))).get();
  }

  /// Get harvests by farm and date range
  Future<List<Harvest>> getHarvestsByFarmAndPeriod(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(harvests)
          ..where((h) =>
              h.farmId.equals(farmId) &
              h.harvestDate.isBiggerOrEqualValue(startDate) &
              h.harvestDate.isSmallerOrEqualValue(endDate))
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
        .get();
  }

  /// Get harvests by species
  Future<List<Harvest>> getHarvestsBySpecies(int species) {
    return (select(harvests)
          ..where((h) => h.species.equals(species))
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
        .get();
  }

  /// Get recent harvests (limited)
  Future<List<Harvest>> getRecentHarvests(int limit) {
    return (select(harvests)
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)])
          ..limit(limit))
        .get();
  }

  /// Get total yield for a farm
  Future<double> getTotalYieldByFarm(String farmId) async {
    final query = selectOnly(harvests)
      ..addColumns([harvests.yieldKg.sum()])
      ..where(harvests.farmId.equals(farmId));

    final result = await query.getSingleOrNull();
    return result?.read(harvests.yieldKg.sum()) ?? 0.0;
  }

  /// Get harvest count for a farm
  Future<int> getHarvestCountByFarm(String farmId) async {
    final query = selectOnly(harvests)
      ..addColumns([harvests.id.count()])
      ..where(harvests.farmId.equals(farmId));

    final result = await query.getSingleOrNull();
    return result?.read(harvests.id.count()) ?? 0;
  }

  /// Get average yield per harvest for a farm
  Future<double> getAverageYieldByFarm(String farmId) async {
    final query = selectOnly(harvests)
      ..addColumns([harvests.yieldKg.avg()])
      ..where(harvests.farmId.equals(farmId));

    final result = await query.getSingleOrNull();
    return result?.read(harvests.yieldKg.avg()) ?? 0.0;
  }

  /// Insert a new harvest
  Future<int> insertHarvest(HarvestsCompanion harvest) {
    return into(harvests).insert(harvest);
  }

  /// Update an existing harvest
  Future<bool> updateHarvest(Harvest harvest) {
    return update(harvests).replace(harvest);
  }

  /// Delete a harvest
  Future<int> deleteHarvest(String id) {
    return (delete(harvests)..where((h) => h.id.equals(id))).go();
  }

  /// Delete all harvests for a farm
  Future<int> deleteHarvestsByFarm(String farmId) {
    return (delete(harvests)..where((h) => h.farmId.equals(farmId))).go();
  }

  /// Get harvests by flush number
  Future<List<Harvest>> getHarvestsByFlush(String farmId, int flushNumber) {
    return (select(harvests)
          ..where((h) =>
              h.farmId.equals(farmId) & h.flushNumber.equals(flushNumber))
          ..orderBy([(h) => OrderingTerm.desc(h.harvestDate)]))
        .get();
  }

  /// Get best quality harvests (quality score >= threshold)
  Future<List<Harvest>> getHighQualityHarvests(double qualityThreshold) {
    return (select(harvests)
          ..where((h) => h.qualityScore.isBiggerOrEqualValue(qualityThreshold))
          ..orderBy([(h) => OrderingTerm.desc(h.qualityScore)]))
        .get();
  }
}
