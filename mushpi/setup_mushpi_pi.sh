#!/bin/bash
# MushPi Setup Script for Raspberry Pi
# This script sets up the necessary directories and files for MushPi service

set -e  # Exit on error

echo "=========================================="
echo "MushPi Raspberry Pi Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="/home/pi/mushpi"
USER="pi"
GROUP="pi"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --user)
            USER="$2"
            shift 2
            ;;
        --group)
            GROUP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dir DIR     Installation directory (default: /home/pi/mushpi)"
            echo "  --user USER   Owner user (default: pi)"
            echo "  --group GROUP Owner group (default: pi)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}Installation directory: ${INSTALL_DIR}${NC}"
echo -e "${GREEN}Owner: ${USER}:${GROUP}${NC}"
echo ""

# Function to create directory with proper permissions
create_directory() {
    local dir=$1
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}Directory already exists: ${dir}${NC}"
    else
        echo -e "${GREEN}Creating directory: ${dir}${NC}"
        mkdir -p "$dir"
        chown ${USER}:${GROUP} "$dir"
        chmod 755 "$dir"
    fi
}

# Function to check if running as root or with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Check sudo privileges
check_sudo

# Create main directories
echo ""
echo "Step 1: Creating directory structure..."
echo "----------------------------------------"

create_directory "${INSTALL_DIR}"
create_directory "${INSTALL_DIR}/app"
create_directory "${INSTALL_DIR}/app/config"
create_directory "${INSTALL_DIR}/data"
create_directory "${INSTALL_DIR}/.venv"

# Create subdirectories in data
create_directory "${INSTALL_DIR}/data/logs"
create_directory "${INSTALL_DIR}/data/backups"

echo -e "${GREEN}✓ Directory structure created${NC}"

# Copy .env file if it exists
echo ""
echo "Step 2: Setting up environment configuration..."
echo "------------------------------------------------"

if [ -f "${INSTALL_DIR}/.env.pi" ]; then
    echo -e "${GREEN}Found .env.pi file, copying to .env${NC}"
    cp "${INSTALL_DIR}/.env.pi" "${INSTALL_DIR}/.env"
    chown ${USER}:${GROUP} "${INSTALL_DIR}/.env"
    chmod 644 "${INSTALL_DIR}/.env"
    echo -e "${GREEN}✓ Environment file configured${NC}"
elif [ -f ".env.pi" ]; then
    echo -e "${GREEN}Found .env.pi in current directory, copying to ${INSTALL_DIR}/.env${NC}"
    cp ".env.pi" "${INSTALL_DIR}/.env"
    chown ${USER}:${GROUP} "${INSTALL_DIR}/.env"
    chmod 644 "${INSTALL_DIR}/.env"
    echo -e "${GREEN}✓ Environment file configured${NC}"
else
    echo -e "${YELLOW}Warning: .env.pi file not found${NC}"
    echo "Please copy .env.pi to ${INSTALL_DIR}/.env manually"
fi

# Create stage_config.json if it doesn't exist
echo ""
echo "Step 3: Checking configuration files..."
echo "----------------------------------------"

STAGE_CONFIG="${INSTALL_DIR}/data/stage_config.json"
if [ ! -f "$STAGE_CONFIG" ]; then
    echo -e "${GREEN}Creating default stage_config.json${NC}"
    cat > "$STAGE_CONFIG" << 'EOF'
{
  "mode": "SEMI",
  "species": "Oyster",
  "stage": "Pinning",
  "stage_start_ts": 0,
  "expected_days": 5
}
EOF
    chown ${USER}:${GROUP} "$STAGE_CONFIG"
    chmod 644 "$STAGE_CONFIG"
    echo -e "${GREEN}✓ Created default stage configuration${NC}"
else
    echo -e "${YELLOW}stage_config.json already exists${NC}"
fi

# Check thresholds.json
THRESHOLDS_FILE="${INSTALL_DIR}/app/config/thresholds.json"
if [ ! -f "$THRESHOLDS_FILE" ]; then
    echo -e "${YELLOW}Warning: thresholds.json not found at ${THRESHOLDS_FILE}${NC}"
    echo "Please copy mushpi/app/config/thresholds.json to this location"
else
    echo -e "${GREEN}✓ thresholds.json found${NC}"
    chown ${USER}:${GROUP} "$THRESHOLDS_FILE"
    chmod 644 "$THRESHOLDS_FILE"
fi

# Set ownership recursively
echo ""
echo "Step 4: Setting permissions..."
echo "------------------------------"
chown -R ${USER}:${GROUP} "${INSTALL_DIR}"
echo -e "${GREEN}✓ Permissions set${NC}"

# Check if systemd service file exists
echo ""
echo "Step 5: Checking systemd service..."
echo "------------------------------------"
SERVICE_FILE="/etc/systemd/system/mushpi.service"
if [ -f "$SERVICE_FILE" ]; then
    echo -e "${GREEN}✓ Service file found: ${SERVICE_FILE}${NC}"
    
    # Check if service is using correct paths
    if grep -q "/opt/mushpi" "$SERVICE_FILE"; then
        echo -e "${YELLOW}Warning: Service file still references /opt/mushpi${NC}"
        echo "You may need to update WorkingDirectory and ExecStart in ${SERVICE_FILE}"
        echo "To use: ${INSTALL_DIR}"
    fi
else
    echo -e "${YELLOW}Service file not found${NC}"
    echo "You may need to create ${SERVICE_FILE}"
fi

# Summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Directory structure created:"
echo "  ${INSTALL_DIR}/"
echo "    ├── app/"
echo "    │   └── config/"
echo "    ├── data/"
echo "    │   ├── logs/"
echo "    │   └── backups/"
echo "    └── .venv/"
echo ""
echo "Next steps:"
echo "1. Copy your application code to ${INSTALL_DIR}/app/"
echo "2. Copy thresholds.json to ${INSTALL_DIR}/app/config/"
echo "3. Copy .env.pi to ${INSTALL_DIR}/.env (if not already done)"
echo "4. Install Python dependencies in ${INSTALL_DIR}/.venv"
echo "5. Update systemd service file if needed"
echo "6. Run: sudo systemctl daemon-reload"
echo "7. Run: sudo systemctl restart mushpi.service"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
