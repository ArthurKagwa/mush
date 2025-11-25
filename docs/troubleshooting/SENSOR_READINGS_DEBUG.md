# No Sensor Readings After Connection - Diagnostic Guide

**Issue:** BLE connection works, but monitoring screen shows "no sensor data"  
**Date:** November 6, 2025  
**Status:** Diagnostic phase

---

## 🔍 Complete Data Flow

### Expected Flow (5 Steps)
```
1. Pi Backend (every 30s)
   └─> main.py reads sensors
   └─> calls ble_gatt.notify_env_packet(temp, rh, co2, light)
   └─> EnvironmentalMeasurementsCharacteristic.update_data()
   └─> Sends BLE notification packet (12 bytes)

2. Flutter BLE Repository
   └─> Receives notification via FlutterBluePlus
   └─> Parses bytes: BLEDataSerializer.parseEnvironmentalData()
   └─> Emits EnvironmentalReading to environmentalDataStream

3. Sensor Data Listener (Auto-initialized at app startup)
   └─> Listens to environmentalDataStream
   └─> Matches device ID to farm ID
   └─> Calls ReadingsDao.insertReading()
   └─> Saves to SQLite database

4. Database
   └─> Readings table stores: timestamp, farmId, co2, temp, RH, light

5. Monitoring Screen (every 30s refresh)
   └─> Queries selectedMonitoringFarmLatestReadingProvider
   └─> Reads latest reading from database
   └─> Displays data with color coding
```

---

## 📋 Diagnostic Checklist

### Step 1: Verify Pi is Sending Data ✅/❌

**On Raspberry Pi, check main.py logs:**
```bash
sudo journalctl -u mushpi.service -f --since "5 minutes ago" | grep -E "Sensors|BLE|Environmental"
```

**Expected logs (every 30 seconds):**
```
INFO - Sensors - Temp: 22.5°C, RH: 65.0%, CO2: 450ppm, Light: 78
DEBUG - Environmental data updated: T=22.5°C, RH=65.0%, CO2=450ppm, L=78
DEBUG - BLE env read: CO2=450, T=22.5°C
```

**If missing:**
- ❌ Sensor monitoring not started
- ❌ main.py loop not running
- ❌ Check: `sudo systemctl status mushpi.service`
- ❌ Fix: `sudo systemctl restart mushpi.service`

---

### Step 2: Verify Flutter Receives Notifications ✅/❌

**In Flutter app logs (VS Code debug console):**
```
Look for lines containing:
📦 BLE PACKET RECEIVED [Environmental]: 18 bytes - Raw: [210, 7, 232, 3, ...]
📊 PARSED DATA [Environmental]: Temp=22.5°C, RH=65.0%, CO2=450ppm, Light=78
```

**How to check:**
```bash
# Run Flutter app in terminal with verbose logging
cd /Users/arthur/dev/mush/flutter/mushpi_hub
flutter run -v 2>&1 | grep -E "BLE PACKET|PARSED DATA|SensorListener"
```

**If missing:**
- ❌ BLE notifications not subscribed
- ❌ Check: Connection state is "connected" in app
- ❌ Check: Device has discovered services
- ❌ Fix: Disconnect and reconnect to device

---

### Step 3: Verify Sensor Data Listener is Active ✅/❌

**In Flutter app logs:**
```
Look for initialization:
🎬 [SensorListener] Initializing sensor data listener
✅ [SensorListener] Sensor data listener initialized and ready

Look for farm identification:
🔗 [SensorListener] Device connected: XX:XX:XX:XX:XX:XX
✅ [SensorListener] Identified farm: My Farm (ID: farm-uuid-123)
```

**If missing farm identification:**
- ❌ Device ID doesn't match any farm's deviceId
- ❌ Farm was created but deviceId wasn't saved
- ❌ Check database: `farm.deviceId` should equal `device.remoteId.toString()`

**Fix: Verify farm-device link:**
```dart
// In Flutter DevTools console:
final farms = await ref.read(farmsDaoProvider).getAllFarms();
for (final farm in farms) {
  print('Farm: ${farm.name}, DeviceID: ${farm.deviceId}');
}

// Compare with BLE device ID:
final device = ref.read(bleRepositoryProvider).connectedDevice;
print('Connected Device ID: ${device?.remoteId.toString()}');
```

---

### Step 4: Verify Data is Saved to Database ✅/❌

**In Flutter app logs (should appear after each BLE notification):**
```
📊 [SensorListener] Received environmental data:
  Farm: farm-uuid-123
  Temperature: 22.5°C
  Humidity: 65.0%
  CO₂: 450 ppm
  Light: 78
✅ [SensorListener] Successfully saved reading to database
```

**If missing save confirmation:**
- ❌ Debouncing is active (saves max once per 5 seconds)
- ❌ Database write error
- ❌ Check for error logs: `❌ [SensorListener] Failed to save reading`

**Check database directly:**
```dart
// In Flutter DevTools console:
final dao = ref.read(readingsDaoProvider);
final readings = await dao.getRecentReadingsByFarm('farm-uuid-123', 10);
for (final reading in readings) {
  print('${reading.timestamp}: T=${reading.temperatureC}°C, RH=${reading.relativeHumidity}%');
}
```

---

### Step 5: Verify Monitoring Screen Displays Data ✅/❌

**In Monitoring Screen:**
- Check: Environmental card should show actual values (not "--")
- Check: Timestamp should show "Just now" or "Xm ago"
- Check: Color coding should reflect sensor values

**In Flutter app logs:**
```
Look for:
🔄 [MonitoringScreen] Auto-refresh triggered
📊 [Provider] selectedMonitoringFarmLatestReadingProvider fetching latest reading
✅ [Provider] Latest reading found: timestamp=2025-11-06 23:45:00
```

**If showing "No Data":**
- ❌ selectedMonitoringFarmIdProvider is null
- ❌ No readings exist for selected farm
- ❌ Database query is failing

**Check query:**
```dart
// In Flutter DevTools console:
final farmId = ref.read(selectedMonitoringFarmIdProvider);
print('Selected farm ID: $farmId');

final dao = ref.read(readingsDaoProvider);
final latest = await dao.getLatestReadingByFarm(farmId!);
print('Latest reading: $latest');
```

---

## 🔧 Common Issues & Fixes

### Issue 1: Pi sensors working but no BLE notifications

**Symptoms:**
- Pi logs show sensor readings
- No BLE packet logs in Flutter

**Cause:** BLE service not sending notifications

**Fix:**
```bash
# On Pi, check BLE service status
sudo systemctl status mushpi.service

# Check if notify_env_packet is being called
sudo journalctl -u mushpi.service -f | grep "notify_env_packet\|Environmental data updated"

# Restart service if needed
sudo systemctl restart mushpi.service
```

---

### Issue 2: BLE notifications received but not saved

**Symptoms:**
- Flutter logs show `📦 BLE PACKET RECEIVED`
- No `✅ Successfully saved reading to database`

**Cause:** Sensor Data Listener not identifying farm

**Fix:**
```dart
// Check device-farm link
1. Get device ID from BLE: device.remoteId.toString()
2. Get farm deviceId from database: farm.deviceId
3. They MUST match exactly (case-sensitive)

// If they don't match, update farm:
final dao = ref.read(farmsDaoProvider);
await dao.updateFarm(
  farm.copyWith(deviceId: device.remoteId.toString())
);
```

---

### Issue 3: Data saved but monitoring screen blank

**Symptoms:**
- Database has readings
- Monitoring screen shows "--" or "No Data"

**Cause:** Farm not selected in monitoring screen

**Fix:**
```dart
// Manually select farm
ref.read(selectedMonitoringFarmIdProvider.notifier).state = 'your-farm-id';

// Or navigate from farm card (auto-selects)
context.go('/monitoring');
ref.read(selectedMonitoringFarmIdProvider.notifier).state = farmId;
```

---

## 🚀 Quick Test Procedure

### Complete End-to-End Test

**1. Connect to device via Farms tab**
```
- Tap farm card
- Tap "Connect" button
- Wait for "Connected" status
```

**2. Check Pi is sending (Terminal 1)**
```bash
ssh pi@raspberrypi.local
sudo journalctl -u mushpi.service -f | grep "Sensors"
# Should see readings every 30 seconds
```

**3. Check Flutter is receiving (Terminal 2)**
```bash
cd /Users/arthur/dev/mush/flutter/mushpi_hub
flutter run -v 2>&1 | grep "BLE PACKET RECEIVED"
# Should see packets every 30 seconds
```

**4. Check listener is saving (Flutter logs)**
```
Look for:
✅ [SensorListener] Identified farm: My Farm
✅ [SensorListener] Successfully saved reading to database
```

**5. Check monitoring screen**
```
- Navigate to Monitoring tab
- Select your farm from dropdown
- Environmental card should show live data
- Timestamp should show "Just now"
```

---

## 📊 Expected Timeline

**From connection to data display:**
```
T+0s:   User taps "Connect"
T+2s:   BLE connection established
T+3s:   Services discovered
T+4s:   Notifications subscribed
T+5s:   SensorListener identifies farm
T+30s:  Pi sends first notification (30s interval)
T+30s:  Flutter receives packet
T+30s:  Data saved to database
T+30s:  Monitoring screen displays data
```

**If no data after 60 seconds:**
- Something is broken - follow diagnostic steps above

---

## 🐛 Debug Commands

### Check App State
```dart
// In Flutter DevTools console:

// 1. Check BLE connection
final ble = ref.read(bleRepositoryProvider);
print('Connected: ${ble.isConnected}');
print('Device: ${ble.connectedDevice?.platformName}');

// 2. Check sensor listener
print('Sensor listener initialized in app.dart');

// 3. Check database
final dao = ref.read(readingsDaoProvider);
final count = await dao.getAllReadings().then((r) => r.length);
print('Total readings in database: $count');

// 4. Check monitoring state
final farmId = ref.read(selectedMonitoringFarmIdProvider);
print('Selected farm: $farmId');
```

### Check Pi State
```bash
# 1. Check service status
sudo systemctl status mushpi.service

# 2. Check sensor readings
sudo journalctl -u mushpi.service --since "1 minute ago" | grep "Sensors"

# 3. Check BLE is advertising
sudo hciconfig hci0
sudo hcitool lescan

# 4. Check BLE service logs
sudo journalctl -u mushpi.service --since "1 minute ago" | grep "BLE"
```

---

## ✅ Success Indicators

**All systems operational when you see:**

**Pi Logs:**
```
✅ Sensors - Temp: 22.5°C, RH: 65.0%, CO2: 450ppm, Light: 78
✅ Environmental data updated: T=22.5°C, RH=65.0%, CO2=450ppm, L=78
```

**Flutter Logs:**
```
✅ 📦 BLE PACKET RECEIVED [Environmental]: 18 bytes
✅ ✅ [SensorListener] Identified farm: My Farm (ID: farm-123)
✅ ✅ [SensorListener] Successfully saved reading to database
```

**Monitoring Screen:**
```
✅ Temperature: 22.5°C (colored indicator)
✅ Humidity: 65.0% (colored indicator)
✅ CO₂: 450 ppm (colored indicator)
✅ Light: 78
✅ Timestamp: "Just now" (green indicator)
```

---

## 📞 Next Steps

**If data flow is still not working after following this guide:**

1. **Gather diagnostic info:**
   - Pi service logs (last 100 lines)
   - Flutter app logs (with BLE packet filter)
   - Database query results (farms + readings tables)
   - Screenshots of monitoring screen

2. **Share findings in this format:**
   ```
   Step 1 (Pi sending): ✅/❌
   Step 2 (Flutter receiving): ✅/❌
   Step 3 (Listener active): ✅/❌
   Step 4 (Database saving): ✅/❌
   Step 5 (Screen displaying): ✅/❌
   
   Logs attached: [paste relevant logs]
   ```

3. **I'll help debug the specific failing step**

---

**Updated:** November 6, 2025  
**Version:** 1.0 (Initial Diagnostic Guide)
