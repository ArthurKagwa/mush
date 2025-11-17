# MushPi Scripts

Utility scripts for setup, diagnostics, and maintenance of the MushPi system.

## Directory Structure

```
scripts/
├── setup/          # Installation and setup scripts
├── diagnostic/     # Diagnostic and troubleshooting scripts
└── tools/          # Utility tools and helpers
```

## Setup Scripts (`setup/`)

Scripts for initial installation and configuration:

### `setup_pi.sh`
Complete Raspberry Pi setup script
```bash
bash scripts/setup/setup_pi.sh
```
**What it does:**
- Installs system dependencies (Python, Bluetooth, I2C tools)
- Creates Python virtual environment
- Installs Python packages from requirements.txt
- Configures GPIO and I2C permissions
- Creates data directories

### `install_mushpi_service.sh`
Installs MushPi as a systemd service
```bash
sudo bash scripts/setup/install_mushpi_service.sh
```
**What it does:**
- Creates virtual environment if needed
- Installs Python dependencies
- Generates .env configuration file
- Installs systemd service file
- Enables auto-start on boot
- Starts the service

**See:** `../SYSTEMCTL_README.md` for detailed service management

### `start_mushpi.sh`
Quick start script for manual testing
```bash
bash scripts/setup/start_mushpi.sh
```
**What it does:**
- Activates virtual environment
- Checks Python dependencies
- Displays configuration
- Starts main.py with sudo

### `fix_db_permissions.sh`
Fixes database file permissions
```bash
bash scripts/setup/fix_db_permissions.sh
```
**What it does:**
- Sets correct ownership of data directory
- Creates database if missing
- Fixes "readonly database" errors

## Diagnostic Scripts (`diagnostic/`)

Scripts for troubleshooting and system diagnosis:

### `diagnose_bluetooth.sh`
Comprehensive Bluetooth diagnostics
```bash
bash scripts/diagnostic/diagnose_bluetooth.sh
```
**Checks:**
- Bluetooth service status
- HCI adapter status and configuration
- BlueZ version
- D-Bus connectivity
- User permissions
- Running BLE services

**Output:** Detailed report with recommendations

### `pi_ble_diagnostic.sh`
BLE-specific diagnostics for Raspberry Pi
```bash
bash scripts/diagnostic/pi_ble_diagnostic.sh
```
**Checks:**
- BLE adapter capabilities
- Advertisement status
- GATT service registration
- Connection state
- BlueZ logs

### `verify_ble_advertising.sh`
Verifies BLE advertising is active
```bash
bash scripts/diagnostic/verify_ble_advertising.sh
```
**Checks:**
- Adapter is UP and RUNNING
- Advertisement is registered
- MushPi service UUID is advertised
- Signal strength

**Exit codes:**
- `0` - Advertising successfully
- `1` - Adapter down
- `2` - Not advertising

### `disable_ble_bonding.sh`
Disables BLE bonding/pairing
```bash
sudo bash scripts/diagnostic/disable_ble_bonding.sh
```
**What it does:**
- Configures BlueZ for "no bonding" mode
- Removes existing bond cache
- Restarts Bluetooth service

**Use when:** Android auto-pairing causes connection issues

## Tools (`tools/`)

Utility scripts for testing and maintenance:

### `check_light.py`
Light sensor reading utility
```bash
python3 scripts/tools/check_light.py
```
**What it does:**
- Reads raw light sensor value from ADS1115
- Displays light level (0-65535)
- Checks I2C connectivity

**Requirements:**
- ADS1115 connected to I2C
- Photoresistor on ADS1115 channel A0

### `light_control.py`
Manual light relay control
```bash
python3 scripts/tools/light_control.py [on|off|toggle]
```
**Examples:**
```bash
# Turn light on
python3 scripts/tools/light_control.py on

# Turn light off
python3 scripts/tools/light_control.py off

# Toggle light state
python3 scripts/tools/light_control.py toggle
```

**Requirements:**
- Light relay on GPIO 22 (default)
- Root/sudo access for GPIO

## Usage Patterns

### Fresh Pi Setup
```bash
# 1. Clone/copy mushpi to Pi
cd ~/mushpi

# 2. Run setup script
bash scripts/setup/setup_pi.sh

# 3. Test manually
bash scripts/setup/start_mushpi.sh

# 4. Install as service
sudo bash scripts/setup/install_mushpi_service.sh
```

### Troubleshooting Workflow
```bash
# 1. Check Bluetooth
bash scripts/diagnostic/diagnose_bluetooth.sh

# 2. Verify BLE advertising
bash scripts/diagnostic/verify_ble_advertising.sh

# 3. Check service logs
sudo journalctl -u mushpi -f

# 4. If bonding issues
sudo bash scripts/diagnostic/disable_ble_bonding.sh
```

### Testing Hardware
```bash
# Test light sensor
python3 scripts/tools/check_light.py

# Test light relay
python3 scripts/tools/light_control.py toggle

# Test DHT22 sensor
python3 tests/hardware/test_dht22.py

# Test all sensors
python3 tests/hardware/test_sensors.py
```

## Script Permissions

### Make Scripts Executable
```bash
chmod +x scripts/setup/*.sh
chmod +x scripts/diagnostic/*.sh
```

### Scripts Requiring sudo
- `install_mushpi_service.sh` - Installs systemd service
- `disable_ble_bonding.sh` - Modifies Bluetooth configuration
- `start_mushpi.sh` - Runs main.py with GPIO access

### Scripts Not Requiring sudo
- `setup_pi.sh` - Uses sudo internally when needed
- `diagnose_bluetooth.sh` - Read-only diagnostics
- `verify_ble_advertising.sh` - Read-only checks
- `check_light.py` - I2C read (if user in i2c group)
- `fix_db_permissions.sh` - Only if data/ owner matches user

## Environment Variables

Scripts respect environment variables from `.env`:

```bash
# Override default paths
export MUSHPI_APP_DIR=/custom/path
export MUSHPI_VENV_PATH=/custom/venv

# Run in simulation mode
export MUSHPI_SIMULATION_MODE=true

# Set log level
export MUSHPI_LOG_LEVEL=DEBUG
```

## Error Codes

### Setup Scripts
- `0` - Success
- `1` - General error
- `2` - Missing dependency
- `3` - Permission denied
- `4` - Service already exists

### Diagnostic Scripts
- `0` - All checks passed
- `1` - Critical failure
- `2` - Warning (partial functionality)
- `3` - Not applicable (e.g., not on Pi)

## Creating New Scripts

### Naming Convention
- Setup: `<action>_<target>.sh`
- Diagnostic: `<check>_<component>.sh`
- Tools: `<component>_<action>.py`

### Script Template (Bash)
```bash
#!/bin/bash
# Script: script_name.sh
# Purpose: Brief description
# Usage: bash script_name.sh [args]

set -e  # Exit on error

# Script logic here
echo "✅ Success"
```

### Script Template (Python)
```python
#!/usr/bin/env python3
"""
Script: script_name.py
Purpose: Brief description
Usage: python3 script_name.py [args]
"""

import sys
from app.core.config import load_config

def main():
    # Script logic here
    print("✅ Success")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

## Resources

- Systemd service guide: `../SYSTEMCTL_README.md`
- Main README: `../README.md`
- Troubleshooting docs: `../docs/troubleshooting/`
- Quick reference: `../docs/reference/QUICK_REFERENCE.md`
