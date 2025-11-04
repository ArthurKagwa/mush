import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tables.dart';
import 'daos/farms_dao.dart';
import 'daos/harvests_dao.dart';
import 'daos/readings_dao.dart';
import 'daos/devices_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

/// Main application database with Drift
/// 
/// Manages all local data storage including:
/// - Farms and farm metadata
/// - Harvest records and production tracking
/// - Environmental sensor readings
/// - BLE device connections
/// - App settings and configuration
@DriftDatabase(
  tables: [Farms, Harvests, Devices, Readings, Settings],
  daos: [FarmsDao, HarvestsDao, ReadingsDao, DevicesDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Open database connection
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'mushpi.db'));
      return NativeDatabase(file);
    });
  }
}
