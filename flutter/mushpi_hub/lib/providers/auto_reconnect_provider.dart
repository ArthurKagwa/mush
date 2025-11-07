// lib/providers/auto_reconnect_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:developer' as developer;

import '../providers/ble_provider.dart';
import '../providers/database_provider.dart';

/// Auto-reconnection state
enum ReconnectionState {
  idle,
  scanning,
  connecting,
  connected,
  failed,
  disabled,
}

/// Auto-reconnection status data
class ReconnectionStatus {
  final ReconnectionState state;
  final int attemptCount;
  final String? lastError;
  final DateTime? lastAttempt;
  final String? deviceId;
  final String? deviceAddress;

  const ReconnectionStatus({
    required this.state,
    this.attemptCount = 0,
    this.lastError,
    this.lastAttempt,
    this.deviceId,
    this.deviceAddress,
  });

  ReconnectionStatus copyWith({
    ReconnectionState? state,
    int? attemptCount,
    String? lastError,
    DateTime? lastAttempt,
    String? deviceId,
    String? deviceAddress,
  }) {
    return ReconnectionStatus(
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      deviceId: deviceId ?? this.deviceId,
      deviceAddress: deviceAddress ?? this.deviceAddress,
    );
  }
}

/// Auto-reconnection service provider
///
/// Manages automatic reconnection to last connected BLE device with:
/// - Exponential backoff retry logic (2s, 5s, 10s)
/// - Settings integration (auto_reconnect enabled/disabled)
/// - Connection state monitoring
/// - Manual vs automatic disconnect detection
///
/// Usage:
/// ```dart
/// // Access service
/// final autoReconnect = ref.read(autoReconnectServiceProvider);
/// await autoReconnect.attemptReconnection();
///
/// // Monitor status
/// final status = ref.watch(reconnectionStatusProvider);
/// if (status.state == ReconnectionState.connecting) {
///   // Show connecting UI
/// }
/// ```
final autoReconnectServiceProvider = Provider<AutoReconnectService>((ref) {
  final service = AutoReconnectService(ref);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Reconnection status provider
final reconnectionStatusProvider = StateProvider<ReconnectionStatus>((ref) {
  return const ReconnectionStatus(state: ReconnectionState.idle);
});

/// Auto-reconnect service implementation
class AutoReconnectService {
  AutoReconnectService(this._ref);

  final Ref _ref;
  Timer? _reconnectTimer;
  bool _isManualDisconnect = false;
  static const int _maxRetries = 3;
  static const List<Duration> _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  /// Check if auto-reconnect is enabled in settings
  Future<bool> isEnabled() async {
    try {
      final settingsDao = _ref.read(settingsDaoProvider);
      return await settingsDao.getAutoReconnect();
    } catch (error) {
      developer.log(
        'Error checking auto-reconnect setting',
        name: 'mushpi.auto_reconnect',
        error: error,
        level: 900,
      );
      return true; // Default to enabled
    }
  }

  /// Enable auto-reconnect
  Future<void> enable() async {
    try {
      final settingsDao = _ref.read(settingsDaoProvider);
      await settingsDao.setAutoReconnect(true);
      
      developer.log(
        'Auto-reconnect enabled',
        name: 'mushpi.auto_reconnect',
      );
      
      _updateStatus(state: ReconnectionState.idle);
    } catch (error, stackTrace) {
      developer.log(
        'Error enabling auto-reconnect',
        name: 'mushpi.auto_reconnect',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Disable auto-reconnect
  Future<void> disable() async {
    try {
      final settingsDao = _ref.read(settingsDaoProvider);
      await settingsDao.setAutoReconnect(false);
      
      // Cancel any pending reconnection
      _cancelReconnect();
      
      developer.log(
        'Auto-reconnect disabled',
        name: 'mushpi.auto_reconnect',
      );
      
      _updateStatus(state: ReconnectionState.disabled);
    } catch (error, stackTrace) {
      developer.log(
        'Error disabling auto-reconnect',
        name: 'mushpi.auto_reconnect',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Attempt reconnection to last connected device
  Future<bool> attemptReconnection() async {
    try {
      debugPrint('🔄 [AUTO-RECONNECT] Starting reconnection attempt...');
      
      // Check if auto-reconnect is enabled
      if (!await isEnabled()) {
        debugPrint('🔄 [AUTO-RECONNECT] Auto-reconnect is disabled, skipping reconnection');
        developer.log(
          'Auto-reconnect is disabled, skipping reconnection',
          name: 'mushpi.auto_reconnect',
        );
        _updateStatus(state: ReconnectionState.disabled);
        return false;
      }

      debugPrint('✅ [AUTO-RECONNECT] Auto-reconnect is enabled');

      // Get last connected device info
      final settingsDao = _ref.read(settingsDaoProvider);
      final deviceId = await settingsDao.getLastConnectedDeviceId();
      final deviceAddress = await settingsDao.getLastConnectedDeviceAddress();
      final farmId = await settingsDao.getLastConnectedFarmId();

      debugPrint('🔄 [AUTO-RECONNECT] Last connected device info:');
      debugPrint('  Device ID: $deviceId');
      debugPrint('  Device Address: $deviceAddress');
      debugPrint('  Farm ID: $farmId');

      if (deviceId == null || deviceAddress == null) {
        debugPrint('❌ [AUTO-RECONNECT] No last connected device found in settings');
        developer.log(
          'No last connected device found',
          name: 'mushpi.auto_reconnect',
          level: 900,
        );
        _updateStatus(
          state: ReconnectionState.failed,
          lastError: 'No device to reconnect to',
        );
        return false;
      }

      debugPrint('🔄 [AUTO-RECONNECT] Attempting reconnection to device: $deviceId');
      developer.log(
        'Attempting reconnection to device: $deviceId',
        name: 'mushpi.auto_reconnect',
      );

      _updateStatus(
        state: ReconnectionState.scanning,
        deviceId: deviceId,
        deviceAddress: deviceAddress,
      );

      // Start scanning for the device
      return await _scanAndConnect(deviceId, deviceAddress);
    } catch (error, stackTrace) {
      debugPrint('❌ [AUTO-RECONNECT] Error during reconnection attempt: $error');
      debugPrint('Stack trace: $stackTrace');
      developer.log(
        'Error during reconnection attempt',
        name: 'mushpi.auto_reconnect',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      
      _updateStatus(
        state: ReconnectionState.failed,
        lastError: error.toString(),
      );
      
      return false;
    }
  }

  /// Scan for and connect to specific device
  Future<bool> _scanAndConnect(String targetDeviceId, String targetAddress) async {
    try {
      debugPrint('🔍 [AUTO-RECONNECT] Starting scan for device: $targetDeviceId');
      final bleRepository = _ref.read(bleRepositoryProvider);
      
      // Check if already connected to target device
      final connectedDevice = bleRepository.connectedDevice;
      if (connectedDevice != null && 
          connectedDevice.remoteId.toString() == targetDeviceId) {
        debugPrint('✅ [AUTO-RECONNECT] Already connected to target device');
        developer.log(
          'Already connected to target device',
          name: 'mushpi.auto_reconnect',
        );
        _updateStatus(state: ReconnectionState.connected);
        return true;
      }

      // Start scanning
      debugPrint('🔍 [AUTO-RECONNECT] Starting BLE scan (10 second timeout)...');
      _updateStatus(state: ReconnectionState.scanning);
      
      BluetoothDevice? targetDevice;
      final scanCompleter = Completer<BluetoothDevice?>();
      
      final scanSubscription = bleRepository.scanResultsStream.listen(
        (results) {
          debugPrint('🔍 [AUTO-RECONNECT] Scan results: ${results.length} device(s)');
          for (final result in results) {
            debugPrint('  📱 Device: ${result.device.platformName} (${result.device.remoteId})');
            if (result.device.remoteId.toString() == targetDeviceId) {
              debugPrint('  ✅ FOUND TARGET DEVICE: ${result.device.platformName}');
              developer.log(
                'Found target device: ${result.device.platformName}',
                name: 'mushpi.auto_reconnect',
              );
              targetDevice = result.device;
              if (!scanCompleter.isCompleted) {
                scanCompleter.complete(result.device);
              }
              break;
            }
          }
        },
        onError: (error) {
          debugPrint('❌ [AUTO-RECONNECT] Scan error: $error');
          if (!scanCompleter.isCompleted) {
            scanCompleter.completeError(error);
          }
        },
      );

      // Start scan with timeout
      await bleRepository.startScan(timeout: const Duration(seconds: 10));

      // Wait for device to be found
      debugPrint('🔍 [AUTO-RECONNECT] Waiting for target device to appear...');
      targetDevice = await scanCompleter.future.timeout(
        const Duration(seconds: 11),
        onTimeout: () {
          debugPrint('⏱️ [AUTO-RECONNECT] Scan timeout - device not found');
          return null;
        },
      );

      await scanSubscription.cancel();

      if (targetDevice == null) {
        debugPrint('❌ [AUTO-RECONNECT] Target device not found during scan');
        developer.log(
          'Target device not found during scan',
          name: 'mushpi.auto_reconnect',
          level: 900,
        );
        _updateStatus(
          state: ReconnectionState.failed,
          lastError: 'Device not found',
        );
        return false;
      }

      // Attempt connection
      debugPrint('🔗 [AUTO-RECONNECT] Target device found, attempting connection...');
      _updateStatus(state: ReconnectionState.connecting);
      
      final bleOps = _ref.read(bleOperationsProvider);
      final settingsDao = _ref.read(settingsDaoProvider);
      final farmId = await settingsDao.getLastConnectedFarmId();
      
      debugPrint('🔗 [AUTO-RECONNECT] Connecting to ${targetDevice!.platformName}...');
      debugPrint('  Farm ID: $farmId');
      
      // Connect to the device
      await bleOps.connect(targetDevice!, farmId: farmId);

      debugPrint('✅ [AUTO-RECONNECT] Successfully reconnected!');
      developer.log(
        'Successfully reconnected to device',
        name: 'mushpi.auto_reconnect',
      );
      
      _updateStatus(state: ReconnectionState.connected);
      return true;
    } catch (error, stackTrace) {
      debugPrint('❌ [AUTO-RECONNECT] Error during scan and connect: $error');
      debugPrint('Stack trace: $stackTrace');
      developer.log(
        'Error during scan and connect',
        name: 'mushpi.auto_reconnect',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      
      _updateStatus(
        state: ReconnectionState.failed,
        lastError: error.toString(),
      );
      
      return false;
    }
  }

  /// Handle disconnection with retry logic
  Future<void> onDisconnected({bool isManual = false}) async {
    _isManualDisconnect = isManual;

    if (isManual) {
      developer.log(
        'Manual disconnect - skipping auto-reconnect',
        name: 'mushpi.auto_reconnect',
      );
      _cancelReconnect();
      return;
    }

    // Check if auto-reconnect is enabled
    if (!await isEnabled()) {
      developer.log(
        'Auto-reconnect disabled - skipping reconnection',
        name: 'mushpi.auto_reconnect',
      );
      return;
    }

    developer.log(
      'Unexpected disconnect - starting auto-reconnect with retry logic',
      name: 'mushpi.auto_reconnect',
    );

    // Start retry sequence
    _startRetrySequence();
  }

  /// Start retry sequence with exponential backoff
  void _startRetrySequence() {
    _cancelReconnect();
    _retryWithBackoff(0);
  }

  /// Retry connection with exponential backoff
  void _retryWithBackoff(int attemptNumber) {
    if (attemptNumber >= _maxRetries) {
      developer.log(
        'Max retry attempts ($attemptNumber) reached - giving up',
        name: 'mushpi.auto_reconnect',
        level: 900,
      );
      _updateStatus(
        state: ReconnectionState.failed,
        attemptCount: attemptNumber,
        lastError: 'Max retries exceeded',
      );
      return;
    }

    final delay = _retryDelays[attemptNumber];
    
    developer.log(
      'Scheduling reconnection attempt ${attemptNumber + 1}/$_maxRetries '
      'in ${delay.inSeconds}s',
      name: 'mushpi.auto_reconnect',
    );

    _updateStatus(
      state: ReconnectionState.idle,
      attemptCount: attemptNumber + 1,
    );

    _reconnectTimer = Timer(delay, () async {
      developer.log(
        'Starting reconnection attempt ${attemptNumber + 1}/$_maxRetries',
        name: 'mushpi.auto_reconnect',
      );

      final success = await attemptReconnection();

      if (!success && attemptNumber + 1 < _maxRetries) {
        // Schedule next retry
        _retryWithBackoff(attemptNumber + 1);
      } else if (!success) {
        developer.log(
          'All reconnection attempts failed',
          name: 'mushpi.auto_reconnect',
          level: 900,
        );
      }
    });
  }

  /// Cancel pending reconnection attempts
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Update reconnection status
  void _updateStatus({
    ReconnectionState? state,
    int? attemptCount,
    String? lastError,
    String? deviceId,
    String? deviceAddress,
  }) {
    final currentStatus = _ref.read(reconnectionStatusProvider);
    
    _ref.read(reconnectionStatusProvider.notifier).state = currentStatus.copyWith(
      state: state,
      attemptCount: attemptCount,
      lastError: lastError,
      lastAttempt: state != null ? DateTime.now() : currentStatus.lastAttempt,
      deviceId: deviceId,
      deviceAddress: deviceAddress,
    );
  }

  /// Mark disconnect as manual (to prevent auto-reconnect)
  void markManualDisconnect() {
    _isManualDisconnect = true;
  }

  /// Clear manual disconnect flag
  void clearManualDisconnect() {
    _isManualDisconnect = false;
  }

  /// Clean up resources
  void dispose() {
    developer.log(
      'Disposing auto-reconnect service',
      name: 'mushpi.auto_reconnect',
    );
    
    _cancelReconnect();
  }
}
