import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
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
  bool _hasEstablishedConnection = false;

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
      debugPrint('🔵 [BLE] Checking Bluetooth availability...');
      
      // Check adapter availability
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('❌ [BLE] Bluetooth not supported on this device');
        developer.log(
          'Bluetooth not supported on this device',
          name: 'BLERepository',
          level: 900,
        );
        return false;
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      debugPrint('🔵 [BLE] Adapter state: $adapterState');
      final isOn = adapterState == BluetoothAdapterState.on;
      debugPrint(isOn ? '✅ [BLE] Bluetooth is ON' : '❌ [BLE] Bluetooth is OFF');
      return isOn;
    } catch (e, stackTrace) {
      debugPrint('❌ [BLE] Error checking Bluetooth availability: $e');
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
      debugPrint('🔵 [BLE] Attempting to turn on Bluetooth...');
      await FlutterBluePlus.turnOn();
      debugPrint('✅ [BLE] Bluetooth turned on successfully');
    } catch (e) {
      debugPrint('❌ [BLE] Failed to turn on Bluetooth: $e');
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
      debugPrint('🔍 [BLE SCAN] ============ STARTING SCAN ============');
      
      // Check Bluetooth availability
      if (!await isBluetoothAvailable()) {
        throw BLEException('Bluetooth is not available or enabled');
      }

      // Stop any existing scan
      await stopScan();

      debugPrint('🔍 [BLE SCAN] Timeout: ${timeout.inSeconds}s');
      developer.log(
        'Starting BLE scan for MushPi devices (timeout: ${timeout.inSeconds}s)',
        name: 'BLERepository',
      );

      final scanResults = <String, ScanResult>{};

      // Listen to scan results
      final scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          debugPrint('🔍 [BLE SCAN] Scan update: ${results.length} total devices found');
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
            debugPrint('📱 [BLE SCAN] Device: ${deviceName.isEmpty ? "Unknown" : deviceName} '
              '($deviceId) RSSI: ${result.rssi}dBm UUIDs: ${serviceUuids.isEmpty ? "none" : serviceUuids.length}');
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
                debugPrint('🔧 [BLE SCAN] DEBUG: Including $deviceName ($deviceId) RSSI: ${result.rssi}dBm');
                developer.log(
                  '🔧 DEBUG: Including device: ${deviceName.isEmpty ? "Unknown" : deviceName} '
                  '(${result.device.remoteId}) RSSI: ${result.rssi}',
                  name: 'BLERepository',
                );
              } else {
                debugPrint('✅ [BLE SCAN] MATCHED MushPi: $deviceName ($deviceId) '
                  '[Name:$hasValidName, MushPi:$nameContainsMushPi, Pi:$nameContainsPi, UUID:$hasServiceUuid] RSSI:${result.rssi}dBm');
                developer.log(
                  '✅ MATCHED MushPi device: ${deviceName.isEmpty ? "Unknown" : deviceName} '
                  '(${result.device.remoteId}) '
                  '[Prefix: $hasValidName, Contains: $nameContainsMushPi/$nameContainsPi, UUID: $hasServiceUuid, RSSI: ${result.rssi}]',
                  name: 'BLERepository',
                );
              }
            } else {
              debugPrint('❌ [BLE SCAN] NOT MushPi: $deviceName '
                '(prefix=$hasValidName, mushpi=$nameContainsMushPi, pi=$nameContainsPi, uuid=$hasServiceUuid)');
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
      debugPrint('🔍 [BLE SCAN] Starting FlutterBluePlus.startScan()...');
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
      debugPrint('🔍 [BLE SCAN] Scan started, waiting ${timeout.inSeconds}s for results...');

      // Wait for scan to complete
      await Future.delayed(timeout);

      // Clean up
      debugPrint('🔍 [BLE SCAN] Timeout reached, stopping scan...');
      await scanSubscription.cancel();
      await stopScan();

      debugPrint('✅ [BLE SCAN] ============ SCAN COMPLETE ============');
      debugPrint('✅ [BLE SCAN] Found ${scanResults.length} MushPi device(s)');
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
        debugPrint('🛑 [BLE SCAN] Stopping scan...');
        await FlutterBluePlus.stopScan();
        debugPrint('✅ [BLE SCAN] Scan stopped');
        developer.log('BLE scan stopped', name: 'BLERepository');
      }
    } catch (e) {
      debugPrint('❌ [BLE SCAN] Error stopping scan: $e');
      developer.log(
        'Error stopping scan',
        name: 'BLERepository',
        error: e,
        level: 900,
      );
    }
  }

  /// Remove existing bond/pairing if present
  ///
  /// This is important because the Raspberry Pi is configured with "no bonding"
  /// but Android may have cached a bond from a previous connection attempt.
  Future<void> _removeBondIfExists(BluetoothDevice device) async {
    try {
      // Check current bond state
      final bondState = await device.bondState.first;
      debugPrint('🔐 [BLERepository] Current bond state: $bondState');
      
      if (bondState == BluetoothBondState.bonded) {
        debugPrint('🔐 [BLERepository] Device is bonded - attempting to remove bond...');
        developer.log(
          'Removing existing bond to prevent pairing conflicts',
          name: 'BLERepository',
        );
        
        try {
          await device.removeBond();
          debugPrint('✅ [BLERepository] Bond removed successfully');
          
          // Wait a moment for bond removal to complete
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('⚠️ [BLERepository] Could not remove bond: $e');
          // Non-critical, continue with connection
        }
      } else {
        debugPrint('✅ [BLERepository] No existing bond - ready for bondless connection');
      }
    } catch (e) {
      debugPrint('⚠️ [BLERepository] Error checking bond state (non-critical): $e');
      // Non-critical, continue with connection
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
      debugPrint('🔗 [BLERepository] Connecting to ${device.platformName} (${device.remoteId})');
      developer.log(
        'Connecting to ${device.platformName} (${device.remoteId})',
        name: 'BLERepository',
      );

      // Disconnect from any existing device
      await disconnect();

      // Remove any existing bond to ensure bondless connection
      await _removeBondIfExists(device);

      _connectedDevice = device;
      _hasEstablishedConnection = false;

      debugPrint('🔗 [BLERepository] Setting up connection state listener...');
      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen(
        (state) {
          final previousState = _currentConnectionState;
          _currentConnectionState = state;
          _connectionStateController.add(state);

          debugPrint('🔄 [BLERepository] Connection state changed: $state');
          developer.log(
            'Connection state changed: $state',
            name: 'BLERepository',
          );

          // Handle disconnection
          if (state == BluetoothConnectionState.disconnected) {
            if (previousState == BluetoothConnectionState.connected ||
                _hasEstablishedConnection) {
              debugPrint('🔌 [BLERepository] Handling disconnection...');
              _handleDisconnection();
            } else {
              debugPrint(
                'ℹ️ [BLERepository] Disconnected event before connection established, '
                'deferring cleanup',
              );
            }
          } else if (state == BluetoothConnectionState.connected) {
            _hasEstablishedConnection = true;
          }
        },
        onError: (e) {
          debugPrint('❌ [BLERepository] Connection state error: $e');
          developer.log(
            'Connection state error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );

      // Monitor bond state changes (Android only)
      // This helps us understand if bonding/pairing is causing issues
      try {
        debugPrint('🔗 [BLERepository] Setting up bond state listener...');
        device.bondState.listen(
          (bondState) {
            debugPrint('🔐 [BLERepository] Bond state changed: $bondState');
            developer.log(
              'Bond state changed: $bondState',
              name: 'BLERepository',
            );
            
            // Log bond state for debugging
            switch (bondState) {
              case BluetoothBondState.none:
                debugPrint('   No bonding - this is expected for MushPi devices');
                break;
              case BluetoothBondState.bonding:
                debugPrint('   ⚠️ Bonding in progress - this may cause connection issues');
                break;
              case BluetoothBondState.bonded:
                debugPrint('   ✅ Device bonded successfully');
                break;
            }
          },
          onError: (e) {
            debugPrint('⚠️ [BLERepository] Bond state listener error (non-critical): $e');
            // Non-critical, bond state monitoring is optional
          },
        );
      } catch (e) {
        debugPrint('⚠️ [BLERepository] Could not setup bond state listener (non-critical): $e');
        // Non-critical, continue without bond state monitoring
      }

      // Connect to device
      debugPrint('🔗 [BLERepository] Calling device.connect()...');
      debugPrint('🔧 [BLERepository] Connection settings: autoConnect=false, mtu=512');
      
      // Note: We use autoConnect=false for direct connection
      // The Raspberry Pi is configured with "no bonding" so we don't want Android to initiate pairing
      await device.connect(
        timeout: timeout,
        autoConnect: false, // Use direct connection, not auto-connect
        mtu: 512, // Request MTU upfront to avoid separate negotiation
      );
      debugPrint('✅ [BLERepository] Device.connect() completed');

      // Wait for connection to stabilize
      // Extended from 2s to 5s to handle any bonding attempts gracefully
      debugPrint('⏳ [BLERepository] Waiting for connection to stabilize (5s)...');
      debugPrint('   This allows time for any bonding/pairing attempts to complete or timeout');
      await Future.delayed(const Duration(seconds: 5));
      
      // Verify device is still connected after stabilization
      if (_connectedDevice == null) {
        debugPrint('❌ [BLERepository] Device reference lost during stabilization period');
        throw BLEException('Device disconnected unexpectedly after connection');
      }
      
      final connectionState = await device.connectionState.first;
      debugPrint('🔍 [BLERepository] Connection state after stabilization: $connectionState');
      
      if (connectionState != BluetoothConnectionState.connected) {
        debugPrint('❌ [BLERepository] Device not in connected state: $connectionState');
        throw BLEException('Device not connected (state: $connectionState)');
      }
      
      debugPrint('✅ [BLERepository] Connection stable and verified');
      
      // MTU is already requested during connect(), but verify it was successful
      try {
        debugPrint('📡 [BLERepository] Verifying MTU negotiation...');
        final mtu = await device.mtu.first;
        debugPrint('✅ [BLERepository] MTU confirmed: $mtu bytes');
      } catch (e) {
        debugPrint('⚠️ [BLERepository] Could not verify MTU (not critical): $e');
        // Non-critical, continue anyway
      }

      // Discover services
      debugPrint('🔍 [BLERepository] Discovering services...');
      await _discoverServices();
      debugPrint('✅ [BLERepository] Services discovered');

      // Subscribe to notifications
      debugPrint('🔔 [BLERepository] Subscribing to notifications...');
      await _subscribeToNotifications();
      debugPrint('✅ [BLERepository] Notification subscription completed');
      debugPrint('');
      debugPrint('🎉 [BLERepository] ========================================');
      debugPrint('🎉 [BLERepository] CONNECTION FULLY ESTABLISHED');
      debugPrint('🎉 [BLERepository] Device: ${device.platformName}');
      debugPrint('🎉 [BLERepository] Waiting for BLE notifications from Pi...');
      debugPrint('🎉 [BLERepository] ========================================');
      debugPrint('');

      debugPrint('✅ [BLERepository] Successfully connected to ${device.platformName}');
      developer.log(
        'Successfully connected to ${device.platformName}',
        name: 'BLERepository',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [BLERepository] Connection failed: $e');
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
      debugPrint('🔍 [BLE DISCOVER] Discovering services...');
      developer.log('Discovering services...', name: 'BLERepository');

      final services = await _connectedDevice!.discoverServices();
      debugPrint('🔍 [BLE DISCOVER] Found ${services.length} service(s)');
      
      for (final service in services) {
        debugPrint('  📋 [BLE DISCOVER] Service UUID: ${service.uuid}');
      }

      // Find MushPi service
      debugPrint('🔍 [BLE DISCOVER] Looking for MushPi service: ${BLEConstants.serviceUUID}');
      final mushPiService = services.firstWhere(
        (service) => service.uuid.toString() == BLEConstants.serviceUUID,
        orElse: () => throw BLEException('MushPi service not found'),
      );

      debugPrint('✅ [BLE DISCOVER] Found MushPi service with ${mushPiService.characteristics.length} characteristic(s)');
      developer.log(
        'Found MushPi service with ${mushPiService.characteristics.length} characteristics',
        name: 'BLERepository',
      );

      // Find all characteristics
      for (final char in mushPiService.characteristics) {
        final uuid = char.uuid.toString();
        final properties = [];
        if (char.properties.read) properties.add('Read');
        if (char.properties.write) properties.add('Write');
        if (char.properties.notify) properties.add('Notify');
        
        debugPrint('  📋 [BLE DISCOVER] Characteristic: $uuid [${properties.join(", ")}]');
        developer.log(
          'Found characteristic: $uuid',
          name: 'BLERepository',
        );

        switch (uuid) {
          case BLEConstants.envMeasurementsUUID:
            _envMeasurementsChar = char;
            debugPrint('    ✅ [BLE DISCOVER] Mapped to: Environmental Measurements');
            break;
          case BLEConstants.controlTargetsUUID:
            _controlTargetsChar = char;
            debugPrint('    ✅ [BLE DISCOVER] Mapped to: Control Targets');
            break;
          case BLEConstants.stageStateUUID:
            _stageStateChar = char;
            debugPrint('    ✅ [BLE DISCOVER] Mapped to: Stage State');
            break;
          case BLEConstants.overrideBitsUUID:
            _overrideBitsChar = char;
            debugPrint('    ✅ [BLE DISCOVER] Mapped to: Override Bits');
            break;
          case BLEConstants.statusFlagsUUID:
            _statusFlagsChar = char;
            debugPrint('    ✅ [BLE DISCOVER] Mapped to: Status Flags');
            break;
          default:
            debugPrint('    ⚠️ [BLE DISCOVER] Unknown characteristic');
        }
      }

      // Verify all required characteristics found
      if (_envMeasurementsChar == null ||
          _controlTargetsChar == null ||
          _stageStateChar == null ||
          _overrideBitsChar == null ||
          _statusFlagsChar == null) {
        debugPrint('❌ [BLE DISCOVER] Missing characteristics:');
        if (_envMeasurementsChar == null) debugPrint('  ❌ Environmental Measurements');
        if (_controlTargetsChar == null) debugPrint('  ❌ Control Targets');
        if (_stageStateChar == null) debugPrint('  ❌ Stage State');
        if (_overrideBitsChar == null) debugPrint('  ❌ Override Bits');
        if (_statusFlagsChar == null) debugPrint('  ❌ Status Flags');
        throw BLEException('Not all required characteristics found');
      }

      debugPrint('✅ [BLE DISCOVER] All 5 characteristics discovered and mapped');
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
      debugPrint('🔔 [BLE NOTIFY] Starting notification subscription process...');
      debugPrint('🔔 [BLE NOTIFY] Checking characteristics availability...');
      debugPrint('  Environmental Measurements Char: ${_envMeasurementsChar != null ? "Available" : "NULL!"}');
      debugPrint('  Status Flags Char: ${_statusFlagsChar != null ? "Available" : "NULL!"}');
      
      developer.log('Subscribing to notifications...', name: 'BLERepository');

      if (_envMeasurementsChar == null || _statusFlagsChar == null) {
        debugPrint('❌ [BLE NOTIFY] ERROR: Required characteristics are null!');
        throw BLEException('Cannot subscribe: characteristics not initialized');
      }

      // Subscribe to environmental measurements
      debugPrint('🔔 [BLE NOTIFY] Enabling notifications for Environmental Measurements...');
      debugPrint('  Characteristic UUID: ${_envMeasurementsChar!.uuid}');
      
      await _envMeasurementsChar!.setNotifyValue(true);
      debugPrint('✅ [BLE NOTIFY] setNotifyValue(true) completed for Environmental Measurements');
      
      // Check if notifications are actually enabled
      final isNotifying = _envMeasurementsChar!.isNotifying;
      debugPrint('🔔 [BLE NOTIFY] Environmental Measurements isNotifying: $isNotifying');
      
      if (!isNotifying) {
        debugPrint('⚠️ [BLE NOTIFY] WARNING: Characteristic reports NOT notifying after setNotifyValue!');
      }
      
      debugPrint('🔔 [BLE NOTIFY] Setting up stream listener for Environmental Measurements...');
      _envNotificationSubscription =
          _envMeasurementsChar!.lastValueStream.listen(
        (data) {
          try {
            debugPrint('📦 [BLE PACKET] Environmental data received: ${data.length} bytes');
            // LOG RAW PACKET
            developer.log(
              '📦 BLE PACKET RECEIVED [Environmental]: ${data.length} bytes - Raw: [${data.join(", ")}]',
              name: 'BLERepository.Packets',
            );
            
            final reading = BLEDataSerializer.parseEnvironmentalData(data);
            _environmentalDataController.add(reading);
            
            debugPrint('✅ [BLE PACKET] Environmental data parsed and added to stream');
            developer.log(
              '✅ Environmental update parsed: $reading',
              name: 'BLERepository',
            );
            
            // LOG PARSED DATA
            developer.log(
              '📊 PARSED DATA [Environmental]: Temp=${reading.temperatureC.toStringAsFixed(1)}°C, RH=${reading.relativeHumidity.toStringAsFixed(1)}%, CO2=${reading.co2Ppm}ppm, Light=${reading.lightRaw}',
              name: 'BLERepository.Packets',
            );
          } catch (e) {
            debugPrint('❌ [BLE PACKET] Failed to parse environmental data: $e');
            developer.log(
              '❌ Failed to parse environmental data from packet: [${data.join(", ")}]',
              name: 'BLERepository.Packets',
              error: e,
              level: 900,
            );
          }
        },
        onError: (e) {
          debugPrint('❌ [BLE NOTIFY] Environmental notification stream error: $e');
          developer.log(
            'Environmental notification error',
            name: 'BLERepository',
            error: e,
            level: 900,
          );
        },
      );
      debugPrint('✅ [BLE NOTIFY] Environmental Measurements stream listener active');

      // Subscribe to status flags
      debugPrint('🔔 [BLE NOTIFY] Enabling notifications for Status Flags...');
      debugPrint('  Characteristic UUID: ${_statusFlagsChar!.uuid}');
      
      await _statusFlagsChar!.setNotifyValue(true);
      debugPrint('✅ [BLE NOTIFY] setNotifyValue(true) completed for Status Flags');
      
      // Check if notifications are actually enabled
      final statusIsNotifying = _statusFlagsChar!.isNotifying;
      debugPrint('🔔 [BLE NOTIFY] Status Flags isNotifying: $statusIsNotifying');
      
      if (!statusIsNotifying) {
        debugPrint('⚠️ [BLE NOTIFY] WARNING: Status characteristic reports NOT notifying after setNotifyValue!');
      }
      
      debugPrint('🔔 [BLE NOTIFY] Setting up stream listener for Status Flags...');
      _statusNotificationSubscription = _statusFlagsChar!.lastValueStream.listen(
        (data) {
          try {
            // LOG RAW PACKET
            developer.log(
              '📦 BLE PACKET RECEIVED [Status Flags]: ${data.length} bytes - Raw: [${data.join(", ")}]',
              name: 'BLERepository.Packets',
            );
            
            final flags = BLEDataSerializer.parseStatusFlags(data);
            _statusFlagsController.add(flags);
            
            developer.log(
              '✅ Status flags update: 0x${flags.toRadixString(16)}',
              name: 'BLERepository',
            );
            
            // LOG PARSED FLAGS
            developer.log(
              '🚩 PARSED FLAGS [Status]: 0x${flags.toRadixString(16).padLeft(4, '0')} (binary: ${flags.toRadixString(2).padLeft(16, '0')})',
              name: 'BLERepository.Packets',
            );
          } catch (e) {
            developer.log(
              '❌ Failed to parse status flags from packet: [${data.join(", ")}]',
              name: 'BLERepository.Packets',
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

      debugPrint('✅ [BLE NOTIFY] All notifications subscribed successfully');
      debugPrint('✅ [BLE NOTIFY] Ready to receive data from device');
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
      developer.log(
        '📥 BLE READ REQUEST [Environmental]',
        name: 'BLERepository.Packets',
      );
      
      final data = await _envMeasurementsChar!.read();
      
      // LOG RAW RESPONSE
      developer.log(
        '📦 BLE READ RESPONSE [Environmental]: ${data.length} bytes - Raw: [${data.join(", ")}]',
        name: 'BLERepository.Packets',
      );
      
      final reading = BLEDataSerializer.parseEnvironmentalData(data);
      
      developer.log(
        '📊 READ DATA [Environmental]: Temp=${reading.temperatureC.toStringAsFixed(1)}°C, RH=${reading.relativeHumidity.toStringAsFixed(1)}%, CO2=${reading.co2Ppm}ppm, Light=${reading.lightRaw}',
        name: 'BLERepository.Packets',
      );
      
      return reading;
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
      
      // LOG OUTGOING PACKET
      developer.log(
        '📤 BLE PACKET SENDING [Control Targets]: ${data.length} bytes - Raw: [${data.join(", ")}]',
        name: 'BLERepository.Packets',
      );
      developer.log(
        '📝 WRITE DATA [Control Targets]: TempMin=${targets.tempMin}°C, TempMax=${targets.tempMax}°C, RHMin=${targets.rhMin}%, CO2Max=${targets.co2Max}ppm, LightMode=${targets.lightMode}, On=${targets.onMinutes}min, Off=${targets.offMinutes}min',
        name: 'BLERepository.Packets',
      );
      
      await _controlTargetsChar!.write(
        data,
        withoutResponse: false,
      );
      
      developer.log(
        '✅ Control targets written successfully',
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
      
      // LOG OUTGOING PACKET
      developer.log(
        '📤 BLE PACKET SENDING [Stage State]: ${data.length} bytes - Raw: [${data.join(", ")}]',
        name: 'BLERepository.Packets',
      );
      developer.log(
        '📝 WRITE DATA [Stage State]: Mode=${state.mode}, Species=${state.species}, Stage=${state.stage}, Day=${state.daysInStage}/${state.expectedDays}',
        name: 'BLERepository.Packets',
      );
      
      await _stageStateChar!.write(
        data,
        withoutResponse: false,
      );
      
      developer.log(
        '✅ Stage state written successfully',
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
      
      // LOG OUTGOING PACKET
      developer.log(
        '📤 BLE PACKET SENDING [Override Bits]: ${data.length} bytes - Raw: [${data.join(", ")}]',
        name: 'BLERepository.Packets',
      );
      developer.log(
        '📝 WRITE DATA [Override Bits]: 0x${bits.toRadixString(16).padLeft(4, '0')} (binary: ${bits.toRadixString(2).padLeft(16, '0')})',
        name: 'BLERepository.Packets',
      );
      
      await _overrideBitsChar!.write(
        data,
        withoutResponse: true, // Write-only characteristic
      );
      
      developer.log(
        '✅ Override bits written successfully',
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
      developer.log(
        '📥 BLE READ REQUEST [Status Flags]',
        name: 'BLERepository.Packets',
      );
      
      final data = await _statusFlagsChar!.read();
      
      // LOG RAW RESPONSE
      developer.log(
        '📦 BLE READ RESPONSE [Status Flags]: ${data.length} bytes - Raw: [${data.join(", ")}]',
        name: 'BLERepository.Packets',
      );
      
      final flags = BLEDataSerializer.parseStatusFlags(data);
      
      developer.log(
        '🚩 READ DATA [Status Flags]: 0x${flags.toRadixString(16).padLeft(4, '0')} (binary: ${flags.toRadixString(2).padLeft(16, '0')})',
        name: 'BLERepository.Packets',
      );
      
      return flags;
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
      debugPrint('🔌 [BLE DISCONNECT] Disconnecting from device...');
      developer.log('Disconnecting from device', name: 'BLERepository');

      // Cancel subscriptions
      debugPrint('🔌 [BLE DISCONNECT] Cancelling notification subscriptions...');
      await _envNotificationSubscription?.cancel();
      await _statusNotificationSubscription?.cancel();
      await _connectionSubscription?.cancel();

      // Disconnect device
      if (_connectedDevice != null) {
        debugPrint('🔌 [BLE DISCONNECT] Disconnecting ${_connectedDevice!.platformName}...');
        await _connectedDevice!.disconnect();
      }

      _handleDisconnection();

      debugPrint('✅ [BLE DISCONNECT] Disconnected successfully');
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
    debugPrint('🧹 [BLE DISCONNECT] Cleaning up connection state...');
    _connectedDevice = null;
    _envMeasurementsChar = null;
    _controlTargetsChar = null;
    _stageStateChar = null;
    _overrideBitsChar = null;
    _statusFlagsChar = null;
    _currentConnectionState = BluetoothConnectionState.disconnected;
    _hasEstablishedConnection = false;
    debugPrint('✅ [BLE DISCONNECT] Cleanup complete');
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
    debugPrint('🗑️ [BLE] Disposing BLE repository...');
    developer.log('Disposing BLE repository', name: 'BLERepository');

    _envNotificationSubscription?.cancel();
    _statusNotificationSubscription?.cancel();
    _connectionSubscription?.cancel();

    _connectionStateController.close();
    _environmentalDataController.close();
    _statusFlagsController.close();
    _scanResultsController.close();
    
    debugPrint('✅ [BLE] BLE repository disposed');
  }
}

/// BLE-specific exception
class BLEException implements Exception {
  final String message;

  BLEException(this.message);

  @override
  String toString() => 'BLEException: $message';
}
