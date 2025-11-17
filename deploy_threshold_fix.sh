#!/bin/bash
# Deploy threshold fix to Raspberry Pi
# This script uploads the updated files and restarts the service

# Configuration
PI_USER="pi"
PI_HOST="${1:-raspberrypi.local}"  # Use first argument or default to raspberrypi.local
PI_MUSHPI_DIR="/opt/mushpi/mushpi"

echo "🚀 Deploying threshold fix to $PI_HOST..."
echo ""

# Check if we can reach the Pi
if ! ping -c 1 "$PI_HOST" > /dev/null 2>&1; then
    echo "❌ Cannot reach $PI_HOST"
    echo "Usage: $0 <pi-hostname-or-ip>"
    exit 1
fi

echo "📤 Uploading updated files..."
echo ""

# Upload main.py
echo "  • mushpi/main.py"
scp mushpi/main.py "$PI_USER@$PI_HOST:$PI_MUSHPI_DIR/main.py" || {
    echo "❌ Failed to upload main.py"
    exit 1
}

# Upload database manager
echo "  • mushpi/app/database/manager.py"
scp mushpi/app/database/manager.py "$PI_USER@$PI_HOST:$PI_MUSHPI_DIR/app/database/manager.py" || {
    echo "❌ Failed to upload database/manager.py"
    exit 1
}

# Upload stage manager
echo "  • mushpi/app/core/stage.py"
scp mushpi/app/core/stage.py "$PI_USER@$PI_HOST:$PI_MUSHPI_DIR/app/core/stage.py" || {
    echo "❌ Failed to upload core/stage.py"
    exit 1
}

echo ""
echo "✅ Files uploaded successfully"
echo ""

# Restart the service
echo "🔄 Restarting mushpi service..."
ssh "$PI_USER@$PI_HOST" "sudo systemctl restart mushpi" || {
    echo "❌ Failed to restart service"
    exit 1
}

echo ""
echo "⏳ Waiting for service to start..."
sleep 3

# Check service status
echo ""
echo "📊 Service status:"
ssh "$PI_USER@$PI_HOST" "sudo systemctl status mushpi --no-pager -l | head -20"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 To view logs in real-time:"
echo "   ssh $PI_USER@$PI_HOST 'sudo journalctl -u mushpi -f'"
echo ""
echo "🔍 Look for these log messages:"
echo "   ✅ Control system initialized with X thresholds"
echo "   📖 BLE requesting thresholds for: Oyster - Incubation"
echo "   ✅ Returning thresholds from database for Oyster - Incubation"
echo ""
