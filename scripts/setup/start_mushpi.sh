#!/bin/bash
# Quick Start MushPi BLE Server (for testing)
# Run this on the Raspberry Pi to start the BLE server manually

echo "========================================="
echo "Starting MushPi BLE Server (Manual Mode)"
echo "========================================="
echo ""

# Change to mushpi directory
cd /home/pi/mushpi || {
    echo "❌ Error: /home/pi/mushpi directory not found"
    exit 1
}

echo "Current directory: $(pwd)"
echo ""

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "⚠️  No virtual environment found"
    echo "Using system Python..."
fi
echo ""

# Check if main.py exists
if [ ! -f "main.py" ]; then
    echo "❌ Error: main.py not found"
    exit 1
fi

# Check Python version
echo "Python version: $(python3 --version)"
echo ""

# Display configuration
echo "Configuration:"
if [ -f ".env" ]; then
    echo "  .env file: ✅ Found"
    grep -E "BLE|SIMULATION" .env | sed 's/^/  /'
else
    echo "  .env file: ⚠️  Not found (using defaults)"
fi
echo ""

# Check required packages
echo "Checking required packages..."
python3 -c "import bluezero; print('  bluezero: ✅')" 2>/dev/null || echo "  bluezero: ❌ NOT INSTALLED"
python3 -c "import RPi.GPIO; print('  RPi.GPIO: ✅')" 2>/dev/null || echo "  RPi.GPIO: ⚠️  Not available (simulation mode?)"
echo ""

# Start the server
echo "========================================="
echo "Starting BLE Server..."
echo "Press Ctrl+C to stop"
echo "========================================="
echo ""

sudo python3 main.py
