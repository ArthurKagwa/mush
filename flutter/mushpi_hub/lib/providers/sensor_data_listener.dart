// lib/providers/sensor_data_listener.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:developer' as developer;

import '../providers/ble_provider.dart';
import '../providers/farms_provider.dart';
import '../providers/database_provider.dart';
import '../core/utils/ble_serializer.dart';
import '../data/database/app_database.dart';

/// Sensor Data Listener Provider
///
/// Automatically listens to BLE environmental data stream and saves
/// readings to the database. Links data to the correct farm based on
/// the connected device ID.
///
/// Features:
/// - Subscribes to environmentalDataStream from BLE
/// - Identifies farm by matching device ID
/// - Saves readings to database automatically
/// - Handles connection/disconnection lifecycle
/// - Debounces rapid updates (max 1 save per 5 seconds per farm)
///
/// Usage:
/// ```dart
/// // Initialize at app startup to enable automatic data saving
/// ref.read(sensorDataListenerProvider);
/// ```
final sensorDataListenerProvider = Provider<SensorDataListener>((ref) {
  final listener = SensorDataListener(ref);
  listener.initialize();
  
  ref.onDispose(() {
    listener.dispose();
  });
  
  return listener;
});

/// Manages automatic sensor data saving from BLE to database
class SensorDataListener {
  SensorDataListener(this._ref);

  final Ref _ref;
  StreamSubscription<EnvironmentalReading>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  // Debouncing: track last save time per farm to avoid excessive writes
  final Map<String, DateTime> _lastSaveTime = {};
  static const _minSaveInterval = Duration(seconds: 5);
  
  String? _currentDeviceId;
  String? _currentFarmId;

  /// Initialize sensor data listener
  void initialize() {
    debugPrint('🎬 [SensorListener] Initializing sensor data listener');
    developer.log(
      'Initializing sensor data listener',
      name: 'mushpi.sensor_data_listener',
    );

    // Listen to BLE connection state to track current device
    _connectionSubscription = _ref
        .read(bleRepositoryProvider)
        .connectionStateStream
        .listen(_onConnectionStateChanged);

    // Listen to environmental data stream
    _dataSubscription = _ref
        .read(bleRepositoryProvider)
        .environmentalDataStream
        .listen(
          _onEnvironmentalDataReceived,
          onError: _onDataStreamError,
        );

    debugPrint('✅ [SensorListener] Sensor data listener initialized and ready');
    developer.log(
      'Sensor data listener initialized and ready',
      name: 'mushpi.sensor_data_listener',
    );
  }

  /// Handle BLE connection state changes
  void _onConnectionStateChanged(BluetoothConnectionState state) async {
    debugPrint('🔄 [SensorListener] Connection state changed: $state');
    developer.log(
      'Connection state changed: $state',
      name: 'mushpi.sensor_data_listener',
    );

    switch (state) {
      case BluetoothConnectionState.connected:
        await _onDeviceConnected();
        break;
      case BluetoothConnectionState.disconnected:
        _onDeviceDisconnected();
        break;
      default:
        break;
    }
  }

  /// Handle device connection - identify the farm
  Future<void> _onDeviceConnected() async {
    try {
      final device = _ref.read(bleRepositoryProvider).connectedDevice;
      
      if (device == null) {
        debugPrint('⚠️ [SensorListener] Device connected but no device reference available');
        developer.log(
          'Device connected but no device reference available',
          name: 'mushpi.sensor_data_listener',
          level: 900,
        );
        return;
      }

      _currentDeviceId = device.remoteId.toString();

      debugPrint('🔗 [SensorListener] Device connected: $_currentDeviceId');
      developer.log(
        '🔗 Device connected: $_currentDeviceId',
        name: 'mushpi.sensor_data_listener',
      );

      // Find the farm associated with this device
      await _identifyFarm(_currentDeviceId!);
    } catch (error, stackTrace) {
      debugPrint('❌ [SensorListener] Error handling device connection: $error');
      developer.log(
        '❌ Error handling device connection',
        name: 'mushpi.sensor_data_listener',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Handle device disconnection
  void _onDeviceDisconnected() {
    debugPrint('🔌 [SensorListener] Device disconnected: $_currentDeviceId');
    developer.log(
      '🔌 Device disconnected: $_currentDeviceId',
      name: 'mushpi.sensor_data_listener',
    );

    _currentDeviceId = null;
    _currentFarmId = null;
  }

  /// Identify which farm this device belongs to
  Future<void> _identifyFarm(String deviceId) async {
    try {
      final farmsDao = _ref.read(farmsDaoProvider);
      final farms = await farmsDao.getAllFarms();

      final matchingFarm = farms
          .where((farm) => farm.deviceId == deviceId)
          .firstOrNull;

      if (matchingFarm == null) {
        debugPrint('⚠️ [SensorListener] No farm found for device: $deviceId');
        developer.log(
          '⚠️ No farm found for device: $deviceId',
          name: 'mushpi.sensor_data_listener',
          level: 900,
        );
        _currentFarmId = null;
        return;
      }

      _currentFarmId = matchingFarm.id;

      debugPrint('✅ [SensorListener] Identified farm: ${matchingFarm.name} (ID: $_currentFarmId)');
      developer.log(
        '✅ Identified farm: ${matchingFarm.name} (ID: $_currentFarmId)',
        name: 'mushpi.sensor_data_listener',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [SensorListener] Error identifying farm: $error');
      developer.log(
        '❌ Error identifying farm',
        name: 'mushpi.sensor_data_listener',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      _currentFarmId = null;
    }
  }

  /// Handle incoming environmental data
  void _onEnvironmentalDataReceived(EnvironmentalReading reading) async {
    try {
      // Must have a farm identified to save data
      if (_currentFarmId == null) {
        debugPrint('⏭️ [SensorListener] Skipping reading save - no farm identified');
        developer.log(
          '⏭️ Skipping reading save - no farm identified',
          name: 'mushpi.sensor_data_listener',
          level: 500,
        );
        return;
      }

      // Check if we should debounce this save
      if (_shouldDebounce(_currentFarmId!)) {
        debugPrint('⏭️ [SensorListener] Debouncing - skipping save (last save was < ${_minSaveInterval.inSeconds}s ago)');
        developer.log(
          '⏭️ Debouncing - skipping save (last save was < ${_minSaveInterval.inSeconds}s ago)',
          name: 'mushpi.sensor_data_listener',
          level: 500,
        );
        return;
      }

      debugPrint('📊 [SensorListener] Received environmental data:\n'
        '  Farm: $_currentFarmId\n'
        '  Temperature: ${reading.temperatureC.toStringAsFixed(1)}°C\n'
        '  Humidity: ${reading.relativeHumidity.toStringAsFixed(1)}%\n'
        '  CO₂: ${reading.co2Ppm} ppm\n'
        '  Light: ${reading.lightRaw}');
      developer.log(
        '📊 Received environmental data:\n'
        '  Farm: $_currentFarmId\n'
        '  Temperature: ${reading.temperatureC.toStringAsFixed(1)}°C\n'
        '  Humidity: ${reading.relativeHumidity.toStringAsFixed(1)}%\n'
        '  CO₂: ${reading.co2Ppm} ppm\n'
        '  Light: ${reading.lightRaw}',
        name: 'mushpi.sensor_data_listener',
      );

      // Save to database
      await _saveReading(reading, _currentFarmId!);

      // Update last save time
      _lastSaveTime[_currentFarmId!] = DateTime.now();

      debugPrint('✅ [SensorListener] Successfully saved reading to database');
      developer.log(
        '✅ Successfully saved reading to database',
        name: 'mushpi.sensor_data_listener',
      );

      // Invalidate providers to refresh UI
      _invalidateProviders();
    } catch (error, stackTrace) {
      debugPrint('❌ [SensorListener] Error processing environmental data: $error');
      developer.log(
        '❌ Error processing environmental data',
        name: 'mushpi.sensor_data_listener',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Check if we should debounce this save
  bool _shouldDebounce(String farmId) {
    final lastSave = _lastSaveTime[farmId];
    if (lastSave == null) return false;

    final timeSinceLastSave = DateTime.now().difference(lastSave);
    return timeSinceLastSave < _minSaveInterval;
  }

  /// Save reading to database
  Future<void> _saveReading(EnvironmentalReading reading, String farmId) async {
    try {
      final readingsDao = _ref.read(readingsDaoProvider);

      await readingsDao.insertReading(
        ReadingsCompanion.insert(
          farmId: farmId,
          timestamp: reading.timestamp,
          co2Ppm: reading.co2Ppm,
          temperatureC: reading.temperatureC,
          relativeHumidity: reading.relativeHumidity,
          lightRaw: reading.lightRaw,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [SensorListener] Failed to save reading to database: $error');
      developer.log(
        '❌ Failed to save reading to database',
        name: 'mushpi.sensor_data_listener',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Invalidate providers to refresh UI with new data
  void _invalidateProviders() {
    try {
      // Invalidate farm providers to refresh monitoring screens
      _ref.invalidate(activeFarmsProvider);
      
      // The monitoring screen providers will automatically refresh
      // when they detect new data
    } catch (error) {
      debugPrint('⚠️ [SensorListener] Error invalidating providers: $error');
      developer.log(
        '⚠️ Error invalidating providers',
        name: 'mushpi.sensor_data_listener',
        error: error,
        level: 900,
      );
    }
  }

  /// Handle errors from data stream
  void _onDataStreamError(Object error, StackTrace stackTrace) {
    debugPrint('❌ [SensorListener] Environmental data stream error: $error');
    developer.log(
      '❌ Environmental data stream error',
      name: 'mushpi.sensor_data_listener',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  /// Clean up resources
  void dispose() {
    debugPrint('🛑 [SensorListener] Disposing sensor data listener');
    developer.log(
      'Disposing sensor data listener',
      name: 'mushpi.sensor_data_listener',
    );

    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _lastSaveTime.clear();
  }
}
