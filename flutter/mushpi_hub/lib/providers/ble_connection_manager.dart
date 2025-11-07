// lib/providers/ble_connection_manager.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:developer' as developer;

import '../providers/ble_provider.dart';
import '../providers/farms_provider.dart';
import '../providers/database_provider.dart';
import '../providers/auto_reconnect_provider.dart';

/// BLE Connection Manager Provider
///
/// Monitors BLE connection state and automatically updates farm lastActive
/// timestamps when devices connect. This ensures farms show as "Online"
/// when their MushPi devices are connected via BLE.
///
/// Features:
/// - Listens to BLE connection state changes
/// - Updates farm.lastActive on connection
/// - Periodic heartbeat (every 90 seconds) while connected
/// - Automatically finds farm by device ID
///
/// Usage:
/// ```dart
/// // Initialize at app startup to enable automatic farm status updates
/// ref.read(bleConnectionManagerProvider);
/// ```
final bleConnectionManagerProvider = Provider<BLEConnectionManager>((ref) {
  final manager = BLEConnectionManager(ref);
  manager.initialize();
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Manages BLE connection lifecycle and farm status updates
class BLEConnectionManager {
  BLEConnectionManager(this._ref);

  final Ref _ref;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _heartbeatTimer;
  String? _currentDeviceId;

  /// Initialize connection monitoring
  void initialize() {
    debugPrint('🎬 [BLEConnectionManager] Initializing BLE connection manager');
    developer.log(
      'Initializing BLE connection manager',
      name: 'mushpi.ble_connection_manager',
    );

    // Listen to BLE connection state changes
    _connectionSubscription = _ref
        .read(bleRepositoryProvider)
        .connectionStateStream
        .listen(_onConnectionStateChanged);
  }

  /// Handle connection state changes
  void _onConnectionStateChanged(BluetoothConnectionState state) async {
    debugPrint('🔄 [BLEConnectionManager] BLE connection state changed: $state');
    developer.log(
      'BLE connection state changed: $state',
      name: 'mushpi.ble_connection_manager',
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

  /// Handle device connection
  Future<void> _onDeviceConnected() async {
    try {
      final device = _ref.read(bleRepositoryProvider).connectedDevice;
      
      if (device == null) {
        debugPrint('⚠️ [BLEConnectionManager] Device connected but no device reference available');
        developer.log(
          'Device connected but no device reference available',
          name: 'mushpi.ble_connection_manager',
          level: 900,
        );
        return;
      }

      _currentDeviceId = device.remoteId.toString();

      debugPrint('🔗 [BLEConnectionManager] Device connected: $_currentDeviceId');
      developer.log(
        'Device connected: $_currentDeviceId',
        name: 'mushpi.ble_connection_manager',
      );

      // Save device info for auto-reconnect
      await _saveDeviceInfo(device);

      // Find and update the farm associated with this device
      await _updateFarmLastActive(_currentDeviceId!);

      // Start periodic heartbeat to keep farm "online"
      _startHeartbeat();
    } catch (error, stackTrace) {
      debugPrint('❌ [BLEConnectionManager] Error handling device connection: $error');
      developer.log(
        'Error handling device connection',
        name: 'mushpi.ble_connection_manager',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Handle device disconnection
  void _onDeviceDisconnected() async {
    final wasConnected = _currentDeviceId != null;
    
    debugPrint('🔌 [BLEConnectionManager] Device disconnected: $_currentDeviceId');
    developer.log(
      'Device disconnected: $_currentDeviceId',
      name: 'mushpi.ble_connection_manager',
    );

    // Stop heartbeat
    _stopHeartbeat();
    
    // Update farm status to offline by clearing lastActive
    if (_currentDeviceId != null) {
      await _clearFarmLastActive(_currentDeviceId!);
    }
    
    // Only trigger auto-reconnect if we had a successful connection before
    // This prevents endless reconnect loops on first-time connection failures
    if (wasConnected) {
      debugPrint('🔄 [BLEConnectionManager] Was previously connected - triggering auto-reconnect');
      _triggerAutoReconnect();
    } else {
      debugPrint('ℹ️ [BLEConnectionManager] Never connected - skipping auto-reconnect');
      developer.log(
        'Disconnected before successful connection - skipping auto-reconnect',
        name: 'mushpi.ble_connection_manager',
      );
    }
    
    _currentDeviceId = null;
  }

  /// Update farm's lastActive timestamp
  Future<void> _updateFarmLastActive(String deviceId) async {
    try {
      // Get all farms and find the one with matching deviceId
      final farmsDao = _ref.read(farmsDaoProvider);
      final farms = await farmsDao.getAllFarms();

      final matchingFarm = farms.where((farm) => farm.deviceId == deviceId).firstOrNull;

      if (matchingFarm == null) {
        debugPrint('⚠️ [BLEConnectionManager] No farm found for device: $deviceId');
        developer.log(
          'No farm found for device: $deviceId',
          name: 'mushpi.ble_connection_manager',
          level: 900,
        );
        return;
      }

      debugPrint('🔄 [BLEConnectionManager] Updating lastActive for farm: ${matchingFarm.name} (ID: ${matchingFarm.id})');
      developer.log(
        'Updating lastActive for farm: ${matchingFarm.name} (ID: ${matchingFarm.id})',
        name: 'mushpi.ble_connection_manager',
      );

      // Update lastActive timestamp
      final farmOps = _ref.read(farmOperationsProvider);
      await farmOps.updateLastActive(matchingFarm.id);

      // Invalidate providers to refresh UI
      _ref.invalidate(activeFarmsProvider);
      _ref.invalidate(farmByIdProvider(matchingFarm.id));

      debugPrint('✅ [BLEConnectionManager] Successfully updated lastActive for farm: ${matchingFarm.name}');
      developer.log(
        'Successfully updated lastActive for farm: ${matchingFarm.name}',
        name: 'mushpi.ble_connection_manager',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [BLEConnectionManager] Error updating farm lastActive: $error');
      developer.log(
        'Error updating farm lastActive',
        name: 'mushpi.ble_connection_manager',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Clear farm's lastActive timestamp to mark as offline
  Future<void> _clearFarmLastActive(String deviceId) async {
    try {
      // Get all farms and find the one with matching deviceId
      final farmsDao = _ref.read(farmsDaoProvider);
      final farms = await farmsDao.getAllFarms();

      final matchingFarm = farms.where((farm) => farm.deviceId == deviceId).firstOrNull;

      if (matchingFarm == null) {
        debugPrint('⚠️ [BLEConnectionManager] No farm found for device: $deviceId');
        developer.log(
          'No farm found for device: $deviceId',
          name: 'mushpi.ble_connection_manager',
          level: 900,
        );
        return;
      }

      debugPrint('🔄 [BLEConnectionManager] Clearing lastActive for farm: ${matchingFarm.name} to mark as offline');
      developer.log(
        'Clearing lastActive for farm: ${matchingFarm.name} to mark as offline',
        name: 'mushpi.ble_connection_manager',
      );

      // Clear lastActive timestamp by setting to null
      final farmOps = _ref.read(farmOperationsProvider);
      await farmOps.clearLastActive(matchingFarm.id);

      // Invalidate providers to refresh UI
      _ref.invalidate(activeFarmsProvider);
      _ref.invalidate(farmByIdProvider(matchingFarm.id));

      debugPrint('✅ [BLEConnectionManager] Successfully cleared lastActive for farm: ${matchingFarm.name} - now showing as offline');
      developer.log(
        'Successfully cleared lastActive for farm: ${matchingFarm.name} - now showing as offline',
        name: 'mushpi.ble_connection_manager',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [BLEConnectionManager] Error clearing farm lastActive: $error');
      developer.log(
        'Error clearing farm lastActive',
        name: 'mushpi.ble_connection_manager',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Start periodic heartbeat to keep farm online
  void _startHeartbeat() {
    _stopHeartbeat(); // Ensure no duplicate timers

    // Update every 30 seconds (well within the 1-minute online threshold)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentDeviceId != null) {
        debugPrint('💓 [BLEConnectionManager] Heartbeat: updating lastActive for device $_currentDeviceId');
        developer.log(
          'Heartbeat: updating lastActive for device $_currentDeviceId',
          name: 'mushpi.ble_connection_manager',
        );
        _updateFarmLastActive(_currentDeviceId!);
      }
    });

    debugPrint('✅ [BLEConnectionManager] Started heartbeat timer (30s interval)');
    developer.log(
      'Started heartbeat timer (30s interval)',
      name: 'mushpi.ble_connection_manager',
    );
  }

  /// Stop periodic heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    debugPrint('🛑 [BLEConnectionManager] Stopped heartbeat timer');
    developer.log(
      'Stopped heartbeat timer',
      name: 'mushpi.ble_connection_manager',
    );
  }

  /// Save device info for auto-reconnect
  Future<void> _saveDeviceInfo(BluetoothDevice device) async {
    try {
      final deviceId = device.remoteId.toString();
      final deviceAddress = device.remoteId.toString(); // Address is same as ID for BLE
      
      debugPrint('💾 [BLEConnectionManager] Saving device info for auto-reconnect...');
      debugPrint('  Device ID: $deviceId');
      debugPrint('  Device Address: $deviceAddress');
      
      // Find farm ID for this device
      final farmsDao = _ref.read(farmsDaoProvider);
      final farms = await farmsDao.getAllFarms();
      debugPrint('  Found ${farms.length} farms in database');
      
      final matchingFarm = farms.where((farm) => farm.deviceId == deviceId).firstOrNull;
      
      if (matchingFarm != null) {
        debugPrint('  ✅ Matched to farm: ${matchingFarm.name} (ID: ${matchingFarm.id})');
      } else {
        debugPrint('  ⚠️ No matching farm found for this device');
      }
      
      final settingsDao = _ref.read(settingsDaoProvider);
      await settingsDao.setLastConnectedDevice(
        deviceId: deviceId,
        address: deviceAddress,
        farmId: matchingFarm?.id,
      );
      
      debugPrint('✅ [BLEConnectionManager] Device info saved successfully!');
      developer.log(
        'Saved device info for auto-reconnect: $deviceId',
        name: 'mushpi.ble_connection_manager',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [BLEConnectionManager] Error saving device info: $error');
      debugPrint('Stack trace: $stackTrace');
      developer.log(
        'Error saving device info',
        name: 'mushpi.ble_connection_manager',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Trigger auto-reconnect on unexpected disconnect
  void _triggerAutoReconnect() {
    try {
      final autoReconnect = _ref.read(autoReconnectServiceProvider);
      
      developer.log(
        'Triggering auto-reconnect for unexpected disconnect',
        name: 'mushpi.ble_connection_manager',
      );
      
      // Handle disconnection (will start retry logic if enabled)
      autoReconnect.onDisconnected(isManual: false);
    } catch (error, stackTrace) {
      developer.log(
        'Error triggering auto-reconnect',
        name: 'mushpi.ble_connection_manager',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Clean up resources
  void dispose() {
    developer.log(
      'Disposing BLE connection manager',
      name: 'mushpi.ble_connection_manager',
    );

    _connectionSubscription?.cancel();
    _stopHeartbeat();
  }
}
