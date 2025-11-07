#!/bin/bash
# Verify BLE Advertising Script for MushPi
# This script checks if the Raspberry Pi is properly advertising BLE services

set -e

echo "======================================"
echo "MushPi BLE Advertising Verification"
echo "======================================"
echo ""

# Check if Bluetooth adapter is up
echo "1. Checking Bluetooth adapter status..."
if hciconfig hci0 | grep -q "UP RUNNING"; then
    echo "   ✓ Bluetooth adapter hci0 is UP and RUNNING"
else
    echo "   ✗ Bluetooth adapter hci0 is not running"
    echo "   Try: sudo hciconfig hci0 up"
    exit 1
fi
echo ""

# Check Bluetooth service
echo "2. Checking Bluetooth service..."
if systemctl is-active --quiet bluetooth; then
    echo "   ✓ Bluetooth service is active"
else
    echo "   ✗ Bluetooth service is not active"
    echo "   Try: sudo systemctl start bluetooth"
    exit 1
fi
echo ""

# Check if device is discoverable
echo "3. Checking adapter discoverability..."
ADAPTER_INFO=$(bluetoothctl show | grep "Discoverable")
echo "   $ADAPTER_INFO"
echo ""

# Scan for BLE devices and look for MushPi
echo "4. Scanning for BLE devices (15 seconds)..."
echo "   Looking for devices with 'MushPi' in the name..."
echo ""

timeout 15s bluetoothctl --timeout 15 scan on 2>&1 | tee /tmp/ble_scan.log | grep -i "mushpi" || true

echo ""
echo "5. Checking scan results for MushPi devices..."
if grep -qi "mushpi" /tmp/ble_scan.log; then
    echo "   ✓ Found MushPi device(s)!"
    echo ""
    
    # Extract MAC address
    MAC=$(grep -i "mushpi" /tmp/ble_scan.log | head -1 | awk '{print $3}')
    
    if [ ! -z "$MAC" ]; then
        echo "6. Getting device info for $MAC..."
        echo ""
        timeout 5s bluetoothctl info "$MAC" || echo "   (Could not get device info)"
    fi
else
    echo "   ✗ No MushPi devices found in scan"
    echo ""
    echo "   Troubleshooting:"
    echo "   - Ensure main.py is running (preferably with sudo)"
    echo "   - Check main.py logs for 'Advertising name=' message"
    echo "   - Try: sudo python3 main.py"
fi

echo ""
echo "======================================"
echo "Advanced verification (optional):"
echo "======================================"
echo "Run these commands for detailed info:"
echo ""
echo "# Monitor raw BLE packets (shows service UUIDs):"
echo "sudo btmon"
echo ""
echo "# Use bluetoothctl interactively:"
echo "bluetoothctl"
echo "  > scan on"
echo "  > devices"
echo "  > info <MAC_ADDRESS>"
echo ""
echo "# Check current advertising data from BlueZ D-Bus:"
echo "busctl introspect org.bluez /org/bluez/hci0"
echo ""

rm -f /tmp/ble_scan.log
