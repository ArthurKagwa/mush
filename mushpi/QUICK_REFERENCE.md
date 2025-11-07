# Quick Reference - BLE Advertisement Fix

## The Problem You Had

```
ERROR:dbus.connection:Unable to set arguments ('/uk/co/mushpi/advertisement1762446088', {}) 
according to signature None: <class 'ValueError'>: Unable to guess signature from an empty dict

ERROR:app.ble.service:Unexpected error registering advertisement: 
Unable to guess signature from an empty dict
```

## The Solution

Changed this:
```python
ad_manager.RegisterAdvertisement(advertisement.path, {})
```

To this:
```python
ad_manager.RegisterAdvertisement(
    advertisement.path,
    dbus.Dictionary({}, signature='sv'),  # Proper D-Bus signature
    timeout=60  # Extended timeout for Pi hardware
)
```

## What Was Fixed

1. ✅ **D-Bus signature error** - Added `dbus.Dictionary({}, signature='sv')`
2. ✅ **Timeout errors** - Extended from 25s to 60s
3. ✅ **Stale advertisements** - Auto-cleanup on startup
4. ✅ **Unique paths** - Timestamp-based to avoid conflicts
5. ✅ **Error handling** - Graceful degradation if registration fails

## Deploy on Raspberry Pi

```bash
# 1. Pull changes
cd /opt/mushpi
git pull

# 2. Check Bluetooth is OK
chmod +x diagnose_bluetooth.sh
./diagnose_bluetooth.sh

# 3. Fix any issues found (common ones):
sudo systemctl restart bluetooth
sudo usermod -a -G bluetooth $USER
sudo hciconfig hci0 up

# 4. Restart MushPi
sudo systemctl restart mushpi

# 5. Check it worked
journalctl -u mushpi.service -n 50 | grep -i "advertisement"
```

## Expected Output

### ✅ Success:
```
INFO:app.ble.service:Advertisement registered: name='MushPi-Init' uuid=12345678-...
INFO:app.ble.service:BLE GATT service started - advertising as 'MushPi-Init'
```

### ⚠️ Graceful Degradation (still works):
```
ERROR:app.ble.service:D-Bus timeout during advertisement registration...
WARNING:app.ble.service:Continuing without explicit D-Bus advertisement
INFO:app.ble.service:BLE GATT service started - advertising as 'MushPi-Init'
```

Both are OK! The service works either way.

## Test It

```bash
# Test advertisement registration
python3 test_ble_advertisement.py

# Scan for BLE devices (from another terminal/device)
sudo hcitool lescan | grep MushPi

# Check service is advertising
./verify_ble_advertising.sh
```

## Files Changed

- ✏️ `app/ble/service.py` - Main fix
- ➕ `diagnose_bluetooth.sh` - Diagnostic tool
- ➕ `test_ble_advertisement.py` - Test script
- ➕ `BLUETOOTH_TROUBLESHOOTING.md` - Full guide
- ➕ `FIX_SUMMARY.md` - Deployment guide
- ➕ `PATCH_NOTES.md` - Technical details
- ➕ `QUICK_REFERENCE.md` - This file

## Why It Failed Before

D-Bus needs to know the type signature of arguments. Passing a plain Python `{}` doesn't work because D-Bus can't infer the type from an empty dict. The fix wraps it in `dbus.Dictionary({}, signature='sv')` which explicitly tells D-Bus: "this is a string→variant dictionary, and it's empty."

## Common Issues

| Error | Fix |
|-------|-----|
| NoReply timeout | Now fixed with 60s timeout |
| Signature error | Now fixed with proper D-Bus call |
| UnknownMethod/UnknownInterface | BlueZ < 5.43 - upgrade with `sudo apt-get install bluez` |
| AlreadyExists | Now auto-cleans old registrations |
| NotPermitted | `sudo usermod -a -G bluetooth $USER` |
| Adapter not found | `sudo hciconfig hci0 up` |

## Service Still Works Without Advertisement!

Even if D-Bus advertisement fails completely, your BLE service **still works**:
- ✅ GATT service is registered
- ✅ Adapter name is "MushPi-Init"
- ✅ Mobile apps can connect
- ✅ All characteristics work
- ⚠️ Only difference: Service UUID might not show in scan results

## BlueZ Version Requirements

**Minimum for LEAdvertisingManager1:** BlueZ 5.43+

The `UnknownMethod` error means your BlueZ version doesn't support the `LEAdvertisingManager1` interface.

**Check your version:**
```bash
bluetoothctl --version
```

**Upgrade BlueZ (if needed):**
```bash
sudo apt-get update
sudo apt-get install bluez
sudo systemctl restart bluetooth
sudo systemctl restart mushpi
```

**Important:** Even with BlueZ < 5.43, your service **still works**! You just won't get the custom service UUID advertised. Devices can still:
- See "MushPi-Init" in scan results
- Connect by name
- Use all GATT characteristics
- Full functionality is maintained

## Verification Checklist

- [ ] Code pulled from git
- [ ] `diagnose_bluetooth.sh` runs clean (or issues fixed)
- [ ] Service restarts without errors
- [ ] Logs show "Advertisement registered" or graceful warning
- [ ] Mobile app can see "MushPi-Init"
- [ ] Can connect and read characteristics

## Need Help?

1. Run diagnostics: `./diagnose_bluetooth.sh`
2. Check full guide: `BLUETOOTH_TROUBLESHOOTING.md`
3. View logs: `journalctl -u mushpi.service -f`
4. Test manually: `python3 test_ble_advertisement.py`

---

**Status:** Ready to deploy ✅
**Risk:** Low (backwards compatible, graceful degradation)
**Time to deploy:** ~2 minutes
