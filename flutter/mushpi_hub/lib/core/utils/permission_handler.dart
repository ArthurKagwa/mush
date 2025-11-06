import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

/// Handles BLE permission requests and checks for Android and iOS.
///
/// This utility manages the platform-specific permission flow required
/// for Bluetooth Low Energy operations.
class BLEPermissionHandler {
  /// Check if all required BLE permissions are granted.
  ///
  /// Returns true if permissions are granted, false otherwise.
  static Future<bool> hasPermissions() async {
    try {
      // Check if Bluetooth adapter is available
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        developer.log('Bluetooth adapter not available', name: 'BLEPermissions');
        return false;
      }

      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        developer.log('Bluetooth is turned off', name: 'BLEPermissions');
        return false;
      }

      // On Android, check location permission
      if (Platform.isAndroid) {
        final locationStatus = await Permission.locationWhenInUse.status;
        if (!locationStatus.isGranted) {
          developer.log('Location permission not granted', name: 'BLEPermissions');
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Error checking permissions: $e', name: 'BLEPermissions', error: e);
      return false;
    }
  }

  /// Request BLE permissions from the user.
  ///
  /// On Android 12+, this will request BLUETOOTH_SCAN, BLUETOOTH_CONNECT, and ACCESS_FINE_LOCATION.
  /// On Android 11 and below, this will request BLUETOOTH, BLUETOOTH_ADMIN, and ACCESS_FINE_LOCATION.
  /// On iOS, permissions are handled automatically when accessing Bluetooth.
  ///
  /// Returns true if permissions were granted, false otherwise.
  static Future<bool> requestPermissions() async {
    try {
      // Check if Bluetooth adapter is available
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        developer.log('Bluetooth adapter not available', name: 'BLEPermissions');
        return false;
      }

      // On Android, request location permission (required for BLE scanning)
      if (Platform.isAndroid) {
        developer.log('Requesting Android location permission...', name: 'BLEPermissions');
        
        final locationStatus = await Permission.locationWhenInUse.request();
        
        developer.log(
          'Location permission status: $locationStatus',
          name: 'BLEPermissions',
        );
        
        if (!locationStatus.isGranted) {
          developer.log(
            'Location permission denied: $locationStatus',
            name: 'BLEPermissions',
            level: 900,
          );
          return false;
        }

        // Also request Bluetooth permissions on Android 12+
        if (Platform.isAndroid) {
          final bluetoothScan = await Permission.bluetoothScan.request();
          final bluetoothConnect = await Permission.bluetoothConnect.request();
          
          developer.log(
            'Bluetooth scan: $bluetoothScan, connect: $bluetoothConnect',
            name: 'BLEPermissions',
          );
        }
      }

      developer.log('All permissions granted', name: 'BLEPermissions');
      return true;
    } catch (e) {
      developer.log('Error requesting permissions: $e', name: 'BLEPermissions', error: e);
      return false;
    }
  }

  /// Turn on Bluetooth adapter.
  ///
  /// On Android, this will show a system dialog asking the user to enable Bluetooth.
  /// On iOS, this will navigate the user to Settings (cannot be done programmatically).
  ///
  /// Returns true if Bluetooth was successfully turned on or is already on.
  static Future<bool> turnOnBluetooth() async {
    try {
      // Check current state
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState == BluetoothAdapterState.on) {
        return true;
      }

      if (Platform.isAndroid) {
        // On Android, try to turn on Bluetooth
        try {
          await FlutterBluePlus.turnOn();
          return true;
        } catch (e) {
          developer.log('Error turning on Bluetooth: $e', name: 'BLEPermissions', error: e);
          return false;
        }
      } else {
        // On iOS, cannot turn on Bluetooth programmatically
        developer.log('Bluetooth is off - user must enable in Settings', name: 'BLEPermissions');
        return false;
      }
    } catch (e) {
      developer.log('Error in turnOnBluetooth: $e', name: 'BLEPermissions', error: e);
      return false;
    }
  }

  /// Show a dialog explaining why BLE permissions are needed.
  ///
  /// Use this before requesting permissions to provide context to the user.
  static Future<bool> showPermissionRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          Platform.isAndroid
              ? 'MushPi Hub needs Bluetooth and Location access to:\n\n'
                  '• Discover nearby MushPi devices\n'
                  '• Connect to your farms\n'
                  '• Monitor environmental conditions\n'
                  '• Control growing parameters\n\n'
                  'Location permission is required by Android for Bluetooth scanning. '
                  'Your location is NOT tracked or stored.'
              : 'MushPi Hub needs Bluetooth access to:\n\n'
                  '• Discover nearby MushPi devices\n'
                  '• Connect to your farms\n'
                  '• Monitor environmental conditions\n'
                  '• Control growing parameters',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show a dialog when Bluetooth is turned off.
  ///
  /// Provides options to turn on Bluetooth or cancel the operation.
  static Future<bool> showBluetoothOffDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth is Off'),
        content: Text(
          Platform.isAndroid
              ? 'MushPi Hub requires Bluetooth to be turned on to connect to your devices.\n\n'
                  'Would you like to turn on Bluetooth now?'
              : 'MushPi Hub requires Bluetooth to be turned on to connect to your devices.\n\n'
                  'Please enable Bluetooth in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (Platform.isAndroid)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Turn On'),
            )
          else
            FilledButton(
              onPressed: () {
                Navigator.pop(context, false);
                // On iOS, we can't open Settings programmatically
                // User must manually go to Settings
              },
              child: const Text('OK'),
            ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show a dialog when permissions are permanently denied.
  ///
  /// Provides guidance to the user on how to enable permissions in Settings.
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          Platform.isAndroid
              ? 'MushPi Hub needs Bluetooth and Location permissions.\n\n'
                  'To enable:\n'
                  '1. Open Settings\n'
                  '2. Go to Apps → MushPi Hub → Permissions\n'
                  '3. Enable Bluetooth and Location\n\n'
                  'Note: Location is required by Android for Bluetooth scanning. '
                  'Your location is NOT tracked.'
              : 'MushPi Hub needs Bluetooth permission.\n\n'
                  'To enable:\n'
                  '1. Open Settings\n'
                  '2. Go to Privacy → Bluetooth\n'
                  '3. Enable MushPi Hub',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Complete permission flow with user guidance.
  ///
  /// This method handles the entire permission request flow:
  /// 1. Show rationale if needed
  /// 2. Request permissions
  /// 3. Check if Bluetooth is on
  /// 4. Turn on Bluetooth if needed
  /// 5. Show appropriate error dialogs
  ///
  /// Returns true if all permissions are granted and Bluetooth is on.
  static Future<bool> ensurePermissions(BuildContext context) async {
    try {
      // Check if permissions are already granted
      final hasPerms = await hasPermissions();
      if (hasPerms) {
        return true;
      }

      // Show rationale
      final shouldRequest = await showPermissionRationale(context);
      if (!shouldRequest) {
        return false;
      }

      // Request permissions
      final granted = await requestPermissions();
      if (!granted) {
        if (context.mounted) {
          await showPermissionDeniedDialog(context);
        }
        return false;
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (context.mounted) {
          final shouldTurnOn = await showBluetoothOffDialog(context);
          if (shouldTurnOn) {
            final turnedOn = await turnOnBluetooth();
            return turnedOn;
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Error in ensurePermissions: $e', name: 'BLEPermissions', error: e);
      return false;
    }
  }
}
