#!/bin/bash
#
# Deploy database migration fix to Raspberry Pi
# This script copies the updated database manager and restarts the service
#

set -e  # Exit on error

PI_HOST="${PI_HOST:-pi@raspberrypi.local}"
PROJECT_DIR="/home/pi/mushpi"

echo "🚀 Deploying database migration fix to $PI_HOST"
echo ""

# Copy the updated database manager
echo "📦 Copying updated database manager..."
scp mushpi/app/database/manager.py "$PI_HOST:$PROJECT_DIR/app/database/manager.py"

echo ""
echo "🔄 Restarting mushpi service..."
ssh "$PI_HOST" "sudo systemctl restart mushpi"

echo ""
echo "⏳ Waiting for service to start..."
sleep 3

echo ""
echo "📋 Checking service status..."
ssh "$PI_HOST" "sudo systemctl status mushpi --no-pager -l" || true

echo ""
echo "📜 Recent logs (looking for migration message)..."
ssh "$PI_HOST" "sudo journalctl -u mushpi -n 50 --no-pager | grep -E '(migration|start_time|initialized|Error)'" || true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "To watch live logs, run:"
echo "  ssh $PI_HOST 'sudo journalctl -u mushpi -f'"
