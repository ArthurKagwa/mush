# Flutter BLE Debug Mode - Enable All Device Scanning

This guide shows how to enable debug scanning in your Flutter app to see **all BLE devices**, including MushPi.

## Quick Overview

When scanning normally, Flutter BLE libraries often filter devices. To debug:
1. Remove all scan filters
2. Enable low-latency scanning
3. Print all discovered devices
4. Check for service UUIDs in advertisement data

---

## Option 1: Using `flutter_blue_plus` (Recommended)

### 1. Add debug scanning code

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Start scanning with NO filters
Future<void> startDebugScan() async {
  print('🔍 Starting DEBUG BLE scan (all devices)...');
  
  // Stop any existing scan
  await FlutterBluePlus.stopScan();
  
  // Start scan with no filters
  await FlutterBluePlus.startScan(
    timeout: Duration(seconds: 15),
    androidUsesFineLocation: true,  // Android: enable fine location
  );
  
  // Listen to scan results
  FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult result in results) {
      print('───────────────────────────────────');
      print('Device: ${result.device.name.isEmpty ? "(No Name)" : result.device.name}');
      print('MAC: ${result.device.id}');
      print('RSSI: ${result.rssi} dBm');
      print('Service UUIDs: ${result.advertisementData.serviceUuids}');
      print('Manufacturer Data: ${result.advertisementData.manufacturerData}');
      print('Service Data: ${result.advertisementData.serviceData}');
      
      // Highlight MushPi devices
      if (result.device.name.toLowerCase().contains('mushpi')) {
        print('🍄 FOUND MUSHPI DEVICE! 🍄');
      }
    }
  });
}
```

### 2. Check for your service UUID

Look for this UUID in the output:
```
Service UUIDs: [12345678-1234-5678-1234-56789abcdef0]
```

---

## Option 2: Using `flutter_reactive_ble`

```dart
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final flutterReactiveBle = FlutterReactiveBle();

void startDebugScan() {
  print('🔍 Starting DEBUG BLE scan...');
  
  flutterReactiveBle.scanForDevices(
    withServices: [],  // Empty = scan for ALL devices
    scanMode: ScanMode.lowLatency,
  ).listen((device) {
    print('───────────────────────────────────');
    print('Device: ${device.name}');
    print('ID: ${device.id}');
    print('RSSI: ${device.rssi}');
    print('Service UUIDs: ${device.serviceUuids}');
    
    if (device.name.toLowerCase().contains('mushpi')) {
      print('🍄 FOUND MUSHPI DEVICE! 🍄');
    }
  }, onError: (error) {
    print('Scan error: $error');
  });
}
```

---

## Android Permissions (Android 12+)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Bluetooth permissions for Android 12+ -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                     android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- For older Android versions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    
    <application>
        ...
    </application>
</manifest>
```

### Request permissions at runtime:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  if (Platform.isAndroid) {
    // Request Bluetooth permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }
}
```

---

## iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<dict>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>MushPi needs Bluetooth to connect to your mushroom growing controller</string>
    
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>MushPi needs Bluetooth to discover nearby devices</string>
</dict>
```

---

## Troubleshooting

### "No devices found"

**Android:**
1. Enable Location Services (Settings → Location → On)
2. Grant Location permission to the app
3. Grant Bluetooth permissions (Android 12+)
4. Try disabling battery optimization for your app

**iOS:**
1. Grant Bluetooth permission when prompted
2. Ensure app is in foreground while scanning
3. Check Info.plist has the required keys

### "Device shows but no service UUIDs"

- Some devices don't advertise service UUIDs (this is normal)
- Check if the device name is "MushPi-..." - that's your Pi!
- Connect to the device to discover services

### "Scan finds devices but not MushPi"

**On the Raspberry Pi:**
```bash
# Ensure app is running with sudo
sudo python3 main.py

# Check if advertising
sudo bluetoothctl
> scan on
# Look for MushPi-Init in the list
```

**Check the app logs:**
```
INFO:app.ble.service:Advertising name='MushPi-Init' uuid=12345678-1234-5678-1234-56789abcdef0
```

If you see this log, the Pi is advertising!

---

## Testing Steps

1. **Start MushPi on Raspberry Pi:**
   ```bash
   cd ~/mushpi
   sudo venv/bin/python3 main.py
   ```

2. **Verify advertising on Pi:**
   ```bash
   # Run the verification script
   chmod +x verify_ble_advertising.sh
   ./verify_ble_advertising.sh
   ```

3. **Run Flutter app with debug scanning:**
   - Add the debug scanning code above
   - Run on a physical device (not emulator)
   - Check console logs for device list

4. **Look for these indicators:**
   - Device name contains "MushPi"
   - Service UUIDs include `12345678-1234-5678-1234-56789abcdef0`
   - RSSI is reasonable (typically -30 to -90 dBm when nearby)

---

## Example Debug Output

When working correctly, you should see:

```
🔍 Starting DEBUG BLE scan (all devices)...
───────────────────────────────────
Device: MushPi-Init
MAC: AA:BB:CC:DD:EE:FF
RSSI: -65 dBm
Service UUIDs: [12345678-1234-5678-1234-56789abcdef0]
Manufacturer Data: {}
Service Data: {}
🍄 FOUND MUSHPI DEVICE! 🍄
───────────────────────────────────
```

---

## Quick Reference Commands

**Raspberry Pi:**
```bash
# Start app with advertising
sudo venv/bin/python3 main.py

# Verify advertising
./verify_ble_advertising.sh

# Manual check
sudo bluetoothctl
> scan on
> devices
> info <MAC_ADDRESS>
```

**Flutter:**
```dart
// Enable debug scanning
startDebugScan();

// Check service UUIDs
if (device.serviceUuids.contains('12345678-1234-5678-1234-56789abcdef0')) {
  print('This is a MushPi device!');
}
```

---

## Need More Help?

1. Check the MushPi app logs for advertising status
2. Run `btmon` on the Pi to see raw BLE packets
3. Verify Bluetooth is enabled on phone
4. Try scanning with a BLE scanner app (nRF Connect, LightBlue)
