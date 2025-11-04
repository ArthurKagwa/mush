import 'package:drift/drift.dart';

/// Farms table - Core farm entity
class Farms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get deviceId => text().unique()(); // One device per farm
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActive => dateTime().nullable()();
  IntColumn get totalHarvests => integer().withDefault(const Constant(0))();
  RealColumn get totalYieldKg => real().withDefault(const Constant(0.0))();
  IntColumn get primarySpecies => integer().nullable()(); // Species enum ID
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get metadata => text().nullable()(); // JSON

  @override
  Set<Column> get primaryKey => {id};
}

/// Harvests table - Production tracking
class Harvests extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  DateTimeColumn get harvestDate => dateTime()();
  IntColumn get species => integer()(); // Species enum ID
  IntColumn get stage => integer()(); // GrowthStage enum ID
  RealColumn get yieldKg => real()();
  IntColumn get flushNumber => integer().nullable()();
  RealColumn get qualityScore => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrls => text().nullable()(); // JSON array
  TextColumn get metadata => text().nullable()(); // JSON

  @override
  Set<Column> get primaryKey => {id};
}

/// Devices table - BLE device connections
class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get farmId => text().nullable().references(Farms, #id)();
  DateTimeColumn get lastConnected => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// Readings table - Environmental sensor data
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get farmId => text().references(Farms, #id)();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get co2Ppm => integer()();
  RealColumn get temperatureC => real()();
  RealColumn get relativeHumidity => real()();
  IntColumn get lightRaw => integer()();
}

/// Settings table - App configuration and farm settings
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON serialized
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
