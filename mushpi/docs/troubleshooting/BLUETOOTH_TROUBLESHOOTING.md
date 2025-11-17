# Bluetooth BLE Troubleshooting Guide

## Overview
This guide addresses the D-Bus `NoReply` error that can occur when registering BLE advertisements on Raspberry Pi:

```
ERROR:app.ble.service:Failed to register D-Bus advertisement: 
org.freedesktop.DBus.Error.NoReply: Did not receive a reply...
```

## What Changed

### Code Improvements in `app/ble/service.py`

1. **Extended D-Bus Timeout** (60 seconds)
   - Default 25-second timeout is often too short for Raspberry Pi hardware
   - New code uses `timeout=60` in `RegisterAdvertisement()` call

2. **Better Error Handling**
   - Gracefully handles timeout errors and continues operation
   - Service remains discoverable via adapter name even if explicit advertisement fails
   - Specific error messages for different D-Bus failure modes

3. **Advertisement Cleanup**
   - Automatically cleans up stale advertisements from previous crashed runs
   - Uses unique timestamp-based paths to avoid conflicts

4. **Improved D-Bus Connection**
   - Uses `private=False` for shared system bus connection
   - Adds `introspect=False` to reduce initial connection overhead
   - Better mainloop initialization

5. **Configurable Timeouts and Retries (via .env)**
   - `MUSHPI_BLE_GATT_PUBLISH_TIMEOUT_SEC` — max seconds to wait for GATT publish thread before continuing (default 10)
   - `MUSHPI_BLE_ADV_STABILIZATION_DELAY_MS` — delay after powering/marking adapter discoverable before registering advertisement (default 0)
   - `MUSHPI_BLE_ADV_REGISTER_RETRIES` — number of retries for `RegisterAdvertisement` on transient failures (default 0)
   - `MUSHPI_BLE_ADV_REGISTER_BACKOFF_MS` — base backoff between retries (exponential, default 0)
   - `MUSHPI_BLE_ADV_REGISTER_BACKOFF_MAX_MS` — cap for backoff delay (default 0)

## Quick Fixes

### 1. Restart Bluetooth Service
```bash
sudo systemctl restart bluetooth
```

### 2. Verify User Permissions
```bash
# Add your user to bluetooth group
sudo usermod -a -G bluetooth $USER

# Log out and back in for changes to take effect
# Or use:
newgrp bluetooth
```

### 3. Check Adapter Status
```bash
# Ensure hci0 is up
sudo hciconfig hci0 up

# Check for radio blocks
sudo rfkill unblock bluetooth
```

### 4. Run Diagnostic Script
```bash
cd /opt/mushpi  # or your MushPi directory
chmod +x diagnose_bluetooth.sh
./diagnose_bluetooth.sh
```

## Understanding the Error

The `NoReply` error typically means one of:

1. **BlueZ daemon is slow/overloaded** - Fixed by increasing timeout
2. **D-Bus permissions issue** - Fixed by adding user to `bluetooth` group
3. **Stale advertisement registered** - Fixed by cleanup logic in new code
4. **Bluetooth adapter not ready** - Fixed by checking `hciconfig hci0 up`

## What the Code Does Now

### Before (Old Behavior)
```python
# Short timeout, no cleanup, crashes on error
ad_manager.RegisterAdvertisement(advertisement.path, {})
```

### After (New Behavior)
```python
# 1. Clean up any stale advertisements
try:
    ad_manager.UnregisterAdvertisement(old_path, timeout=5)
except:
    pass  # No previous advertisement is fine

# 2. Register with extended timeout
ad_manager.RegisterAdvertisement(
    advertisement.path,
    {},
    timeout=60  # 60 seconds for slow Pi
)

# 3. Graceful error handling
except dbus.exceptions.DBusException as e:
    if 'NoReply' in str(e):
        logger.error("D-Bus timeout - continuing anyway")
        # Service still works via adapter name
```

## Service Still Works!

Even if the D-Bus advertisement registration fails, your BLE service **will still work**:

- The GATT service is registered via BlueZero
- The adapter name is set correctly
- The service UUID may not appear in scan results, but:
  - Mobile apps can still connect by name
  - Once connected, all characteristics work normally
  - Only the advertising packet lacks the service UUID

## Verification

After deploying the updated code:

1. **Check logs** - Should see:
   ```
   INFO:app.ble.service:Advertisement registered: name='MushPi-Init' uuid=...
   ```
   
   Or if timeout occurs:
   ```
   ERROR:app.ble.service:D-Bus timeout during advertisement registration...
   INFO:app.ble.service:Continuing without explicit advertisement registration...
   ```

2. **Test scanning** from your mobile device:
   ```
   - Look for "MushPi-Init" in BLE scanner
   - Connect to it
   - Verify characteristics are readable
   ```

3. **Check D-Bus** directly:
   ```bash
   # See if advertisement is registered
   dbus-send --system --print-reply --dest=org.bluez \
     /org/bluez/hci0 \
     org.freedesktop.DBus.Introspectable.Introspect
   ```

## Long-term Monitoring

The updated code logs detailed information about D-Bus failures. Monitor your service logs:

```bash
# If using systemd
journalctl -u mushpi.service -f

# Or check log file if configured
tail -f /opt/mushpi/logs/mushpi.log
```

## Hardware Considerations

Some Raspberry Pi models have different Bluetooth hardware:

- **Pi 3/4/Zero W** - Built-in Bluetooth (usually reliable)
- **Pi with USB dongle** - May need driver configuration
- **Pi 5** - May have different BlueZ requirements

If problems persist after applying fixes, check:
```bash
# Hardware detection
lsusb | grep -i bluetooth

# Kernel messages
dmesg | grep -i bluetooth

# Service logs
journalctl -u bluetooth -n 100
```

## Related Files

- `app/ble/service.py` - Main BLE service (updated with fixes)
- `diagnose_bluetooth.sh` - Diagnostic script
- `pi_ble_diagnostic.sh` - Additional BLE diagnostics
- `verify_ble_advertising.sh` - Advertisement verification

## Further Reading

- BlueZ D-Bus API: https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc
- Raspberry Pi Bluetooth: https://www.raspberrypi.com/documentation/computers/configuration.html#bluetooth
- D-Bus timeout issues: Common on Pi Zero and older Pi 3 models
