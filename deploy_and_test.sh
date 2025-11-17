#!/bin/bash
# Deploy changes and test database on Raspberry Pi

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PI_USER="${PI_USER:-pi}"
PI_HOST="${PI_HOST:-raspberrypi.local}"
PI_INSTALL_DIR="/opt/mushpi"

echo "=================================================="
echo "MushPi Database Fix Deployment & Test"
echo "=================================================="
echo ""

# Check if PI_HOST is set
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <pi-ip-address>${NC}"
    echo "Example: $0 192.168.1.100"
    echo ""
    echo "Or set environment variables:"
    echo "  PI_HOST=192.168.1.100 $0"
    exit 1
fi

PI_HOST="$1"

echo "Target: ${PI_USER}@${PI_HOST}"
echo "Install directory: ${PI_INSTALL_DIR}"
echo ""

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 "${PI_USER}@${PI_HOST}" "echo 'Connected'" &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to ${PI_USER}@${PI_HOST}${NC}"
    echo "Please check:"
    echo "  - Pi is powered on and connected to network"
    echo "  - IP address is correct"
    echo "  - SSH is enabled on Pi"
    exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"
echo ""

# Deploy code changes
echo -e "${YELLOW}Deploying code changes...${NC}"
rsync -avz --progress \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='build/' \
    --exclude='*.egg-info' \
    mushpi/app/database/manager.py \
    mushpi/main.py \
    "${PI_USER}@${PI_HOST}:${PI_INSTALL_DIR}/app/" || {
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ Code deployed${NC}"
echo ""

# Copy test script
echo -e "${YELLOW}Copying test script...${NC}"
scp test_database_pi.py "${PI_USER}@${PI_HOST}:/tmp/" || {
    echo -e "${RED}❌ Failed to copy test script${NC}"
    exit 1
}
echo -e "${GREEN}✅ Test script copied${NC}"
echo ""

# Restart service
echo -e "${YELLOW}Restarting mushpi service...${NC}"
ssh "${PI_USER}@${PI_HOST}" "sudo systemctl restart mushpi.service" || {
    echo -e "${RED}❌ Failed to restart service${NC}"
    exit 1
}
echo -e "${GREEN}✅ Service restarted${NC}"
echo ""

# Wait for service to stabilize
echo "Waiting 5 seconds for service to start..."
sleep 5

# Check service status
echo -e "${YELLOW}Checking service status...${NC}"
ssh "${PI_USER}@${PI_HOST}" "sudo systemctl status mushpi.service --no-pager -l" || true
echo ""

# Run test script
echo -e "${YELLOW}Running database test...${NC}"
echo "=================================================="
ssh "${PI_USER}@${PI_HOST}" "cd ${PI_INSTALL_DIR} && source .venv/bin/activate && python3 /tmp/test_database_pi.py" || {
    echo -e "${RED}❌ Test script failed${NC}"
    echo ""
    echo "Check logs with:"
    echo "  ssh ${PI_USER}@${PI_HOST} sudo journalctl -u mushpi.service -n 50"
    exit 1
}
echo "=================================================="
echo ""

# Show recent logs
echo -e "${YELLOW}Recent service logs (last 20 lines):${NC}"
echo "=================================================="
ssh "${PI_USER}@${PI_HOST}" "sudo journalctl -u mushpi.service -n 20 --no-pager"
echo "=================================================="
echo ""

# Summary
echo -e "${GREEN}✅ Deployment and testing complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Test from Flutter app by opening Stage Wizard"
echo "  2. Try reading/writing thresholds"
echo "  3. Check for errors in app"
echo ""
echo "To view live logs:"
echo "  ssh ${PI_USER}@${PI_HOST} sudo journalctl -u mushpi.service -f"
echo ""
echo "To check database directly:"
echo "  ssh ${PI_USER}@${PI_HOST}"
echo "  sqlite3 ${PI_INSTALL_DIR}/data/sensors.db"
echo "  SELECT * FROM stage_thresholds;"
