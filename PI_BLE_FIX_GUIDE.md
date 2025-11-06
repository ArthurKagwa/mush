# Pi BLE Not Advertising - Quick Fix Guide

## Problem Identified

Your Raspberry Pi's Bluetooth is **NOT advertising properly**:
- ❌ No device name in advertising packet
- ❌ No service UUID in advertising packet
- All devices show as "Unknown" with "UUIDs: none"

This is a **Pi configuration issue**, not an app issue.

---

## Immediate Workaround (App Side)

I've enabled DEBUG mode in the app so you can see ALL devices (including "Unknown" ones).

**To test the app now:**

1. **Hot restart the Flutter app**:
   ```bash
   flutter run
   ```

2. **You'll now see ALL BLE devices** in the scan list
   - They'll show as "Unknown" 
   - Look for the device with the **strongest RSSI** (closest to 0, like -40 to -70)
   - That's probably your Pi if it's nearby

3. **Try connecting** to an "Unknown" device
   - If it's your Pi, the connection will work
   - If not, try another one

**This is temporary** - we need to fix the Pi advertising properly.

---

## Fix the Pi (Proper Solution)

### Step 1: Run Diagnostic Script

**On your Raspberry Pi:**

```bash
# Copy the diagnostic script (already created at /Users/arthur/dev/mush/pi_ble_diagnostic.sh)
# Transfer it to Pi, then:
chmod +x pi_ble_diagnostic.sh
./pi_ble_diagnostic.sh
```

**Share the output** - it will tell us what's wrong.

---

### Step 2: Quick Pi BLE Fixes

**Try these commands on the Pi:**

```bash
# 1. Restart Bluetooth
sudo systemctl restart bluetooth
sleep 2

# 2. Configure adapter
sudo hciconfig hci0 down
sudo hciconfig hci0 up
sudo hciconfig hci0 piscan
sudo hciconfig hci0 leadv

# 3. Make discoverable via bluetoothctl
sudo bluetoothctl << EOF
power on
discoverable on
pairable on
EOF

# 4. Restart MushPi service
sudo systemctl restart mushpi.service

# 5. Check status
sudo systemctl status mushpi.service
```

---

### Step 3: Check MushPi Service

**Look for this in the logs:**

```bash
sudo journalctl -u mushpi.service -n 50 --no-pager | grep -i advertising
```

**Should see:**
```
BLE GATT service started - advertising as 'MushPi-OysterPinning'
```

**If you see errors:**
- Share the error messages
- Check Python BLE code is running

---

### Step 4: Verify Advertising

**Test if Pi is advertising:**

```bash
# On Pi itself
sudo hcitool -i hci0 cmd 0x08 0x0008 1E 02 01 1A 1A FF 4C 00 02 15 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 C8

# Check adapter settings
sudo bluetoothctl show
```

**Should show:**
- Powered: yes
- Discoverable: yes
- Pairable: yes

---

## Common Pi BLE Issues

### Issue 1: BlueZ Not Running
```bash
sudo systemctl status bluetooth
# If inactive:
sudo systemctl start bluetooth
sudo systemctl enable bluetooth
```

### Issue 2: Adapter Not Powered
```bash
sudo rfkill unblock bluetooth
sudo hciconfig hci0 up
```

### Issue 3: MushPi Service Not Starting BLE
```bash
# Check Python BLE service
sudo journalctl -u mushpi.service -f
# Should show: "BLE GATT service started"
```

### Issue 4: bluezero Library Issue
```bash
# Reinstall bluezero
pip3 install --upgrade bluezero

# Or try using D-Bus directly
sudo apt-get install --reinstall bluez
```

---

## Testing BLE Advertising

**Use nRF Connect app** on your phone:
1. Open nRF Connect
2. Scan for devices
3. Look for "MushPi-..." device
4. Check if service UUID `12345678-...` is visible
5. If YES → Problem is in Flutter app filtering
6. If NO → Problem is in Pi advertising

---

## What Logs to Share

Please share these:

1. **Pi diagnostic output**:
   ```bash
   ./pi_ble_diagnostic.sh > diagnostic.txt 2>&1
   cat diagnostic.txt
   ```

2. **MushPi service logs**:
   ```bash
   sudo journalctl -u mushpi.service -n 100 --no-pager
   ```

3. **Bluetooth adapter status**:
   ```bash
   hciconfig -a
   sudo bluetoothctl show
   ```

4. **What you see in nRF Connect** (screenshot if possible)

---

## Debug Mode Cleanup

**Once Pi advertising is fixed**, disable debug mode in the app:

File: `lib/data/repositories/ble_repository.dart`
```dart
static const bool _debugShowAllDevices = false; // Change true → false
```

---

## Next Steps

1. ✅ Run the app now (you'll see all devices)
2. ⚠️ Try connecting to "Unknown" devices to find your Pi
3. 🔧 Run diagnostic script on Pi
4. 📤 Share Pi logs so we can fix advertising

**The app is ready to test - the Pi needs fixing!**
