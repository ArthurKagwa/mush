#!/bin/bash
# MushPi Service Installation Script
# Run this on the Raspberry Pi to install and start the MushPi BLE service

set -e  # Exit on error

echo "========================================="
echo "MushPi Service Installation"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo:"
    echo "  sudo bash install_mushpi_service.sh"
    exit 1
fi

# Configuration
MUSHPI_DIR="/home/pi/mushpi"
VENV_DIR="$MUSHPI_DIR/venv"
SERVICE_FILE="$MUSHPI_DIR/app/service/mushpi.service"
SYSTEMD_SERVICE="/etc/systemd/system/mushpi.service"

echo "1. Checking MushPi directory..."
if [ ! -d "$MUSHPI_DIR" ]; then
    echo "❌ Error: MushPi directory not found at $MUSHPI_DIR"
    exit 1
fi
echo "✅ Found: $MUSHPI_DIR"
echo ""

echo "2. Checking main.py..."
if [ ! -f "$MUSHPI_DIR/main.py" ]; then
    echo "❌ Error: main.py not found"
    exit 1
fi
echo "✅ Found: $MUSHPI_DIR/main.py"
echo ""

echo "3. Creating Python virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "✅ Created virtual environment"
else
    echo "✅ Virtual environment already exists"
fi
echo ""

echo "4. Installing Python dependencies..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$MUSHPI_DIR/requirements.txt"
echo "✅ Dependencies installed"
echo ""

echo "5. Creating .env file..."
if [ ! -f "$MUSHPI_DIR/.env" ]; then
    cat > "$MUSHPI_DIR/.env" << 'EOF'
# MushPi Configuration
MUSHPI_BLE_ENABLED=true
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi
MUSHPI_SIMULATION_MODE=false
MUSHPI_LOG_LEVEL=INFO
EOF
    echo "✅ Created .env file"
else
    echo "✅ .env file already exists"
fi
echo ""

echo "6. Creating systemd service file..."
cat > "$SYSTEMD_SERVICE" << EOF
[Unit]
Description=Mushroom Pi BLE Control Service
After=network-online.target bluetooth.target
Wants=network-online.target bluetooth.target

[Service]
Type=simple
User=pi
WorkingDirectory=$MUSHPI_DIR
ExecStart=$VENV_DIR/bin/python -u $MUSHPI_DIR/main.py
EnvironmentFile=-$MUSHPI_DIR/.env
Environment=PYTHONPATH=$MUSHPI_DIR
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
KillMode=mixed
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF
echo "✅ Created systemd service file"
echo ""

echo "7. Setting permissions..."
chown -R pi:pi "$MUSHPI_DIR"
chmod +x "$MUSHPI_DIR/main.py"
echo "✅ Permissions set"
echo ""

echo "8. Reloading systemd..."
systemctl daemon-reload
echo "✅ Systemd reloaded"
echo ""

echo "9. Enabling MushPi service..."
systemctl enable mushpi.service
echo "✅ Service enabled (will start on boot)"
echo ""

echo "10. Starting MushPi service..."
systemctl start mushpi.service
echo "✅ Service started"
echo ""

echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Service Status:"
systemctl status mushpi.service --no-pager -l
echo ""
echo "Recent Logs:"
journalctl -u mushpi.service -n 20 --no-pager
echo ""
echo "Useful Commands:"
echo "  sudo systemctl status mushpi.service   # Check status"
echo "  sudo systemctl restart mushpi.service  # Restart service"
echo "  sudo journalctl -u mushpi.service -f   # Follow logs"
echo "  sudo systemctl stop mushpi.service     # Stop service"
echo ""
