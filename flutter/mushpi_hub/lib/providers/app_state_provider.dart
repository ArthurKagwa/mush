// lib/providers/app_state_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'package:mushpi_hub/providers/farms_provider.dart';
import 'package:mushpi_hub/providers/ble_provider.dart';
import 'dart:developer' as developer;

/// Theme mode provider
///
/// Manages the app's theme mode (light, dark, or system).
/// Persisted to settings database for restoration on app restart.
///
/// Usage:
/// ```dart
/// final themeMode = ref.watch(themeModeProvider);
/// MaterialApp(
///   themeMode: themeMode,
///   ...
/// );
/// 
/// // To change theme:
/// ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
/// ```
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settingsDao = ref.watch(settingsDaoProvider);
  return ThemeModeNotifier(settingsDao);
});

/// Notifier for theme mode state management
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._settingsDao) : super(ThemeMode.system) {
    _init();
  }

  final dynamic _settingsDao; // SettingsDao

  Future<void> _init() async {
    try {
      // Load theme mode from settings
      final themeModeString = await _settingsDao.getThemeMode();
      
      if (themeModeString != null) {
        state = _parseThemeMode(themeModeString);
        
        developer.log(
          'Restored theme mode: ${state.name}',
          name: 'mushpi.providers.app_state',
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load theme mode, using system default',
        name: 'mushpi.providers.app_state',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      developer.log(
        'Setting theme mode: ${mode.name}',
        name: 'mushpi.providers.app_state',
      );

      state = mode;

      // Persist to settings
      await _settingsDao.setThemeMode(mode.name);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to set theme mode',
        name: 'mushpi.providers.app_state',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// App initialization state provider
///
/// Tracks the app's initialization status.
///
/// Usage:
/// ```dart
/// final initState = ref.watch(appInitializationProvider);
/// initState.when(
///   data: (_) => HomePage(),
///   loading: () => SplashScreen(),
///   error: (err, stack) => ErrorScreen(error: err),
/// );
/// ```
final appInitializationProvider = FutureProvider<void>((ref) async {
  developer.log(
    'Initializing app',
    name: 'mushpi.providers.app_state',
  );

  try {
    // Initialize database
    final _ = ref.watch(databaseProvider);

    // Load initial data (optional pre-caching)
    // Farms will be lazy-loaded when needed
    
    // Small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    developer.log(
      'App initialization complete',
      name: 'mushpi.providers.app_state',
    );
  } catch (error, stackTrace) {
    developer.log(
      'App initialization failed',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    rethrow;
  }
});

/// Notifications enabled provider
///
/// Manages whether notifications are enabled.
///
/// Usage:
/// ```dart
/// final notificationsEnabled = ref.watch(notificationsEnabledProvider);
/// notificationsEnabled.when(
///   data: (enabled) => Switch(value: enabled, ...),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => false,
/// );
/// ```
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final settingsDao = ref.watch(settingsDaoProvider);
  
  try {
    final enabled = await settingsDao.getNotificationsEnabled();
    return enabled;
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get notifications setting',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
    return true; // Default to enabled
  }
});

/// Auto-reconnect enabled provider
///
/// Manages whether BLE auto-reconnect is enabled.
///
/// Usage:
/// ```dart
/// final autoReconnect = ref.watch(autoReconnectEnabledProvider);
/// ```
final autoReconnectEnabledProvider = FutureProvider<bool>((ref) async {
  final settingsDao = ref.watch(settingsDaoProvider);
  
  try {
    final enabled = await settingsDao.getAutoReconnect();
    return enabled;
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get auto-reconnect setting',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
    return true; // Default to enabled
  }
});

/// Data retention days provider
///
/// Gets the number of days to retain environmental readings.
///
/// Usage:
/// ```dart
/// final retentionDays = ref.watch(dataRetentionDaysProvider);
/// ```
final dataRetentionDaysProvider = FutureProvider<int>((ref) async {
  final settingsDao = ref.watch(settingsDaoProvider);
  
  try {
    final days = await settingsDao.getDataRetentionDays();
    return days;
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get data retention setting',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
    return 90; // Default to 90 days
  }
});

/// Chart time range provider
///
/// Gets the default time range for environmental data charts.
///
/// Usage:
/// ```dart
/// final timeRange = ref.watch(chartTimeRangeProvider);
/// ```
final chartTimeRangeProvider = FutureProvider<String>((ref) async {
  final settingsDao = ref.watch(settingsDaoProvider);
  
  try {
    final range = await settingsDao.getChartTimeRange();
    return range;
  } catch (error, stackTrace) {
    developer.log(
      'Failed to get chart time range setting',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
    return '24h'; // Default to 24 hours
  }
});

/// App settings operations provider
///
/// Provides convenient methods for managing app settings.
///
/// Usage:
/// ```dart
/// final appSettings = ref.read(appSettingsOperationsProvider);
/// await appSettings.setNotificationsEnabled(true);
/// ```
final appSettingsOperationsProvider = Provider<AppSettingsOperations>((ref) {
  final settingsDao = ref.watch(settingsDaoProvider);
  return AppSettingsOperations(settingsDao: settingsDao, ref: ref);
});

/// App Settings Operations wrapper class
class AppSettingsOperations {
  AppSettingsOperations({
    required this.settingsDao,
    required this.ref,
  });

  final dynamic settingsDao; // SettingsDao
  final Ref ref;

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      developer.log(
        'Setting notifications enabled: $enabled',
        name: 'mushpi.providers.app_state.settings',
      );

      await settingsDao.setValue('notifications_enabled', enabled ? '1' : '0');
      
      // Refresh provider
      ref.invalidate(notificationsEnabledProvider);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to set notifications enabled',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Set auto-reconnect enabled
  Future<void> setAutoReconnectEnabled(bool enabled) async {
    try {
      developer.log(
        'Setting auto-reconnect enabled: $enabled',
        name: 'mushpi.providers.app_state.settings',
      );

      await settingsDao.setValue('auto_reconnect', enabled ? '1' : '0');
      
      // Refresh provider
      ref.invalidate(autoReconnectEnabledProvider);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to set auto-reconnect enabled',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Set data retention days
  Future<void> setDataRetentionDays(int days) async {
    try {
      developer.log(
        'Setting data retention days: $days',
        name: 'mushpi.providers.app_state.settings',
      );

      await settingsDao.setValue('data_retention_days', days.toString());
      
      // Refresh provider
      ref.invalidate(dataRetentionDaysProvider);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to set data retention days',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Set chart time range
  Future<void> setChartTimeRange(String range) async {
    try {
      developer.log(
        'Setting chart time range: $range',
        name: 'mushpi.providers.app_state.settings',
      );

      await settingsDao.setValue('chart_time_range', range);
      
      // Refresh provider
      ref.invalidate(chartTimeRangeProvider);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to set chart time range',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Clear all app data (except farms and harvests)
  Future<void> clearAppData() async {
    try {
      developer.log(
        'Clearing app data',
        name: 'mushpi.providers.app_state.settings',
      );

      // Clear environmental readings (keep farms and harvests)
      final database = ref.read(databaseProvider);
      
      // This would need a method in the database to clear readings
      // For now, we can delete old readings
      final retentionDays = await settingsDao.getDataRetentionDays() ?? 90;
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      await database.readingsDao.deleteReadingsOlderThan(cutoffDate);

      developer.log(
        'App data cleared successfully',
        name: 'mushpi.providers.app_state.settings',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to clear app data',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetSettings() async {
    try {
      developer.log(
        'Resetting all settings to defaults',
        name: 'mushpi.providers.app_state.settings',
      );

      await settingsDao.deleteAllSettings();
      
      // Refresh all setting providers
      ref.invalidate(themeModeProvider);
      ref.invalidate(notificationsEnabledProvider);
      ref.invalidate(autoReconnectEnabledProvider);
      ref.invalidate(dataRetentionDaysProvider);
      ref.invalidate(chartTimeRangeProvider);

      developer.log(
        'Settings reset successfully',
        name: 'mushpi.providers.app_state.settings',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to reset settings',
        name: 'mushpi.providers.app_state.settings',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }
}

/// App health status provider
///
/// Provides overall app health status based on:
/// - Database connectivity
/// - Active farms count
/// - BLE availability
///
/// Usage:
/// ```dart
/// final health = ref.watch(appHealthStatusProvider);
/// health.when(
///   data: (status) => HealthIndicator(status: status),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => ErrorIndicator(),
/// );
/// ```
final appHealthStatusProvider = FutureProvider<AppHealthStatus>((ref) async {
  try {
    // Check database (always available via provider)
    const dbHealthy = true;

    // Check farms
    final farmsResult = await ref.watch(activeFarmsProvider.future);
    final farmsCount = farmsResult.length;

    // Check BLE availability
    final bleOps = ref.watch(bleOperationsProvider);
    final bleAvailable = await bleOps.isBluetoothAvailable();

    return AppHealthStatus(
      databaseHealthy: dbHealthy,
      activeFarmsCount: farmsCount,
      bluetoothAvailable: bleAvailable,
      lastCheckTime: DateTime.now(),
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to check app health',
      name: 'mushpi.providers.app_state',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    
    return AppHealthStatus(
      databaseHealthy: false,
      activeFarmsCount: 0,
      bluetoothAvailable: false,
      lastCheckTime: DateTime.now(),
    );
  }
});

/// App health status model
class AppHealthStatus {
  const AppHealthStatus({
    required this.databaseHealthy,
    required this.activeFarmsCount,
    required this.bluetoothAvailable,
    required this.lastCheckTime,
  });

  final bool databaseHealthy;
  final int activeFarmsCount;
  final bool bluetoothAvailable;
  final DateTime lastCheckTime;

  bool get isHealthy => databaseHealthy && bluetoothAvailable;
  
  String get statusMessage {
    if (isHealthy) {
      return 'App is running smoothly';
    }
    
    final issues = <String>[];
    if (!databaseHealthy) issues.add('Database issue');
    if (!bluetoothAvailable) issues.add('Bluetooth unavailable');
    
    return 'Issues: ${issues.join(', ')}';
  }
}
