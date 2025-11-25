# MushPi Service Setup Guide

## Problem

The `mushpi.service` systemd service is not installed, so the BLE GATT server isn't running.

---

## Quick Start (Testing)

**To test BLE immediately without installing the service:**

### On Raspberry Pi:

```bash
cd ~/mushpi

# Option 1: Run directly
sudo python3 main.py

# Option 2: Use the startup script (copy start_mushpi.sh to Pi first)
chmod +x start_mushpi.sh
./start_mushpi.sh
```

**What to look for:**
```
✅ "BLE GATT service initialized successfully"
✅ "BLE GATT service started - advertising as 'MushPi-OysterPinning'"
```

**If you see errors:**
- Missing module → Install dependencies
- Permission denied → Run with `sudo`
- Bluetooth error → Check Bluetooth adapter

---

## Proper Installation (Systemd Service)

### Step 1: Copy Installation Script to Pi

**From your Mac:**
```bash
# Copy the installation script to Pi
scp /Users/arthur/dev/mush/install_mushpi_service.sh pi@raspberrypi.local:~/

# Or if that doesn't work:
scp /Users/arthur/dev/mush/install_mushpi_service.sh pi@<PI_IP_ADDRESS>:~/
```

### Step 2: Run Installation on Pi

**On the Raspberry Pi:**
```bash
cd ~
chmod +x install_mushpi_service.sh
sudo ./install_mushpi_service.sh
```

**This will:**
1. ✅ Create Python virtual environment
2. ✅ Install all dependencies from requirements.txt
3. ✅ Create .env configuration file
4. ✅ Install systemd service
5. ✅ Enable service (auto-start on boot)
6. ✅ Start the service

### Step 3: Verify Service is Running

```bash
# Check service status
sudo systemctl status mushpi.service

# Should show:
# ● mushpi.service - Mushroom Pi BLE Control Service
#    Active: active (running)

# View logs
sudo journalctl -u mushpi.service -n 50
```

**Look for in logs:**
```
BLE GATT service started - advertising as 'MushPi-...'
```

---

## Service Management Commands

### Start/Stop/Restart
```bash
sudo systemctl start mushpi.service    # Start
sudo systemctl stop mushpi.service     # Stop
sudo systemctl restart mushpi.service  # Restart
sudo systemctl status mushpi.service   # Check status
```

### View Logs
```bash
# Last 50 lines
sudo journalctl -u mushpi.service -n 50

# Follow logs (live)
sudo journalctl -u mushpi.service -f

# Logs since boot
sudo journalctl -u mushpi.service -b
```

### Enable/Disable Auto-Start
```bash
sudo systemctl enable mushpi.service   # Auto-start on boot
sudo systemctl disable mushpi.service  # Don't auto-start
```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
sudo journalctl -u mushpi.service -n 100 --no-pager
```

**Common issues:**

1. **Missing Python packages:**
   ```bash
   cd ~/mushpi
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Missing .env file:**
   ```bash
   cd ~/mushpi
   cat > .env << 'EOF'
   MUSHPI_BLE_ENABLED=true
   MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
   MUSHPI_BLE_NAME_PREFIX=MushPi
   MUSHPI_SIMULATION_MODE=false
   EOF
   ```

3. **Bluetooth not available:**
   ```bash
   sudo systemctl restart bluetooth
   sudo hciconfig hci0 up
   ```

4. **Permission issues:**
   ```bash
   sudo chown -R pi:pi ~/mushpi
   ```

### BLE Not Advertising

**After service starts, check Bluetooth:**
```bash
# Check adapter status
hciconfig -a

# Should show UP RUNNING PSCAN ISCAN
# If not:
sudo hciconfig hci0 up
sudo hciconfig hci0 piscan
```

**Check if advertising:**
```bash
# Restart everything
sudo systemctl restart bluetooth
sudo systemctl restart mushpi.service

# Check logs
sudo journalctl -u mushpi.service | grep advertising
```

### Service Crashes on Startup

**Check Python errors:**
```bash
# Run manually to see full error
cd ~/mushpi
sudo python3 main.py
```

**Common fixes:**
```bash
# Install missing Bluetooth libraries
sudo apt-get update
sudo apt-get install -y bluez python3-bluez

# Install bluezero
pip3 install bluezero

# Install GPIO library
pip3 install RPi.GPIO
```

---

## Configuration

### Edit .env file:
```bash
nano ~/mushpi/.env
```

**Available options:**
```bash
# BLE Settings
MUSHPI_BLE_ENABLED=true
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi

# Simulation mode (for testing without hardware)
MUSHPI_SIMULATION_MODE=false

# Logging
MUSHPI_LOG_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR
```

**After editing .env:**
```bash
sudo systemctl restart mushpi.service
```

---

## Testing BLE Advertising

### From your phone (nRF Connect app):
1. Open nRF Connect
2. Scan for devices
3. Look for "MushPi-OysterPinning" (or similar)
4. Tap to see services
5. Should show service UUID: `12345678-1234-5678-1234-56789abcdef0`

### From Flutter app:
1. Open MushPi Hub app
2. Go to "Scan for Devices"
3. Device should appear in list
4. Shows species and signal strength
5. Tap to connect

---

## Manual Testing (Alternative)

**If service installation fails, you can run manually:**

```bash
cd ~/mushpi

# Create virtual environment (one time)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run server
sudo python3 main.py

# Keep terminal open - press Ctrl+C to stop
```

---

## Complete Fresh Setup

**If nothing works, start from scratch:**

```bash
# 1. Install system packages
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv bluez python3-bluez

# 2. Clone/update code
cd ~
# (assumes code is already in ~/mushpi)

# 3. Create virtual environment
cd ~/mushpi
python3 -m venv venv
source venv/bin/activate

# 4. Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# 5. Create configuration
cat > .env << 'EOF'
MUSHPI_BLE_ENABLED=true
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi
MUSHPI_SIMULATION_MODE=false
MUSHPI_LOG_LEVEL=INFO
EOF

# 6. Test manually
sudo python3 main.py

# 7. If that works, install service
# (copy and run install_mushpi_service.sh as shown above)
```

---

## Next Steps

1. **Install the service** using `install_mushpi_service.sh`
2. **Verify it's running** with `systemctl status mushpi.service`
3. **Check logs** for "advertising as" message
4. **Test with nRF Connect** on your phone
5. **Test with Flutter app**

---

## Quick Reference

```bash
# Install service
sudo ./install_mushpi_service.sh

# Check status
sudo systemctl status mushpi.service

# View logs
sudo journalctl -u mushpi.service -f

# Restart
sudo systemctl restart mushpi.service

# Test manually
cd ~/mushpi && sudo python3 main.py
```
