#!/bin/bash
# Bluetooth and D-Bus Diagnostic Script for MushPi
# This script checks common issues that prevent BLE advertising

echo "=================================================="
echo "MushPi Bluetooth Diagnostics"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}⚠ Running as root. Some checks may not reflect normal user permissions.${NC}"
    echo ""
fi

# 1. Check Bluetooth service status
echo "1. Bluetooth Service Status:"
if systemctl is-active --quiet bluetooth; then
    echo -e "   ${GREEN}✓ bluetooth.service is running${NC}"
else
    echo -e "   ${RED}✗ bluetooth.service is NOT running${NC}"
    echo "   Fix: sudo systemctl start bluetooth"
    echo "        sudo systemctl enable bluetooth"
fi
echo ""

# 2. Check BlueZ version
echo "2. BlueZ Version:"
if command -v bluetoothctl &> /dev/null; then
    VERSION=$(bluetoothctl --version 2>&1 | head -n 1)
    echo "   $VERSION"
    
    # Extract version number and check if it's >= 5.43 (when LEAdvertisingManager1 was added)
    VERSION_NUM=$(echo "$VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
    if [ -n "$VERSION_NUM" ]; then
        # Compare versions (basic comparison)
        MAJOR=$(echo "$VERSION_NUM" | cut -d. -f1)
        MINOR=$(echo "$VERSION_NUM" | cut -d. -f2)
        
        if [ "$MAJOR" -gt 5 ] || ([ "$MAJOR" -eq 5 ] && [ "$MINOR" -ge 43 ]); then
            echo -e "   ${GREEN}✓ BlueZ $VERSION_NUM supports LEAdvertisingManager1${NC}"
        else
            echo -e "   ${YELLOW}⚠ BlueZ $VERSION_NUM may not fully support LEAdvertisingManager1${NC}"
            echo "   (Requires BlueZ 5.43+, you have $VERSION_NUM)"
            echo "   Service will still work but advertising may be limited"
            echo "   Fix: sudo apt-get update && sudo apt-get install bluez"
        fi
    fi
    echo -e "   ${GREEN}✓ bluetoothctl is available${NC}"
else
    echo -e "   ${RED}✗ bluetoothctl not found${NC}"
    echo "   Fix: sudo apt-get install bluez"
fi
echo ""

# 3. Check hci0 adapter
echo "3. Bluetooth Adapter (hci0):"
if hciconfig hci0 &> /dev/null; then
    HCI_INFO=$(hciconfig hci0 2>&1)
    if echo "$HCI_INFO" | grep -q "UP RUNNING"; then
        echo -e "   ${GREEN}✓ hci0 adapter is UP and RUNNING${NC}"
    else
        echo -e "   ${YELLOW}⚠ hci0 adapter exists but may not be running${NC}"
        echo "   Fix: sudo hciconfig hci0 up"
    fi
    echo "   Status: $(hciconfig hci0 | grep -E 'UP|DOWN|RUNNING')"
else
    echo -e "   ${RED}✗ hci0 adapter not found${NC}"
    echo "   This may indicate hardware or driver issues"
fi
echo ""

# 4. Check user group membership
echo "4. User Group Membership:"
CURRENT_USER=${SUDO_USER:-$USER}
if groups $CURRENT_USER | grep -q bluetooth; then
    echo -e "   ${GREEN}✓ User '$CURRENT_USER' is in 'bluetooth' group${NC}"
else
    echo -e "   ${RED}✗ User '$CURRENT_USER' is NOT in 'bluetooth' group${NC}"
    echo "   Fix: sudo usermod -a -G bluetooth $CURRENT_USER"
    echo "        Then log out and back in for changes to take effect"
fi
echo ""

# 5. Check D-Bus service
echo "5. D-Bus System Bus:"
if systemctl is-active --quiet dbus; then
    echo -e "   ${GREEN}✓ dbus.service is running${NC}"
else
    echo -e "   ${RED}✗ dbus.service is NOT running${NC}"
    echo "   Fix: sudo systemctl start dbus"
fi

# Try to connect to system bus
if dbus-send --system --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.GetId &> /dev/null; then
    echo -e "   ${GREEN}✓ D-Bus system bus is accessible${NC}"
else
    echo -e "   ${RED}✗ Cannot connect to D-Bus system bus${NC}"
fi
echo ""

# 6. Check for BlueZ on D-Bus
echo "6. BlueZ D-Bus Registration:"
if dbus-send --system --print-reply --dest=org.bluez / org.freedesktop.DBus.Introspectable.Introspect &> /dev/null; then
    echo -e "   ${GREEN}✓ BlueZ is registered on D-Bus${NC}"
else
    echo -e "   ${RED}✗ BlueZ is NOT registered on D-Bus${NC}"
    echo "   Fix: sudo systemctl restart bluetooth"
fi
echo ""

# 7. Check for existing advertisements
echo "7. Active BLE Advertisements:"
ADVERTS=$(dbus-send --system --print-reply --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -c "node name=\"advertisement")
if [ "$ADVERTS" -gt 0 ]; then
    echo -e "   ${YELLOW}⚠ Found $ADVERTS active advertisement(s)${NC}"
    echo "   If MushPi is not running, these may be stale and should be cleaned up"
else
    echo -e "   ${GREEN}✓ No active advertisements found${NC}"
fi
echo ""

# 7b. Check for LEAdvertisingManager1 interface
echo "7b. LEAdvertisingManager1 Interface:"
if dbus-send --system --print-reply --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -q "LEAdvertisingManager1"; then
    echo -e "   ${GREEN}✓ LEAdvertisingManager1 interface is available${NC}"
else
    echo -e "   ${YELLOW}⚠ LEAdvertisingManager1 interface NOT available${NC}"
    echo "   This interface was added in BlueZ 5.43+"
    echo "   Your BlueZ version may be too old for full BLE advertising support"
    echo "   Fix: sudo apt-get update && sudo apt-get install bluez"
fi
echo ""

# 8. Check Python D-Bus libraries
echo "8. Python D-Bus Libraries:"
if python3 -c "import dbus" 2>/dev/null; then
    echo -e "   ${GREEN}✓ python3-dbus is installed${NC}"
else
    echo -e "   ${RED}✗ python3-dbus is NOT installed${NC}"
    echo "   Fix: sudo apt-get install python3-dbus"
fi

if python3 -c "from gi.repository import GLib" 2>/dev/null; then
    echo -e "   ${GREEN}✓ python3-gi is installed${NC}"
else
    echo -e "   ${RED}✗ python3-gi is NOT installed${NC}"
    echo "   Fix: sudo apt-get install python3-gi"
fi
echo ""

# 9. Check for RFKILL blocks
echo "9. Radio Frequency Kill Switch (rfkill):"
if command -v rfkill &> /dev/null; then
    BLUETOOTH_BLOCKED=$(rfkill list bluetooth | grep -c "Soft blocked: yes")
    if [ "$BLUETOOTH_BLOCKED" -gt 0 ]; then
        echo -e "   ${RED}✗ Bluetooth is soft-blocked by rfkill${NC}"
        echo "   Fix: sudo rfkill unblock bluetooth"
    else
        echo -e "   ${GREEN}✓ Bluetooth is not blocked by rfkill${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ rfkill command not found (install with: sudo apt-get install rfkill)${NC}"
fi
echo ""

# 10. Test D-Bus advertisement registration
echo "10. Test D-Bus Advertisement Registration:"
echo "    Attempting to register a test advertisement..."

# Create a minimal test script
TEST_RESULT=$(python3 - << 'EOF' 2>&1
import sys
try:
    import dbus
    import dbus.mainloop.glib
    from gi.repository import GLib
    
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus(private=False)
    
    # Just try to get the advertising manager interface
    ad_manager = dbus.Interface(
        bus.get_object('org.bluez', '/org/bluez/hci0', introspect=False),
        'org.bluez.LEAdvertisingManager1'
    )
    
    print("SUCCESS: Can access BlueZ advertising manager via D-Bus")
    sys.exit(0)
except dbus.exceptions.DBusException as e:
    print(f"D-Bus Error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
)

if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ D-Bus advertisement interface is accessible${NC}"
else
    echo -e "    ${RED}✗ Failed to access D-Bus advertisement interface${NC}"
    echo "    Error: $TEST_RESULT"
fi
echo ""

# Summary
echo "=================================================="
echo "Diagnostic Summary"
echo "=================================================="
echo ""
echo "Common fixes for 'NoReply' errors:"
echo "  1. Restart Bluetooth: sudo systemctl restart bluetooth"
echo "  2. Add user to group: sudo usermod -a -G bluetooth \$USER"
echo "  3. Ensure hci0 is up: sudo hciconfig hci0 up"
echo "  4. Check for blocks: sudo rfkill unblock bluetooth"
echo "  5. Increase D-Bus timeout (already done in updated code)"
echo ""
echo "If issues persist:"
echo "  - Check 'dmesg | grep -i bluetooth' for hardware errors"
echo "  - Check 'journalctl -u bluetooth -n 50' for service logs"
echo "  - Verify Bluetooth hardware: lsusb | grep -i bluetooth"
echo ""
