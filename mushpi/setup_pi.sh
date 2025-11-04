#!/bin/bash
# =============================================================================
# MushPi Raspberry Pi Setup Script
# =============================================================================
# This script sets up the MushPi environment on a Raspberry Pi
# Run with: bash setup_pi.sh
#
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "MushPi Raspberry Pi Setup"
echo "=================================================="

# Detect current user
CURRENT_USER=${USER}
MUSHPI_DIR="/home/${CURRENT_USER}/mushpi"

echo ""
echo "Setup directory: ${MUSHPI_DIR}"
echo "Current user: ${CURRENT_USER}"
echo ""

# Check if we're in the mushpi directory
if [ ! -f "main.py" ]; then
    echo "Error: Please run this script from the mushpi directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

# 1. Create necessary directories
echo "Creating data directories..."
mkdir -p data
mkdir -p logs
mkdir -p app/config

# 2. Fix permissions for database directory
echo "Setting directory permissions..."
chmod 775 data
chmod 775 logs
chmod 755 app/config

# 3. Remove old database if it exists and is read-only
if [ -f "data/sensors.db" ]; then
    echo "Found existing database file..."
    if [ ! -w "data/sensors.db" ]; then
        echo "Database is read-only, removing it..."
        rm -f data/sensors.db
        rm -f data/sensors.db-shm
        rm -f data/sensors.db-wal
    fi
fi

# 4. Create .env from example if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    
    # Update paths in .env to use current home directory
    sed -i "s|MUSHPI_APP_DIR=/home/pi/mushpi|MUSHPI_APP_DIR=${MUSHPI_DIR}|g" .env
    sed -i "s|MUSHPI_DATA_DIR=/home/pi/mushpi/data|MUSHPI_DATA_DIR=${MUSHPI_DIR}/data|g" .env
    sed -i "s|MUSHPI_CONFIG_DIR=/home/pi/mushpi/app/config|MUSHPI_CONFIG_DIR=${MUSHPI_DIR}/app/config|g" .env
    sed -i "s|MUSHPI_VENV_PATH=/home/pi/mushpi/venv|MUSHPI_VENV_PATH=${MUSHPI_DIR}/venv|g" .env
    
    echo "✓ .env file created and configured for ${MUSHPI_DIR}"
else
    echo "✓ .env file already exists"
fi

# 5. Check for virtual environment
if [ ! -d "venv" ]; then
    echo ""
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# 6. Activate venv and install/upgrade packages
echo ""
echo "Installing Python packages..."
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install required packages
if [ -f "requirements.txt" ]; then
    echo "Installing from requirements.txt..."
    pip install -r requirements.txt
fi

# Install Adafruit sensor libraries
echo "Installing Adafruit sensor libraries..."
pip install adafruit-blinka
pip install adafruit-circuitpython-ads1x15
pip install adafruit-circuitpython-scd4x
pip install adafruit-circuitpython-dht

echo "✓ Python packages installed"

# 7. Check I2C
echo ""
echo "Checking I2C configuration..."
if [ -c "/dev/i2c-1" ]; then
    echo "✓ I2C is enabled"
    
    # Check if i2cdetect is available
    if command -v i2cdetect &> /dev/null; then
        echo ""
        echo "Scanning I2C bus for devices..."
        i2cdetect -y 1
    fi
else
    echo "⚠ I2C is not enabled"
    echo "  Enable with: sudo raspi-config → Interface Options → I2C → Enable"
fi

# 8. Test configuration
echo ""
echo "Testing configuration..."
python3 -c "from app.core.config import config; print('✓ Configuration loaded successfully')" || {
    echo "✗ Configuration test failed"
    exit 1
}

# 9. Summary
echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "Directory structure:"
echo "  App:    ${MUSHPI_DIR}"
echo "  Data:   ${MUSHPI_DIR}/data"
echo "  Config: ${MUSHPI_DIR}/app/config"
echo "  Venv:   ${MUSHPI_DIR}/venv"
echo ""
echo "Next steps:"
echo "  1. Activate virtual environment: source venv/bin/activate"
echo "  2. Run the application: python3 main.py"
echo ""
echo "If you see GPIO library warnings:"
echo "  - Make sure I2C is enabled (see message above)"
echo "  - Check sensors are connected properly"
echo "  - Verify I2C addresses with: i2cdetect -y 1"
echo ""
echo "For production deployment to /opt/mushpi:"
echo "  - Edit .env and change paths to /opt/mushpi"
echo "  - Copy files: sudo cp -r ${MUSHPI_DIR} /opt/mushpi"
echo "  - Fix ownership: sudo chown -R ${CURRENT_USER}:${CURRENT_USER} /opt/mushpi"
echo ""
echo "=================================================="
