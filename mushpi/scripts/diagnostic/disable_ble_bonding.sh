#!/bin/bash
# Disable BLE bonding/pairing requirement for MushPi
# This allows the Flutter app to connect without pairing

echo "🔧 Disabling BLE bonding/pairing requirement..."

# Stop bluetooth service
sudo systemctl stop bluetooth

# Configure BlueZ to not require bonding
sudo mkdir -p /etc/bluetooth
sudo tee /etc/bluetooth/main.conf > /dev/null << 'EOF'
[General]
# Disable pairing/bonding requirement
Class = 0x000100
DiscoverableTimeout = 0
PairableTimeout = 0
Pairable = no

# Privacy settings
Privacy = device

# GATT cache
Cache = no

[Policy]
AutoEnable=true
EOF

# Restart bluetooth service
sudo systemctl start bluetooth

echo "✅ BLE bonding disabled"
echo ""
echo "📋 Bluetooth service status:"
sudo systemctl status bluetooth --no-pager | head -n 10
echo ""
echo "🔄 Please restart the MushPi service:"
echo "   sudo systemctl restart mushpi"
