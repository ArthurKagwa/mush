import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Get all settings
  Future<List<Setting>> getAllSettings() => select(settings).get();

  /// Get setting by key
  Future<Setting?> getSetting(String key) {
    return (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
  }

  /// Get setting value by key (returns null if not found)
  Future<String?> getValue(String key) async {
    final setting = await getSetting(key);
    return setting?.value;
  }

  /// Get setting value with default fallback
  Future<String> getValueOrDefault(String key, String defaultValue) async {
    final value = await getValue(key);
    return value ?? defaultValue;
  }

  /// Set a setting value (insert or update)
  Future<void> setValue(String key, String value) async {
    await into(settings).insert(
      SettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (old) => SettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      ),
    );
  }

  /// Set multiple settings at once
  Future<void> setMultipleValues(Map<String, String> keyValuePairs) async {
    await batch((batch) {
      for (final entry in keyValuePairs.entries) {
        batch.insert(
          settings,
          SettingsCompanion(
            key: Value(entry.key),
            value: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (old) => SettingsCompanion(
              value: Value(entry.value),
              updatedAt: Value(DateTime.now()),
            ),
          ),
        );
      }
    });
  }

  /// Delete a setting
  Future<int> deleteSetting(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  /// Delete multiple settings
  Future<int> deleteMultipleSettings(List<String> keys) {
    return (delete(settings)..where((s) => s.key.isIn(keys))).go();
  }

  /// Delete all settings
  Future<int> deleteAllSettings() {
    return delete(settings).go();
  }

  /// Check if a setting exists
  Future<bool> settingExists(String key) async {
    final setting = await getSetting(key);
    return setting != null;
  }

  /// Get settings count
  Future<int> getSettingsCount() async {
    final query = selectOnly(settings)..addColumns([settings.key.count()]);
    final result = await query.getSingleOrNull();
    return result?.read(settings.key.count()) ?? 0;
  }

  /// Get settings updated after a specific date
  Future<List<Setting>> getSettingsUpdatedSince(DateTime since) {
    return (select(settings)
          ..where((s) => s.updatedAt.isBiggerOrEqualValue(since))
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
  }

  // === App-Specific Setting Keys ===

  /// Last selected farm ID
  static const String keyLastSelectedFarmId = 'last_selected_farm_id';

  /// Theme mode (light/dark/system)
  static const String keyThemeMode = 'theme_mode';

  /// Notification enabled
  static const String keyNotificationsEnabled = 'notifications_enabled';

  /// Auto-reconnect enabled
  static const String keyAutoReconnect = 'auto_reconnect';

  /// Data retention days
  static const String keyDataRetentionDays = 'data_retention_days';

  /// Chart time range (24h/7d/30d)
  static const String keyChartTimeRange = 'chart_time_range';

  // === Convenience Methods for Common Settings ===

  /// Get last selected farm ID
  Future<String?> getLastSelectedFarmId() => getValue(keyLastSelectedFarmId);

  /// Set last selected farm ID
  Future<void> setLastSelectedFarmId(String farmId) =>
      setValue(keyLastSelectedFarmId, farmId);

  /// Clear last selected farm ID
  Future<int> clearLastSelectedFarmId() =>
      deleteSetting(keyLastSelectedFarmId);

  /// Get theme mode
  Future<String> getThemeMode() =>
      getValueOrDefault(keyThemeMode, 'system');

  /// Set theme mode
  Future<void> setThemeMode(String mode) => setValue(keyThemeMode, mode);

  /// Get notifications enabled
  Future<bool> getNotificationsEnabled() async {
    final value = await getValueOrDefault(keyNotificationsEnabled, 'true');
    return value.toLowerCase() == 'true';
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) =>
      setValue(keyNotificationsEnabled, enabled.toString());

  /// Get auto-reconnect enabled
  Future<bool> getAutoReconnect() async {
    final value = await getValueOrDefault(keyAutoReconnect, 'true');
    return value.toLowerCase() == 'true';
  }

  /// Set auto-reconnect enabled
  Future<void> setAutoReconnect(bool enabled) =>
      setValue(keyAutoReconnect, enabled.toString());

  /// Get data retention days
  Future<int> getDataRetentionDays() async {
    final value = await getValueOrDefault(keyDataRetentionDays, '90');
    return int.tryParse(value) ?? 90;
  }

  /// Set data retention days
  Future<void> setDataRetentionDays(int days) =>
      setValue(keyDataRetentionDays, days.toString());

  /// Get chart time range
  Future<String> getChartTimeRange() =>
      getValueOrDefault(keyChartTimeRange, '24h');

  /// Set chart time range
  Future<void> setChartTimeRange(String range) =>
      setValue(keyChartTimeRange, range);
}
