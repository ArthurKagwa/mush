# BLE Debug Log Reference

Quick reference for filtering and understanding BLE transaction logs in the Flutter app.

## 🔍 How to View BLE Logs

### Method 1: VS Code Debug Console
```
1. Open project in VS Code
2. Run app: F5 or "Run > Start Debugging"
3. View logs in "DEBUG CONSOLE" tab
4. Filter using search box (Ctrl+F / Cmd+F)
```

### Method 2: Terminal with Grep
```bash
cd /Users/arthur/dev/mush/flutter/mushpi_hub

# All BLE operations
flutter run -v 2>&1 | grep "\[BLE"

# Only scan operations
flutter run -v 2>&1 | grep "BLE SCAN"

# Only connection operations
flutter run -v 2>&1 | grep -E "BLE\]|BLE DISCOVER|BLE NOTIFY"

# Only data packets
flutter run -v 2>&1 | grep "BLE PACKET"

# Only sensor listener
flutter run -v 2>&1 | grep "SensorListener"

# Combined: BLE + Sensor Listener
flutter run -v 2>&1 | grep -E "BLE|SensorListener"
```

### Method 3: Save to File
```bash
# Save all logs to file
flutter run -v 2>&1 | tee flutter_logs_$(date +%Y%m%d_%H%M%S).txt

# Save only BLE logs to file
flutter run -v 2>&1 | grep -E "BLE|SensorListener" | tee ble_logs_$(date +%Y%m%d_%H%M%S).txt
```

---

## 🏷️ Log Prefixes

### Scan Operations
- `🔍 [BLE SCAN]` - Scan lifecycle (start, stop, complete)
- `📱 [BLE SCAN]` - Device discovered during scan
- `✅ [BLE SCAN]` - Device matched MushPi filter
- `❌ [BLE SCAN]` - Device rejected (not MushPi)
- `🛑 [BLE SCAN]` - Scan stopped

### Connection Operations
- `🔗 [BLE]` - Connection establishment
- `🔄 [BLE]` - Connection state change
- `🔌 [BLE]` - Disconnection
- `🔌 [BLE DISCONNECT]` - Disconnection details
- `🧹 [BLE DISCONNECT]` - Connection cleanup

### Service Discovery
- `🔍 [BLE DISCOVER]` - Service/characteristic discovery
- `📋 [BLE DISCOVER]` - Found service or characteristic
- `✅ [BLE DISCOVER]` - Successfully mapped characteristic
- `❌ [BLE DISCOVER]` - Missing characteristic

### Notifications
- `🔔 [BLE NOTIFY]` - Notification subscription
- `✅ [BLE NOTIFY]` - Notification ready

### Data Operations
- `📦 BLE PACKET RECEIVED` - Incoming notification
- `📊 PARSED DATA` - Parsed notification data
- `📤 BLE PACKET SENDING` - Outgoing write
- `📝 WRITE DATA` - Write operation details
- `📥 BLE READ REQUEST` - Read initiated
- `📦 BLE READ RESPONSE` - Read completed
- `🚩 PARSED FLAGS` - Status flags parsed

### Sensor Data Listener
- `🎬 [SensorListener]` - Initialization
- `🔗 [SensorListener]` - Device connected
- `✅ [SensorListener]` - Farm identified
- `📊 [SensorListener]` - Data received
- `✅ [SensorListener]` - Data saved to database
- `⏭️ [SensorListener]` - Skipped (debounce/no farm)

### General BLE
- `🔵 [BLE]` - Bluetooth adapter operations
- `🗑️ [BLE]` - Disposal/cleanup

---

## 📋 Common Log Sequences

### Successful Scan
```
🔍 [BLE SCAN] ============ STARTING SCAN ============
🔍 [BLE SCAN] Timeout: 30s
🔍 [BLE SCAN] Starting FlutterBluePlus.startScan()...
🔍 [BLE SCAN] Scan started, waiting 30s for results...
🔍 [BLE SCAN] Scan update: 5 total devices found
📱 [BLE SCAN] Device: MushPi-Init (B8:27:EB:D8:B5:5D) RSSI: -45dBm
✅ [BLE SCAN] MATCHED MushPi: MushPi-Init [Name:true, UUID:true] RSSI:-45dBm
📱 [BLE SCAN] Device: iPhone (XX:XX:XX:XX:XX:XX) RSSI: -60dBm
❌ [BLE SCAN] NOT MushPi: iPhone (checks failed)
🔍 [BLE SCAN] Timeout reached, stopping scan...
🛑 [BLE SCAN] Stopping scan...
✅ [BLE SCAN] Scan stopped
✅ [BLE SCAN] ============ SCAN COMPLETE ============
✅ [BLE SCAN] Found 1 MushPi device(s)
```

### Successful Connection
```
🔗 [BLE] Connecting to MushPi-Init (B8:27:EB:D8:B5:5D)
🔗 [BLE] Setting up connection state listener...
🔗 [BLE] Calling device.connect()...
✅ [BLE] Device.connect() completed
🔍 [BLE DISCOVER] Discovering services...
🔍 [BLE DISCOVER] Found 3 service(s)
  📋 [BLE DISCOVER] Service UUID: 0000180f-0000-1000-8000-00805f9b34fb
  📋 [BLE DISCOVER] Service UUID: 12345678-1234-5678-1234-56789abcdef0
🔍 [BLE DISCOVER] Looking for MushPi service: 12345678-1234-5678-1234-56789abcdef0
✅ [BLE DISCOVER] Found MushPi service with 5 characteristic(s)
  📋 [BLE DISCOVER] Characteristic: 12345678-1234-5678-1234-56789abcdef1 [Read, Notify]
    ✅ [BLE DISCOVER] Mapped to: Environmental Measurements
  📋 [BLE DISCOVER] Characteristic: 12345678-1234-5678-1234-56789abcdef2 [Read, Write]
    ✅ [BLE DISCOVER] Mapped to: Control Targets
  📋 [BLE DISCOVER] Characteristic: 12345678-1234-5678-1234-56789abcdef3 [Read, Write]
    ✅ [BLE DISCOVER] Mapped to: Stage State
  📋 [BLE DISCOVER] Characteristic: 12345678-1234-5678-1234-56789abcdef4 [Write]
    ✅ [BLE DISCOVER] Mapped to: Override Bits
  📋 [BLE DISCOVER] Characteristic: 12345678-1234-5678-1234-56789abcdef5 [Read, Notify]
    ✅ [BLE DISCOVER] Mapped to: Status Flags
✅ [BLE DISCOVER] All 5 characteristics discovered and mapped
🔔 [BLE NOTIFY] Subscribing to notifications...
🔔 [BLE NOTIFY] Enabling notifications for Environmental Measurements...
✅ [BLE NOTIFY] Environmental Measurements notifications enabled
🔔 [BLE NOTIFY] Enabling notifications for Status Flags...
✅ [BLE NOTIFY] Status Flags notifications enabled
✅ [BLE NOTIFY] All notifications subscribed successfully
✅ [BLE NOTIFY] Ready to receive data from device
✅ [BLE] Successfully connected to MushPi-Init
```

### Data Reception Flow
```
📦 BLE PACKET RECEIVED [Environmental]: 18 bytes - Raw: [210, 7, 232, 3, 160, 1, 50, 0, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0]
📊 PARSED DATA [Environmental]: Temp=22.5°C, RH=65.0%, CO2=450ppm, Light=78
✅ [SensorListener] Received environmental data:
  Farm: 5e80ed0f-d1ff-4695-96c8-4389030d4b0c
  Temperature: 22.5°C
  Humidity: 65.0%
  CO₂: 450 ppm
  Light: 78
✅ [SensorListener] Successfully saved reading to database
```

### Disconnection
```
🔌 [BLE DISCONNECT] Disconnecting from device...
🔌 [BLE DISCONNECT] Cancelling notification subscriptions...
🔌 [BLE DISCONNECT] Disconnecting MushPi-Init...
🧹 [BLE DISCONNECT] Cleaning up connection state...
✅ [BLE DISCONNECT] Cleanup complete
✅ [BLE DISCONNECT] Disconnected successfully
```

---

## 🐛 Troubleshooting Patterns

### Problem: No devices found in scan

**Look for:**
```
🔍 [BLE SCAN] Found 0 MushPi device(s)
```

**Check:**
- Are ANY devices found? Look for `📱 [BLE SCAN] Device:` lines
- If yes, why rejected? Look for `❌ [BLE SCAN] NOT MushPi:` with reasons
- Is Bluetooth on? Look for `✅ [BLE] Bluetooth is ON`

---

### Problem: Device found but won't connect

**Look for:**
```
❌ [BLE] Connection failed: <error>
```

**Check:**
- Did services discovery succeed? Look for `✅ [BLE DISCOVER] Found MushPi service`
- Are all 5 characteristics found? Look for `✅ [BLE DISCOVER] All 5 characteristics`
- Did connection timeout? Look for timeout errors

---

### Problem: Connected but no data

**Look for:**
```
✅ [BLE NOTIFY] Ready to receive data from device
[NO PACKETS AFTER THIS]
```

**Check:**
- Are notifications enabled? Should see both Environmental and Status enabled
- Is Pi sending? Check Pi logs: `sudo journalctl -u mushpi.service -f`
- Is sensor listener active? Look for `✅ [SensorListener] Identified farm:`

---

### Problem: Data received but not saved

**Look for:**
```
📦 BLE PACKET RECEIVED [Environmental]: ...
[NO "Successfully saved" AFTER THIS]
```

**Check:**
- Is farm identified? Look for `✅ [SensorListener] Identified farm:`
- Is debouncing active? Look for `⏭️ [SensorListener] Debouncing`
- Database errors? Look for `❌ [SensorListener] Failed to save`

---

### Problem: Data saved but not displayed

**Check:**
- Is monitoring screen querying correct farm? Check selected farm ID
- Is auto-refresh working? Look for refresh logs every 30s
- Database empty? Query directly in DevTools

---

## 💡 Pro Tips

### 1. Watch in Real-Time
```bash
# Follow logs as they happen
flutter run -v 2>&1 | grep --line-buffered -E "BLE|SensorListener"
```

### 2. Count Events
```bash
# Count how many devices found
flutter run -v 2>&1 | grep "📱 \[BLE SCAN\] Device:" | wc -l

# Count data packets received
flutter run -v 2>&1 | grep "📦 BLE PACKET RECEIVED" | wc -l

# Count successful saves
flutter run -v 2>&1 | grep "Successfully saved reading" | wc -l
```

### 3. Time Analysis
```bash
# Show timestamps (pipe through this)
flutter run -v 2>&1 | grep -E "BLE|SensorListener" | ts '[%Y-%m-%d %H:%M:%S]'
```

### 4. Extract Specific Data
```bash
# Extract all temperature readings
flutter run -v 2>&1 | grep "PARSED DATA" | grep -oP 'Temp=\K[\d.]+°C'

# Extract all RSSI values
flutter run -v 2>&1 | grep "RSSI:" | grep -oP 'RSSI: \K-?\d+'
```

### 5. Compare Before/After Connection
```bash
# Before connection (scan phase)
flutter run -v 2>&1 | grep "BLE SCAN" > before_connect.log

# After connection (notification phase)
flutter run -v 2>&1 | grep "BLE PACKET" > after_connect.log
```

---

## 📊 Log Analysis Checklist

When debugging "no sensor readings" issue, check these in order:

- [ ] **Scan**: `✅ [BLE SCAN] Found 1 MushPi device(s)`
- [ ] **Connect**: `✅ [BLE] Successfully connected`
- [ ] **Services**: `✅ [BLE DISCOVER] All 5 characteristics discovered`
- [ ] **Notifications**: `✅ [BLE NOTIFY] Ready to receive data`
- [ ] **Listener**: `✅ [SensorListener] Identified farm:`
- [ ] **Packets**: `📦 BLE PACKET RECEIVED [Environmental]:`
- [ ] **Save**: `✅ [SensorListener] Successfully saved reading`
- [ ] **Display**: Check monitoring screen UI

If any step fails, that's where the problem is!

---

**Updated:** November 6, 2025
**Version:** 1.0
