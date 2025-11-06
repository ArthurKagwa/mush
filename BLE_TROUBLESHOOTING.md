# BLE Connection Troubleshooting Guide

**Issue:** Mobile app failing to detect MushPi Raspberry Pi device  
**Date:** November 6, 2025  
**Status:** Enhanced detection implemented - debugging phase

---

## ✅ Recent Fixes Applied

### 1. Dual Detection Strategy
- **Before:** Only filtered by device name "MushPi-"
- **After:** Detects by EITHER name OR service UUID
- **Benefit:** Works with different BLE advertising methods

### 2. Software vs Hardware Filtering
- **Before:** Used `withServices` parameter (hardware filter)
- **After:** Scans ALL devices, filters in software
- **Benefit:** Compatible with Pi's BlueZero library limitations

### 3. Enhanced Logging
- **Added:** Comprehensive logs for all discovered devices
- **Added:** Detection strategy indicators (name vs UUID)
- **Added:** RSSI, service UUID count, device details
- **Benefit:** Easy diagnosis of advertising issues

---

## 🔍 Diagnostic Steps

### Step 1: Check Pi BLE Service Status

**On Raspberry Pi, run:**
```bash
# Check if Bluetooth is powered
sudo bluetoothctl show

# Check if MushPi service is running
sudo systemctl status mushpi.service

# Check Python BLE logs
sudo journalctl -u mushpi.service -f --since "5 minutes ago"
```

**Expected Output:**
- Bluetooth adapter shows `Powered: yes`
- Discoverable: yes
- Service running without errors
- Logs show: "BLE GATT service started - advertising as 'MushPi-<species><stage>'"

---

### Step 2: Verify BLE Advertising

**On Raspberry Pi:**
```bash
# Check adapter status
hciconfig hci0

# Enable advertising if needed
sudo hciconfig hci0 up
sudo hciconfig hci0 leadv
sudo hciconfig hci0 piscan
```

**Expected Output:**
```
hci0:   Type: Primary  Bus: UART
        BD Address: XX:XX:XX:XX:XX:XX  ACL MTU: 1021:8  SCO MTU: 64:1
        UP RUNNING PSCAN ISCAN 
        RX bytes:1234 acl:0 sco:0 events:56 errors:0
        TX bytes:2345 acl:0 sco:0 commands:56 errors:0
```

---

### Step 3: Test with Generic BLE Scanner

**Install nRF Connect on your phone:**
- iOS: https://apps.apple.com/app/nrf-connect/id1054362403
- Android: https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp

**Scan for devices and verify:**
1. Device appears in scan results
2. Device name shows "MushPi-<species><stage>"
3. Service UUID `12345678-1234-5678-1234-56789abcdef0` is visible
4. RSSI is strong enough (> -80 dBm)

**If device doesn't appear in nRF Connect:**
- Problem is with Pi's BLE advertising, not the Flutter app
- Check Pi Bluetooth configuration
- Verify BlueZ version: `bluetoothctl --version` (should be ≥ 5.50)

---

### Step 4: Check Flutter App Logs

**Enable verbose logging in VS Code:**
```bash
# In terminal, run Flutter app with verbose logs
cd /Users/arthur/dev/mush/flutter/mushpi_hub
flutter run -v
```

**Watch for these log entries:**
```
[device_scan] Checking BLE permissions...
[device_scan] BLE permissions granted, starting scan...
[device_scan] BLE scanning started successfully
[BLERepository] Starting BLE scan for MushPi devices (timeout: 30s)
[BLERepository] Found MushPi device: <name> (<id>) [Name: true/false, UUID: true/false, RSSI: -XX]
[device_scan] Displaying N scan results
[device_scan] Device: <name> (XX:XX:XX:XX:XX:XX) RSSI: -XX UUIDs: N HasMushPiUUID: true/false
```

**If no devices logged:**
- Check Bluetooth permissions (Settings → MushPi → Bluetooth: ON)
- Check Location permissions (Android requires this for BLE)
- Ensure Bluetooth is enabled on phone
- Check phone is close to Pi (< 10 meters, ideally < 2 meters)

---

### Step 5: Verify Pi Configuration

**Check MushPi config file:**
```bash
cat /home/pi/mushpi/.env
```

**Verify these settings:**
```bash
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi
MUSHPI_BLE_ENABLED=true
```

**Check current stage configuration:**
```bash
cat /home/pi/mushpi/data/stage_config.json
```

**Expected:**
```json
{
  "species": "Oyster",  // or Shiitake, Lion's Mane
  "stage": "Pinning",   // or Incubation, Fruiting
  "mode": "FULL"
}
```

---

### Step 6: Test BLE Advertising Manually

**On Raspberry Pi, run interactive test:**
```python
#!/usr/bin/env python3
import sys
sys.path.append('/home/pi/mushpi')

from app.core.ble_gatt import start_ble_service, get_status

# Start service
print("Starting BLE service...")
success = start_ble_service()
print(f"Service started: {success}")

# Check status
status = get_status()
print(f"Service running: {status.get('running', False)}")
print(f"Connected clients: {status.get('connected_clients', 0)}")

# Keep running
input("Press Enter to stop...")
```

**Save as `/home/pi/test_ble.py` and run:**
```bash
sudo python3 /home/pi/test_ble.py
```

---

## 🐛 Common Issues & Fixes

### Issue 1: "Bluetooth not supported"
**Cause:** Phone doesn't have BLE hardware  
**Fix:** Use a different device (most phones after 2013 have BLE)

### Issue 2: "Bluetooth permissions denied"
**Cause:** User denied permission request  
**Fix:**
- iOS: Settings → MushPi → Bluetooth → Enable
- Android: Settings → Apps → MushPi → Permissions → Location & Nearby devices → Enable

### Issue 3: "No devices found" but nRF Connect works
**Cause:** App filtering too strict  
**Fix:** Already fixed with dual detection! Update to latest code.

### Issue 4: Pi shows "BLE adapter not initialized"
**Cause:** BlueZ not installed or Bluetooth disabled  
**Fix:**
```bash
sudo apt-get update
sudo apt-get install -y bluez python3-bluez
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### Issue 5: Device name is "Unknown" or empty
**Cause:** BlueZero not advertising name properly  
**Fix:** Our dual detection now catches this! Device will be detected by service UUID instead.

### Issue 6: "Service UUID not found" after connection
**Cause:** Pi's GATT service not properly registered  
**Fix:** Restart MushPi service:
```bash
sudo systemctl restart mushpi.service
sleep 5
sudo journalctl -u mushpi.service -n 50
```

---

## 📱 App Debugging Commands

**Enable debug mode in Flutter DevTools:**
```bash
# Open Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# In another terminal, run app
flutter run --observatory-port=9200
```

**Monitor BLE events:**
```dart
// In Flutter DevTools console:
debugPrint('Current scan state: ${ref.read(bleScanStateProvider)}');
```

**Check raw scan results:**
```dart
// Add this temporarily to device_scan_screen.dart
print('Raw results: ${results.map((r) => {
  'name': r.device.platformName,
  'id': r.device.remoteId,
  'rssi': r.rssi,
  'uuids': r.advertisementData.serviceUuids,
}).toList()}');
```

---

## 📊 Expected Behavior

### Successful Connection Flow:

1. **App Launch**
   - Permissions requested and granted ✅
   - Bluetooth enabled ✅
   - BLE scan starts automatically ✅

2. **Device Discovery** (within 5-10 seconds)
   - Pi appears in scan results ✅
   - Device name: "MushPi-OysterPinning" (example) ✅
   - RSSI: -40 to -70 dBm (good signal) ✅
   - Detection method: Name OR UUID ✅

3. **Device Selection**
   - User taps device card ✅
   - Farm creation dialog appears ✅
   - Species auto-detected from name ✅

4. **Farm Creation**
   - User enters farm name ✅
   - Farm saved to database ✅
   - Device linked to farm ✅
   - Navigation to home screen ✅

---

## 🔧 Quick Fixes

### Quick Fix 1: Restart Everything
```bash
# On Pi
sudo systemctl restart bluetooth
sudo systemctl restart mushpi.service

# On Phone
- Close MushPi app completely
- Toggle Bluetooth OFF then ON
- Reopen MushPi app
```

### Quick Fix 2: Reset BLE Adapter (Pi)
```bash
sudo hciconfig hci0 down
sleep 2
sudo hciconfig hci0 up
sudo systemctl restart mushpi.service
```

### Quick Fix 3: Clear Bluetooth Cache (Android)
```bash
Settings → Apps → Bluetooth → Storage → Clear Cache
Settings → Apps → MushPi → Storage → Clear Cache
Restart phone
```

---

## 📞 Support Checklist

Before asking for help, gather this info:

**Pi Information:**
- [ ] `uname -a` output
- [ ] `bluetoothctl --version`
- [ ] `sudo systemctl status mushpi.service`
- [ ] `sudo journalctl -u mushpi.service -n 100`
- [ ] `hciconfig -a` output

**Phone Information:**
- [ ] Device model and OS version
- [ ] Bluetooth enabled? (Yes/No)
- [ ] Permissions granted? (Yes/No)
- [ ] nRF Connect can see Pi? (Yes/No)
- [ ] Flutter app logs from `flutter run -v`

**Network Information:**
- [ ] Distance between Pi and phone (<5m recommended)
- [ ] Other Bluetooth devices nearby?
- [ ] WiFi enabled on both devices?

---

## 🎯 Next Steps

1. **Run diagnostic steps 1-4 above**
2. **Share findings:**
   - Pi BLE service status
   - nRF Connect scan results
   - Flutter app logs
3. **If still not working:**
   - Attach Pi logs (`sudo journalctl -u mushpi.service`)
   - Attach app logs (`flutter run -v` output)
   - Share screenshots from nRF Connect

---

**Updated:** November 6, 2025  
**Version:** 1.1 (Enhanced Detection)
