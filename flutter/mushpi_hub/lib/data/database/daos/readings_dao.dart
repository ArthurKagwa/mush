import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'readings_dao.g.dart';

@DriftAccessor(tables: [Readings])
class ReadingsDao extends DatabaseAccessor<AppDatabase> with _$ReadingsDaoMixin {
  ReadingsDao(super.db);

  /// Get all readings
  Future<List<Reading>> getAllReadings() => select(readings).get();

  /// Get reading by ID
  Future<Reading?> getReadingById(int id) {
    return (select(readings)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Get latest reading for a farm
  Future<Reading?> getLatestReadingByFarm(String farmId) {
    return (select(readings)
          ..where((r) => r.farmId.equals(farmId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get readings by farm ID
  Future<List<Reading>> getReadingsByFarmId(String farmId) {
    return (select(readings)
          ..where((r) => r.farmId.equals(farmId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }

  /// Get readings by farm and date range
  Future<List<Reading>> getReadingsByFarmAndPeriod(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(readings)
          ..where((r) =>
              r.farmId.equals(farmId) &
              r.timestamp.isBiggerOrEqualValue(startDate) &
              r.timestamp.isSmallerOrEqualValue(endDate))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
        .get();
  }

  /// Get recent readings for a farm (limited)
  Future<List<Reading>> getRecentReadingsByFarm(String farmId, int limit) {
    return (select(readings)
          ..where((r) => r.farmId.equals(farmId))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)])
          ..limit(limit))
        .get();
  }

  /// Get readings since a specific time
  Future<List<Reading>> getReadingsSince(String farmId, DateTime since) {
    return (select(readings)
          ..where((r) =>
              r.farmId.equals(farmId) &
              r.timestamp.isBiggerOrEqualValue(since))
          ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
        .get();
  }

  /// Get average temperature for a period
  Future<double> getAverageTemperature(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final query = selectOnly(readings)
      ..addColumns([readings.temperatureC.avg()])
      ..where(
        readings.farmId.equals(farmId) &
            readings.timestamp.isBiggerOrEqualValue(startDate) &
            readings.timestamp.isSmallerOrEqualValue(endDate),
      );

    final result = await query.getSingleOrNull();
    return result?.read(readings.temperatureC.avg()) ?? 0.0;
  }

  /// Get average humidity for a period
  Future<double> getAverageHumidity(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final query = selectOnly(readings)
      ..addColumns([readings.relativeHumidity.avg()])
      ..where(
        readings.farmId.equals(farmId) &
            readings.timestamp.isBiggerOrEqualValue(startDate) &
            readings.timestamp.isSmallerOrEqualValue(endDate),
      );

    final result = await query.getSingleOrNull();
    return result?.read(readings.relativeHumidity.avg()) ?? 0.0;
  }

  /// Get average CO2 for a period
  Future<double> getAverageCO2(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final query = selectOnly(readings)
      ..addColumns([readings.co2Ppm.avg()])
      ..where(
        readings.farmId.equals(farmId) &
            readings.timestamp.isBiggerOrEqualValue(startDate) &
            readings.timestamp.isSmallerOrEqualValue(endDate),
      );

    final result = await query.getSingleOrNull();
    return result?.read(readings.co2Ppm.avg()) ?? 0.0;
  }

  /// Insert a new reading
  Future<int> insertReading(ReadingsCompanion reading) {
    return into(readings).insert(reading);
  }

  /// Insert multiple readings (bulk insert)
  Future<void> insertMultipleReadings(List<ReadingsCompanion> readingsList) {
    return batch((batch) {
      batch.insertAll(readings, readingsList);
    });
  }

  /// Delete reading by ID
  Future<int> deleteReading(int id) {
    return (delete(readings)..where((r) => r.id.equals(id))).go();
  }

  /// Delete readings older than a date
  Future<int> deleteReadingsOlderThan(DateTime date) {
    return (delete(readings)..where((r) => r.timestamp.isSmallerThanValue(date))).go();
  }

  /// Delete all readings for a farm
  Future<int> deleteReadingsByFarm(String farmId) {
    return (delete(readings)..where((r) => r.farmId.equals(farmId))).go();
  }

  /// Get reading count for a farm
  Future<int> getReadingCountByFarm(String farmId) async {
    final query = selectOnly(readings)
      ..addColumns([readings.id.count()])
      ..where(readings.farmId.equals(farmId));

    final result = await query.getSingleOrNull();
    return result?.read(readings.id.count()) ?? 0;
  }

  /// Update farm ID for all readings of a device (for migration)
  Future<int> updateFarmIdForDevice(String oldFarmId, String newFarmId) {
    return (update(readings)..where((r) => r.farmId.equals(oldFarmId)))
        .write(ReadingsCompanion(farmId: Value(newFarmId)));
  }

  /// Get readings with alerts (exceeding thresholds)
  Future<List<Reading>> getAbnormalReadings(
    String farmId,
    double tempMin,
    double tempMax,
    double rhMin,
    int co2Max,
  ) {
    return (select(readings)
          ..where((r) =>
              r.farmId.equals(farmId) &
              (r.temperatureC.isSmallerThanValue(tempMin) |
                  r.temperatureC.isBiggerThanValue(tempMax) |
                  r.relativeHumidity.isSmallerThanValue(rhMin) |
                  r.co2Ppm.isBiggerThanValue(co2Max)))
          ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }
}
