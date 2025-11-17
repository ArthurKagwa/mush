#!/bin/bash
# MushPi BLE Diagnostic Script
# Run this ON THE RASPBERRY PI to diagnose BLE advertising issues

echo "========================================="
echo "MushPi BLE Diagnostic Script"
echo "========================================="
echo ""

# Check Bluetooth adapter status
echo "1. Bluetooth Adapter Status:"
echo "----------------------------"
hciconfig -a
echo ""

# Check if adapter is UP and RUNNING
echo "2. Adapter State:"
echo "----------------"
if hciconfig hci0 | grep -q "UP RUNNING"; then
    echo "✅ Adapter is UP and RUNNING"
else
    echo "❌ Adapter is NOT running properly"
    echo "   Trying to bring it up..."
    sudo hciconfig hci0 up
    sudo hciconfig hci0 piscan
fi
echo ""

# Check BlueZ version
echo "3. BlueZ Version:"
echo "----------------"
bluetoothctl --version
echo ""

# Check if MushPi service is running
echo "4. MushPi Service Status:"
echo "------------------------"
if systemctl is-active --quiet mushpi.service; then
    echo "✅ MushPi service is running"
    sudo systemctl status mushpi.service --no-pager -l | tail -n 20
else
    echo "❌ MushPi service is NOT running"
    echo "   Starting it now..."
    sudo systemctl start mushpi.service
    sleep 2
    sudo systemctl status mushpi.service --no-pager -l | tail -n 20
fi
echo ""

# Check BLE advertising
echo "5. Current BLE Advertising:"
echo "--------------------------"
sudo hcitool -i hci0 lescan --duplicates 2>&1 | head -n 10 &
SCAN_PID=$!
sleep 3
sudo kill $SCAN_PID 2>/dev/null
echo ""

# Check adapter properties
echo "6. Bluetooth Adapter Properties:"
echo "--------------------------------"
sudo bluetoothctl show
echo ""

# Check for advertising
echo "7. Checking if device is discoverable:"
echo "--------------------------------------"
if hciconfig hci0 | grep -q "ISCAN"; then
    echo "✅ Device is discoverable (ISCAN enabled)"
else
    echo "❌ Device is NOT discoverable"
    echo "   Enabling discoverability..."
    sudo hciconfig hci0 piscan
fi
echo ""

# Check MushPi logs for BLE startup
echo "8. Recent MushPi BLE Logs:"
echo "-------------------------"
sudo journalctl -u mushpi.service -n 30 --no-pager | grep -i "ble\|bluetooth\|advertising"
echo ""

# Check Python BLE service
echo "9. Testing Python BLE Service:"
echo "------------------------------"
python3 <<EOF
import sys
sys.path.append('/home/pi/mushpi')

try:
    from app.core.ble_gatt import get_status
    status = get_status()
    print(f"BLE Service Running: {status.get('running', False)}")
    print(f"Connected Clients: {status.get('connected_clients', 0)}")
    print(f"Uptime: {status.get('uptime_seconds', 0)} seconds")
except Exception as e:
    print(f"❌ Error checking BLE service: {e}")
EOF
echo ""

# Check config
echo "10. MushPi BLE Configuration:"
echo "----------------------------"
if [ -f /home/pi/mushpi/.env ]; then
    echo "Config file found:"
    grep -E "BLE|BLUETOOTH" /home/pi/mushpi/.env 2>/dev/null || echo "No BLE config found in .env"
else
    echo "⚠️  No .env file found"
fi
echo ""

echo "========================================="
echo "Diagnostic Complete"
echo "========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Check if adapter is UP and RUNNING (section 1)"
echo "2. Check if MushPi service started successfully (section 4)"
echo "3. Look for 'advertising as' message in logs (section 8)"
echo "4. Share the output with the developer"
echo ""
