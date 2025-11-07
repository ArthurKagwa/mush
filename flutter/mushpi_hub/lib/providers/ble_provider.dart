// lib/providers/ble_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mushpi_hub/data/repositories/ble_repository.dart';
import 'package:mushpi_hub/core/utils/ble_serializer.dart';
import 'package:mushpi_hub/providers/database_provider.dart';
import 'dart:developer' as developer;

/// BLE Repository provider - manages the BLERepository instance
///
/// This provider creates and maintains a single instance of [BLERepository]
/// throughout the app lifecycle. The repository is disposed when the provider
/// is disposed.
///
/// Usage:
/// ```dart
/// final bleRepo = ref.watch(bleRepositoryProvider);
/// await bleRepo.connect(device);
/// ```
final bleRepositoryProvider = Provider<BLERepository>((ref) {
  developer.log(
    'Initializing BLERepository',
    name: 'mushpi.providers.ble',
  );

  final repository = BLERepository();

  ref.onDispose(() {
    developer.log(
      'Disposing BLERepository - cleaning up connections',
      name: 'mushpi.providers.ble',
    );
    repository.dispose();
  });

  return repository;
});

/// BLE scanning state provider
///
/// Manages the state of BLE device scanning including:
/// - Scan active/inactive status
/// - List of discovered devices
/// - Error handling
///
/// Usage:
/// ```dart
/// final scanState = ref.watch(bleScanStateProvider);
/// scanState.when(
///   data: (devices) => ListView(children: devices.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final bleScanStateProvider =
    StateNotifierProvider<BLEScanNotifier, AsyncValue<List<ScanResult>>>(
        (ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  return BLEScanNotifier(bleRepository);
});

/// Notifier for BLE scan state management
class BLEScanNotifier extends StateNotifier<AsyncValue<List<ScanResult>>> {
  BLEScanNotifier(this._bleRepository)
      : super(const AsyncValue.data([])) {
    _init();
  }

  final BLERepository _bleRepository;
  bool _isScanning = false;

  void _init() {
    // Listen to scan results from repository
    _bleRepository.scanResultsStream.listen(
      (results) {
        developer.log(
          'Received ${results.length} scan results',
          name: 'mushpi.providers.ble.scan',
        );
        state = AsyncValue.data(results);
      },
      onError: (error, stackTrace) {
        developer.log(
          'Scan error',
          name: 'mushpi.providers.ble.scan',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  /// Start scanning for BLE devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) {
      developer.log(
        'Scan already in progress',
        name: 'mushpi.providers.ble.scan',
      );
      return;
    }

    try {
      developer.log(
        'Starting BLE scan with ${timeout.inSeconds}s timeout',
        name: 'mushpi.providers.ble.scan',
      );
      
      state = const AsyncValue.loading();
      _isScanning = true;
      
      await _bleRepository.startScan(timeout: timeout);
      
      _isScanning = false;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to start scan',
        name: 'mushpi.providers.ble.scan',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      
      _isScanning = false;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScan() async {
    if (!_isScanning) {
      return;
    }

    try {
      developer.log(
        'Stopping BLE scan',
        name: 'mushpi.providers.ble.scan',
      );
      
      await _bleRepository.stopScan();
      _isScanning = false;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to stop scan',
        name: 'mushpi.providers.ble.scan',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  bool get isScanning => _isScanning;
}

/// BLE connection state provider
///
/// Tracks the connection state of the currently connected BLE device.
///
/// Usage:
/// ```dart
/// final connectionState = ref.watch(bleConnectionStateProvider);
/// if (connectionState == BluetoothConnectionState.connected) {
///   // Device is connected
/// }
/// ```
final bleConnectionStateProvider =
    StreamProvider<BluetoothConnectionState>((ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  return bleRepository.connectionStateStream;
});

/// Current connected device provider
///
/// Provides the currently connected BLE device, or null if not connected.
///
/// Usage:
/// ```dart
/// final device = ref.watch(connectedDeviceProvider);
/// if (device != null) {
///   Text('Connected to: ${device.platformName}');
/// }
/// ```
final connectedDeviceProvider = Provider<BluetoothDevice?>((ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  return bleRepository.connectedDevice;
});

/// Environmental data stream provider
///
/// Provides real-time environmental readings from the connected BLE device.
/// Data includes CO2, temperature, humidity, and light levels.
///
/// Usage:
/// ```dart
/// final envData = ref.watch(environmentalDataStreamProvider);
/// envData.when(
///   data: (reading) => Text('Temp: ${reading.temperatureC}°C'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final environmentalDataStreamProvider =
    StreamProvider<EnvironmentalReading>((ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  return bleRepository.environmentalDataStream;
});

/// Status flags stream provider
///
/// Provides real-time status flags from the connected BLE device.
/// Flags indicate system state, alerts, and operational status.
///
/// Usage:
/// ```dart
/// final statusFlags = ref.watch(statusFlagsStreamProvider);
/// statusFlags.when(
///   data: (flags) => Text('Status: 0x${flags.toRadixString(16)}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
final statusFlagsStreamProvider = StreamProvider<int>((ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  return bleRepository.statusFlagsStream;
});

/// BLE operations provider - provides methods for BLE operations
///
/// This provider offers convenient methods for common BLE operations:
/// - Connect/disconnect to devices
/// - Read/write characteristics
/// - Check Bluetooth availability
///
/// Usage:
/// ```dart
/// final bleOps = ref.read(bleOperationsProvider);
/// await bleOps.connect(device, farmId);
/// ```
final bleOperationsProvider = Provider<BLEOperations>((ref) {
  final bleRepository = ref.watch(bleRepositoryProvider);
  final devicesDao = ref.watch(devicesDaoProvider);
  final readingsDao = ref.watch(readingsDaoProvider);
  final settingsDao = ref.watch(settingsDaoProvider);
  
  return BLEOperations(
    repository: bleRepository,
    devicesDao: devicesDao,
    readingsDao: readingsDao,
    settingsDao: settingsDao,
  );
});

/// BLE Operations wrapper class
///
/// Provides high-level BLE operations with database integration.
class BLEOperations {
  BLEOperations({
    required this.repository,
    required this.devicesDao,
    required this.readingsDao,
    required this.settingsDao,
  });

  final BLERepository repository;
  final dynamic devicesDao; // DevicesDao
  final dynamic readingsDao; // ReadingsDao
  final dynamic settingsDao; // SettingsDao

  /// Check if Bluetooth is available on this device
  Future<bool> isBluetoothAvailable() async {
    try {
      return await repository.isBluetoothAvailable();
    } catch (error, stackTrace) {
      developer.log(
        'Error checking Bluetooth availability',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    try {
      await repository.turnOnBluetooth();
    } catch (error, stackTrace) {
      developer.log(
        'Error turning on Bluetooth',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Connect to a BLE device
  ///
  /// Connects to the specified device and updates the device record
  /// in the database with the connection timestamp.
  ///
  /// [device] - The BLE device to connect to
  /// [farmId] - Optional farm ID to associate with this device
  Future<void> connect(BluetoothDevice device, {String? farmId}) async {
    try {
      debugPrint('🔗 [BLEOperations] Connecting to device: ${device.platformName} (${device.remoteId})');
      developer.log(
        'Connecting to device: ${device.platformName} (${device.remoteId})',
        name: 'mushpi.providers.ble.ops',
      );

      // IMPORTANT: Save device info BEFORE attempting connection
      // This ensures auto-reconnect will work even if connection fails
      final deviceId = device.remoteId.toString();
      final deviceAddress = device.remoteId.toString();
      
      debugPrint('💾 [BLEOperations] Saving device info for auto-reconnect BEFORE connection...');
      try {
        await settingsDao.setLastConnectedDevice(
          deviceId: deviceId,
          address: deviceAddress,
          farmId: farmId,
        );
        debugPrint('✅ [BLEOperations] Device info saved for auto-reconnect');
      } catch (e) {
        debugPrint('⚠️ [BLEOperations] Failed to save device info (non-critical): $e');
        // Non-critical error, continue with connection
      }

      // Connect via repository
      debugPrint('🔗 [BLEOperations] Calling repository.connect()...');
      await repository.connect(device);
      debugPrint('✅ [BLEOperations] Repository connected successfully');

      // Update device in database
      final exists = await devicesDao.deviceExists(deviceId);

      debugPrint('📝 [BLEOperations] Device exists in DB: $exists');

      if (exists) {
        // Update last connected timestamp
        await devicesDao.updateLastConnected(deviceId);
        debugPrint('✅ [BLEOperations] Updated lastConnected timestamp');
        
        // Link to farm if farmId provided
        if (farmId != null) {
          await devicesDao.linkDeviceToFarm(deviceId, farmId);
          debugPrint('✅ [BLEOperations] Linked device to farm: $farmId');
        }
      } else {
        // Insert new device record
        await devicesDao.insertDevice(
          deviceId: deviceId,
          name: device.platformName,
          address: device.remoteId.toString(),
          farmId: farmId,
        );
        debugPrint('✅ [BLEOperations] Inserted new device record');
      }

      debugPrint('✅ [BLEOperations] Successfully connected to device and updated database');
      developer.log(
        'Successfully connected to device',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ [BLEOperations] Failed to connect to device: $error');
      developer.log(
        'Failed to connect to device',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Disconnect from the current BLE device
  Future<void> disconnect() async {
    try {
      developer.log(
        'Disconnecting from device',
        name: 'mushpi.providers.ble.ops',
      );

      await repository.disconnect();

      developer.log(
        'Successfully disconnected',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error during disconnect',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
      rethrow;
    }
  }

  /// Read environmental data from the device
  Future<EnvironmentalReading?> readEnvironmentalData() async {
    try {
      return await repository.readEnvironmentalData();
    } catch (error, stackTrace) {
      developer.log(
        'Error reading environmental data',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Read control targets from the device
  Future<ControlTargetsData?> readControlTargets() async {
    try {
      return await repository.readControlTargets();
    } catch (error, stackTrace) {
      developer.log(
        'Error reading control targets',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Write control targets to the device
  Future<void> writeControlTargets(ControlTargetsData data) async {
    try {
      await repository.writeControlTargets(data);
      
      developer.log(
        'Successfully wrote control targets',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error writing control targets',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read stage state from the device
  Future<StageStateData?> readStageState() async {
    try {
      return await repository.readStageState();
    } catch (error, stackTrace) {
      developer.log(
        'Error reading stage state',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Write stage state to the device
  Future<void> writeStageState(StageStateData data) async {
    try {
      await repository.writeStageState(data);
      
      developer.log(
        'Successfully wrote stage state',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error writing stage state',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Write override bits to the device
  Future<void> writeOverrideBits(int bits) async {
    try {
      await repository.writeOverrideBits(bits);
      
      developer.log(
        'Successfully wrote override bits: 0x${bits.toRadixString(16)}',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error writing override bits',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read status flags from the device
  Future<int?> readStatusFlags() async {
    try {
      return await repository.readStatusFlags();
    } catch (error, stackTrace) {
      developer.log(
        'Error reading status flags',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Save environmental reading to database
  ///
  /// Stores the reading in the database associated with the farm.
  Future<void> saveReading(EnvironmentalReading reading, String farmId) async {
    try {
      await readingsDao.insertReading(
        farmId: farmId,
        timestamp: reading.timestamp,
        co2Ppm: reading.co2Ppm,
        temperatureC: reading.temperatureC,
        relativeHumidity: reading.relativeHumidity,
        lightRaw: reading.lightRaw,
      );

      developer.log(
        'Saved environmental reading for farm $farmId',
        name: 'mushpi.providers.ble.ops',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error saving reading to database',
        name: 'mushpi.providers.ble.ops',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }
}
