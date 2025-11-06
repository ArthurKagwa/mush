import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/ble_constants.dart';
import '../../core/utils/ble_serializer.dart';

/// BLE Repository for MushPi Device Communication
///
/// Handles all Bluetooth Low Energy operations including:
/// - Device scanning and discovery
/// - Connection management with auto-reconnect
/// - Service and characteristic discovery
/// - Read/write operations for all 5 characteristics
/// - Notification subscriptions
/// - Error handling and recovery
class BLERepository {
  BLERepository();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _envMeasurementsChar;
  BluetoothCharacteristic? _controlTargetsChar;
  BluetoothCharacteristic? _stageStateChar;
  BluetoothCharacteristic? _overrideBitsChar;
  BluetoothCharacteristic? _statusFlagsChar;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _envNotificationSubscription;
  StreamSubscription<List<int>>? _statusNotificationSubscription;

  // Stream controllers for data
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _environmentalDataController =
      StreamController<EnvironmentalReading>.broadcast();
  final _statusFlagsController = StreamController<int>.broadcast();
  final _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();

  // Public streams
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<EnvironmentalReading> get environmentalDataStream =>
      _environmentalDataController.stream;
  Stream<int> get statusFlagsStream => _statusFlagsController.stream;
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;

  // Current connection state
  BluetoothConnectionState _currentConnectionState =
      BluetoothConnectionState.disconnected;
  BluetoothConnectionState get connectionState => _currentConnectionState;
  bool get isConnected =>
      _currentConnectionState == BluetoothConnectionState.connected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      // Check adapter availability
      if (await FlutterBluePlus.isSupported == false) {
        developer.log(
          'Bluetooth not supported on this device',
          name: 'BLERepository',
          level: 900,
        );
        return false;
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking Bluetooth availability',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      developer.log(
        'Failed to turn on Bluetooth',
        name: 'BLERepository',
        error: e,
        level: 900,
      );
      rethrow;
    }
  }

  /// Scan for MushPi devices
  ///
  /// Scans for ALL BLE devices and filters for MushPi devices by:
  /// 1. Service UUID (12345678-1234-5678-1234-56789abcdef0)
  /// 2. Device name prefix ("MushPi-")
  ///
  /// Uses dual detection for maximum compatibility with different BLE adapters.
  /// 
  /// DEBUG MODE: Set to true to show ALL devices (even without names/UUIDs)
  static const bool _debugShowAllDevices = false; // Set to true only for debugging
  
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Check Bluetooth availability
      if (!await isBluetoothAvailable()) {
        throw BLEException('Bluetooth is not available or enabled');
      }

      // Stop any existing scan
      await stopScan();

      developer.log(
        'Starting BLE scan for MushPi devices (timeout: ${timeout.inSeconds}s)',
        name: 'BLERepository',
      );

      final scanResults = <String, ScanResult>{};

      // Listen to scan results
      final scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          developer.log(
            'Scan update: ${results.length} total devices found',
            name: 'BLERepository',
          );
          
          // Filter for MushPi devices using dual detection
          for (final result in results) {
            final deviceId = result.device.remoteId.toString();
            final deviceName = result.device.platformName;
            final serviceUuids = result.advertisementData.serviceUuids
                .map((u) => u.toString())
                .toList();
            
            // Log EVERY device for debugging
            developer.log(
              'Device found: ${deviceName.isEmpty ? "Unknown" : deviceName} '
              '(${result.device.remoteId}) '
              'RSSI: ${result.rssi} '
              'UUIDs: ${serviceUuids.isEmpty ? "none" : serviceUuids.join(", ")}',
              name: 'BLERepository.AllDevices',
            );
            
            // Detection Strategy 1: Check device name prefix
            final hasValidName = deviceName.isNotEmpty && 
                                 deviceName.startsWith(BLEConstants.deviceNamePrefix);
            
            // Detection Strategy 1b: Check for case-insensitive "mushpi" or "pi" in name
            final nameContainsMushPi = deviceName.toLowerCase().contains('mushpi');
            final nameContainsPi = deviceName.toLowerCase().contains('pi') && 
                                   deviceName.length < 20; // Avoid matching "PixelBuds" etc.
            
            // Detection Strategy 2: Check for MushPi service UUID
            final hasServiceUuid = result.advertisementData.serviceUuids
                .any((uuid) => uuid.toString() == BLEConstants.serviceUUID);
            
            // Accept device if ANY condition is true OR if debug mode is enabled
            final shouldInclude = hasValidName || nameContainsMushPi || nameContainsPi || 
                                  hasServiceUuid || _debugShowAllDevices;
            
            if (shouldInclude) {
              scanResults[deviceId] = result;
              
              if (_debugShowAllDevices && !hasValidName && !nameContainsMushPi && 
                  !nameContainsPi && !hasServiceUuid) {
                developer.log(
                  '🔧 DEBUG: Including device: ${deviceName.isEmpty ? "Unknown" : deviceName} '
                  '(${result.device.remoteId}) RSSI: ${result.rssi}',
                  name: 'BLERepository',
                );
              } else {
                developer.log(
                  '✅ MATCHED MushPi device: ${deviceName.isEmpty ? "Unknown" : deviceName} '
                  '(${result.device.remoteId}) '
                  '[Prefix: $hasValidName, Contains: $nameContainsMushPi/$nameContainsPi, UUID: $hasServiceUuid, RSSI: ${result.rssi}]',
                  name: 'BLERepository',
                );
              }
            } else {
              developer.log(
                '❌ NOT MushPi: ${deviceName.isEmpty ? "Unknown" : deviceName} '
                '(Checks: prefix=$hasValidName, mushpi=$nameContainsMushPi, pi=$nameContainsPi, uuid=$hasServiceUuid)',
                name: 'BLERepository',
              );
            }
          }

          // Emit current results
          _scanResultsController.add(scanResults.values.toList());
        },
        onError: (e) {
          developer.log(
            'Scan results error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );

      // Start scan WITHOUT service UUID filter for maximum compatibility
      // We'll filter in software instead
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Wait for scan to complete
      await Future.delayed(timeout);

      // Clean up
      await scanSubscription.cancel();
      await stopScan();

      developer.log(
        'Scan completed. Found ${scanResults.length} MushPi device(s)',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error during BLE scan',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      if (await FlutterBluePlus.isScanning.first) {
        await FlutterBluePlus.stopScan();
        developer.log('BLE scan stopped', name: 'BLERepository');
      }
    } catch (e) {
      developer.log(
        'Error stopping scan',
        name: 'BLERepository',
        error: e,
        level: 900,
      );
    }
  }

  /// Connect to a MushPi device
  ///
  /// Establishes connection and discovers services/characteristics.
  /// Automatically subscribes to environmental and status notifications.
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      developer.log(
        'Connecting to ${device.platformName} (${device.remoteId})',
        name: 'BLERepository',
      );

      // Disconnect from any existing device
      await disconnect();

      _connectedDevice = device;

      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen(
        (state) {
          _currentConnectionState = state;
          _connectionStateController.add(state);

          developer.log(
            'Connection state changed: $state',
            name: 'BLERepository',
          );

          // Handle disconnection
          if (state == BluetoothConnectionState.disconnected) {
            _handleDisconnection();
          }
        },
        onError: (e) {
          developer.log(
            'Connection state error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );

      // Connect to device
      await device.connect(timeout: timeout);

      // Discover services
      await _discoverServices();

      // Subscribe to notifications
      await _subscribeToNotifications();

      developer.log(
        'Successfully connected to ${device.platformName}',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Connection failed',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );

      // Clean up on failure
      await disconnect();
      rethrow;
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) {
      throw BLEException('No device connected');
    }

    try {
      developer.log('Discovering services...', name: 'BLERepository');

      final services = await _connectedDevice!.discoverServices();

      // Find MushPi service
      final mushPiService = services.firstWhere(
        (service) => service.uuid.toString() == BLEConstants.serviceUUID,
        orElse: () => throw BLEException('MushPi service not found'),
      );

      developer.log(
        'Found MushPi service with ${mushPiService.characteristics.length} characteristics',
        name: 'BLERepository',
      );

      // Find all characteristics
      for (final char in mushPiService.characteristics) {
        final uuid = char.uuid.toString();
        developer.log(
          'Found characteristic: $uuid',
          name: 'BLERepository',
        );

        switch (uuid) {
          case BLEConstants.envMeasurementsUUID:
            _envMeasurementsChar = char;
            break;
          case BLEConstants.controlTargetsUUID:
            _controlTargetsChar = char;
            break;
          case BLEConstants.stageStateUUID:
            _stageStateChar = char;
            break;
          case BLEConstants.overrideBitsUUID:
            _overrideBitsChar = char;
            break;
          case BLEConstants.statusFlagsUUID:
            _statusFlagsChar = char;
            break;
        }
      }

      // Verify all required characteristics found
      if (_envMeasurementsChar == null ||
          _controlTargetsChar == null ||
          _stageStateChar == null ||
          _overrideBitsChar == null ||
          _statusFlagsChar == null) {
        throw BLEException('Not all required characteristics found');
      }

      developer.log('All characteristics discovered', name: 'BLERepository');
    } catch (e, stackTrace) {
      developer.log(
        'Service discovery failed',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Subscribe to environmental and status notifications
  Future<void> _subscribeToNotifications() async {
    try {
      developer.log('Subscribing to notifications...', name: 'BLERepository');

      // Subscribe to environmental measurements
      await _envMeasurementsChar!.setNotifyValue(true);
      _envNotificationSubscription =
          _envMeasurementsChar!.lastValueStream.listen(
        (data) {
          try {
            final reading = BLEDataSerializer.parseEnvironmentalData(data);
            _environmentalDataController.add(reading);
            developer.log(
              'Environmental update: $reading',
              name: 'BLERepository',
            );
          } catch (e) {
            developer.log(
              'Failed to parse environmental data',
              name: 'BLERepository',
              error: e,
              level: 900,
            );
          }
        },
        onError: (e) {
          developer.log(
            'Environmental notification error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );

      // Subscribe to status flags
      await _statusFlagsChar!.setNotifyValue(true);
      _statusNotificationSubscription = _statusFlagsChar!.lastValueStream.listen(
        (data) {
          try {
            final flags = BLEDataSerializer.parseStatusFlags(data);
            _statusFlagsController.add(flags);
            developer.log(
              'Status flags update: 0x${flags.toRadixString(16)}',
              name: 'BLERepository',
            );
          } catch (e) {
            developer.log(
              'Failed to parse status flags',
              name: 'BLERepository',
              error: e,
              level: 900,
            );
          }
        },
        onError: (e) {
          developer.log(
            'Status notification error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );

      developer.log(
        'Successfully subscribed to notifications',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to subscribe to notifications',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read environmental measurements
  Future<EnvironmentalReading> readEnvironmentalData() async {
    _ensureConnected();
    _ensureCharacteristic(_envMeasurementsChar, 'Environmental measurements');

    try {
      final data = await _envMeasurementsChar!.read();
      return BLEDataSerializer.parseEnvironmentalData(data);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read environmental data',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read control targets
  Future<ControlTargetsData> readControlTargets() async {
    _ensureConnected();
    _ensureCharacteristic(_controlTargetsChar, 'Control targets');

    try {
      final data = await _controlTargetsChar!.read();
      return BLEDataSerializer.parseControlTargets(data);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read control targets',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Write control targets
  Future<void> writeControlTargets(ControlTargetsData targets) async {
    _ensureConnected();
    _ensureCharacteristic(_controlTargetsChar, 'Control targets');

    // Validate targets
    if (!targets.isValid()) {
      throw BLEException('Invalid control targets: out of range');
    }

    try {
      final data = BLEDataSerializer.serializeControlTargets(targets);
      await _controlTargetsChar!.write(
        data,
        withoutResponse: false,
      );
      developer.log(
        'Control targets written: $targets',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to write control targets',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read stage state
  Future<StageStateData> readStageState() async {
    _ensureConnected();
    _ensureCharacteristic(_stageStateChar, 'Stage state');

    try {
      final data = await _stageStateChar!.read();
      return BLEDataSerializer.parseStageState(data);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read stage state',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Write stage state
  Future<void> writeStageState(StageStateData state) async {
    _ensureConnected();
    _ensureCharacteristic(_stageStateChar, 'Stage state');

    try {
      final data = BLEDataSerializer.serializeStageState(state);
      await _stageStateChar!.write(
        data,
        withoutResponse: false,
      );
      developer.log(
        'Stage state written: $state',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to write stage state',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Write override bits
  Future<void> writeOverrideBits(int bits) async {
    _ensureConnected();
    _ensureCharacteristic(_overrideBitsChar, 'Override bits');

    try {
      final data = BLEDataSerializer.serializeOverrideBits(bits);
      await _overrideBitsChar!.write(
        data,
        withoutResponse: true, // Write-only characteristic
      );
      developer.log(
        'Override bits written: 0x${bits.toRadixString(16)}',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to write override bits',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Read status flags
  Future<int> readStatusFlags() async {
    _ensureConnected();
    _ensureCharacteristic(_statusFlagsChar, 'Status flags');

    try {
      final data = await _statusFlagsChar!.read();
      return BLEDataSerializer.parseStatusFlags(data);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to read status flags',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      developer.log('Disconnecting from device', name: 'BLERepository');

      // Cancel subscriptions
      await _envNotificationSubscription?.cancel();
      await _statusNotificationSubscription?.cancel();
      await _connectionSubscription?.cancel();

      // Disconnect device
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _handleDisconnection();

      developer.log('Disconnected successfully', name: 'BLERepository');
    } catch (e, stackTrace) {
      developer.log(
        'Error during disconnection',
        name: 'BLERepository',
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  /// Handle disconnection cleanup
  void _handleDisconnection() {
    _connectedDevice = null;
    _envMeasurementsChar = null;
    _controlTargetsChar = null;
    _stageStateChar = null;
    _overrideBitsChar = null;
    _statusFlagsChar = null;
    _currentConnectionState = BluetoothConnectionState.disconnected;
  }

  /// Ensure device is connected
  void _ensureConnected() {
    if (!isConnected) {
      throw BLEException('Device not connected');
    }
  }

  /// Ensure characteristic is available
  void _ensureCharacteristic(
    BluetoothCharacteristic? char,
    String name,
  ) {
    if (char == null) {
      throw BLEException('$name characteristic not available');
    }
  }

  /// Dispose resources
  void dispose() {
    developer.log('Disposing BLE repository', name: 'BLERepository');

    _envNotificationSubscription?.cancel();
    _statusNotificationSubscription?.cancel();
    _connectionSubscription?.cancel();

    _connectionStateController.close();
    _environmentalDataController.close();
    _statusFlagsController.close();
    _scanResultsController.close();
  }
}

/// BLE-specific exception
class BLEException implements Exception {
  final String message;

  BLEException(this.message);

  @override
  String toString() => 'BLEException: $message';
}
