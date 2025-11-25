# MushPi Systemctl & Service Management Guide

**Complete guide for setting up, managing, and troubleshooting the MushPi systemd service on Raspberry Pi**

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Service File Explained](#service-file-explained)
4. [Installation Methods](#installation-methods)
5. [Service Management Commands](#service-management-commands)
6. [Logs & Monitoring](#logs--monitoring)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)
10. [Quick Reference](#quick-reference)

---

## Overview

### What is systemd?

**systemd** is the init system and service manager for Linux. It:
- Starts services automatically on boot
- Manages service lifecycle (start, stop, restart)
- Handles service dependencies
- Provides logging via journald
- Monitors and restarts failed services

### Why use systemd for MushPi?

- ✅ **Auto-start on boot** - MushPi runs automatically when Pi powers on
- ✅ **Auto-restart on failure** - Service recovers from crashes
- ✅ **Dependency management** - Waits for Bluetooth and network
- ✅ **Centralized logging** - All logs in one place (journald)
- ✅ **Resource control** - Can limit CPU, memory, etc.
- ✅ **Clean shutdown** - Proper signal handling on stop

---

## Quick Start

### Installation (Automated)

```bash
# On your Raspberry Pi
cd ~/mushpi
sudo bash install_mushpi_service.sh
```

This script will:
1. ✅ Create Python virtual environment
2. ✅ Install all dependencies
3. ✅ Create .env configuration file
4. ✅ Install systemd service file
5. ✅ Enable auto-start on boot
6. ✅ Start the service immediately

### Verify Installation

```bash
# Check service status
sudo systemctl status mushpi

# Should show:
# ● mushpi.service - Mushroom Pi Control Service
#    Loaded: loaded (/etc/systemd/system/mushpi.service; enabled)
#    Active: active (running) since [timestamp]
```

### View Live Logs

```bash
# Follow logs in real-time
sudo journalctl -u mushpi -f

# Look for:
# "BLE GATT service started - advertising as 'MushPi-...'"
```

---

## Service File Explained

### Location

**Production:** `/etc/systemd/system/mushpi.service`  
**Source:** `mushpi/app/service/mushpi.service`

### Full Service File

```ini
[Unit]
Description=Mushroom Pi Control Service
After=network-online.target bluetooth.target
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=${MUSHPI_APP_DIR:-/opt/mushpi}
ExecStart=${MUSHPI_VENV_PATH:-/opt/mushpi/venv}/bin/python -u ${MUSHPI_APP_DIR:-/opt/mushpi}/main.py
EnvironmentFile=-/opt/mushpi/.env
Environment=PYTHONPATH=${MUSHPI_APP_DIR:-/opt/mushpi}
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=3
TimeoutStartSec=30
KillMode=mixed
KillSignal=SIGTERM
SendSIGHUP=no

[Install]
WantedBy=multi-user.target
```

### Line-by-Line Breakdown

#### [Unit] Section - Service Metadata

```ini
Description=Mushroom Pi Control Service
```
- Human-readable description shown in `systemctl status`

```ini
After=network-online.target bluetooth.target
```
- **After=** - Wait for these services to start first
- `network-online.target` - Ensures network is ready (for BLE)
- `bluetooth.target` - Ensures Bluetooth subsystem is running

```ini
Wants=network-online.target
```
- **Wants=** - Soft dependency (service starts even if this fails)
- Ensures network is attempted but not required

#### [Service] Section - Execution Details

```ini
Type=simple
```
- **simple** - Main process doesn't fork (stays in foreground)
- systemd considers it started as soon as ExecStart runs

```ini
User=pi
```
- Run service as the `pi` user (not root)
- Matches home directory permissions (`/home/pi/mushpi`)

```ini
WorkingDirectory=${MUSHPI_APP_DIR:-/opt/mushpi}
```
- Sets current directory for the service
- Uses environment variable `MUSHPI_APP_DIR` if set
- Falls back to `/opt/mushpi` if not set
- Relative paths in Python code are relative to this directory

```ini
ExecStart=${MUSHPI_VENV_PATH:-/opt/mushpi/venv}/bin/python -u ${MUSHPI_APP_DIR:-/opt/mushpi}/main.py
```
- **ExecStart=** - Command to run to start the service
- Uses Python from virtual environment
- `-u` flag - Unbuffered output (immediate logs)
- Runs `main.py` from the app directory

```ini
EnvironmentFile=-/opt/mushpi/.env
```
- **EnvironmentFile=** - Load environment variables from file
- `-` prefix - Don't fail if file doesn't exist (optional)
- Loads all `KEY=value` pairs from `.env` file

```ini
Environment=PYTHONPATH=${MUSHPI_APP_DIR:-/opt/mushpi}
```
- **Environment=** - Set environment variable directly
- `PYTHONPATH` - Where Python looks for modules
- Allows `import app.core.config` to work

```ini
Environment=PYTHONUNBUFFERED=1
```
- Force Python to output immediately (don't buffer)
- Essential for real-time log viewing with `journalctl -f`

```ini
Restart=on-failure
```
- **Restart=** - When to automatically restart
- `on-failure` - Restart only if process crashes (non-zero exit)
- Other options: `always`, `no`, `on-abnormal`, `on-abort`

```ini
RestartSec=3
```
- Wait 3 seconds before restarting after failure
- Prevents rapid restart loops

```ini
TimeoutStartSec=30
```
- Maximum time to wait for service to start
- If not started within 30 seconds, considered failed

```ini
KillMode=mixed
```
- **KillMode=** - How to stop the service
- `mixed` - Send SIGTERM to main process, SIGKILL to children
- Ensures clean shutdown of Python process and subprocesses

```ini
KillSignal=SIGTERM
```
- Send SIGTERM (graceful shutdown) instead of SIGKILL
- Python can catch SIGTERM for cleanup

```ini
SendSIGHUP=no
```
- Don't send SIGHUP on reload
- Prevents unintended restarts

#### [Install] Section - Boot Behavior

```ini
WantedBy=multi-user.target
```
- **WantedBy=** - When to start during boot
- `multi-user.target` - Standard multi-user system boot (no GUI required)
- Enables auto-start with `systemctl enable mushpi`

---

## Installation Methods

### Method 1: Automated Installation (Recommended)

**Use the provided installation script:**

```bash
# Copy script to Pi (if not already there)
scp install_mushpi_service.sh pi@raspberrypi.local:~/

# On the Pi
cd ~/
chmod +x install_mushpi_service.sh
sudo ./install_mushpi_service.sh
```

**What it does:**
1. Validates directory structure
2. Creates virtual environment in `/home/pi/mushpi/venv`
3. Installs Python dependencies from `requirements.txt`
4. Creates `.env` file with default configuration
5. Generates systemd service file with correct paths
6. Installs service to `/etc/systemd/system/mushpi.service`
7. Reloads systemd daemon
8. Enables service (auto-start on boot)
9. Starts service immediately
10. Shows status and recent logs

### Method 2: Manual Installation

**Step-by-step manual setup:**

#### 1. Create Virtual Environment

```bash
cd /home/pi/mushpi
python3 -m venv venv
source venv/bin/activate
```

#### 2. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

#### 3. Create Configuration

```bash
cat > .env << 'EOF'
# MushPi Configuration
MUSHPI_BLE_ENABLED=true
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi
MUSHPI_SIMULATION_MODE=false
MUSHPI_LOG_LEVEL=INFO
MUSHPI_APP_DIR=/home/pi/mushpi
MUSHPI_DATA_DIR=/home/pi/mushpi/data
MUSHPI_CONFIG_DIR=/home/pi/mushpi/app/config
EOF
```

#### 4. Create Service File

```bash
sudo tee /etc/systemd/system/mushpi.service > /dev/null << 'EOF'
[Unit]
Description=Mushroom Pi Control Service
After=network-online.target bluetooth.target
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/mushpi
ExecStart=/home/pi/mushpi/venv/bin/python -u /home/pi/mushpi/main.py
EnvironmentFile=-/home/pi/mushpi/.env
Environment=PYTHONPATH=/home/pi/mushpi
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=3
TimeoutStartSec=30
KillMode=mixed
KillSignal=SIGTERM
SendSIGHUP=no

[Install]
WantedBy=multi-user.target
EOF
```

#### 5. Set Permissions

```bash
sudo chown -R pi:pi /home/pi/mushpi
chmod +x /home/pi/mushpi/main.py
```

#### 6. Enable and Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable mushpi
sudo systemctl start mushpi
```

#### 7. Verify

```bash
sudo systemctl status mushpi
sudo journalctl -u mushpi -n 50
```

### Method 3: Custom Installation Location

**If you want to install MushPi in a different location:**

#### Option A: Use Environment Variables

Set these in `/etc/environment` or service file:

```bash
MUSHPI_APP_DIR=/opt/mushpi
MUSHPI_VENV_PATH=/opt/mushpi/venv
```

The service file will use these variables automatically.

#### Option B: Edit Service File

Modify `/etc/systemd/system/mushpi.service`:

```ini
WorkingDirectory=/your/custom/path
ExecStart=/your/custom/path/venv/bin/python -u /your/custom/path/main.py
EnvironmentFile=-/your/custom/path/.env
Environment=PYTHONPATH=/your/custom/path
```

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart mushpi
```

---

## Service Management Commands

### Basic Operations

#### Start Service
```bash
sudo systemctl start mushpi
```
- Starts the MushPi service immediately
- Does not enable auto-start on boot

#### Stop Service
```bash
sudo systemctl stop mushpi
```
- Gracefully stops the service
- Sends SIGTERM to Python process
- Waits for clean shutdown

#### Restart Service
```bash
sudo systemctl restart mushpi
```
- Stops then starts the service
- Use after updating code or configuration

#### Reload Service (if supported)
```bash
sudo systemctl reload mushpi
```
- Reloads configuration without stopping
- Not currently implemented for MushPi

### Status & Information

#### Check Status
```bash
sudo systemctl status mushpi
```

**Possible states:**
- ✅ `active (running)` - Service is working normally
- ⚠️ `active (exited)` - Service started but main process exited
- ❌ `failed` - Service crashed or failed to start
- ⚪ `inactive (dead)` - Service is not running

**Example output:**
```
● mushpi.service - Mushroom Pi Control Service
     Loaded: loaded (/etc/systemd/system/mushpi.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2025-11-17 10:30:45 GMT; 2h 15min ago
   Main PID: 1234 (python)
      Tasks: 3 (limit: 4164)
     Memory: 45.2M
        CPU: 1min 32.5s
     CGroup: /system.slice/mushpi.service
             └─1234 /home/pi/mushpi/venv/bin/python -u /home/pi/mushpi/main.py

Nov 17 10:30:45 raspberrypi systemd[1]: Started Mushroom Pi Control Service.
Nov 17 10:30:47 raspberrypi python[1234]: BLE GATT service started
```

#### Detailed Status
```bash
sudo systemctl show mushpi
```
- Shows all service properties
- Useful for debugging

#### Check if Enabled
```bash
sudo systemctl is-enabled mushpi
```
- Returns: `enabled` or `disabled`

#### Check if Running
```bash
sudo systemctl is-active mushpi
```
- Returns: `active` or `inactive`

### Boot Behavior

#### Enable Auto-Start on Boot
```bash
sudo systemctl enable mushpi
```
- Creates symlink in `/etc/systemd/system/multi-user.target.wants/`
- Service starts automatically after reboot

#### Disable Auto-Start
```bash
sudo systemctl disable mushpi
```
- Removes symlink
- Service won't start on boot (manual start still works)

#### Enable and Start Immediately
```bash
sudo systemctl enable --now mushpi
```
- Combines `enable` + `start` in one command

#### Disable and Stop Immediately
```bash
sudo systemctl disable --now mushpi
```
- Combines `disable` + `stop` in one command

### Advanced Operations

#### Reload systemd Configuration
```bash
sudo systemctl daemon-reload
```
- **Required after editing service file**
- Reloads all unit files from disk
- Does not restart services

#### Mask Service (Prevent Start)
```bash
sudo systemctl mask mushpi
```
- Prevents service from being started (even manually)
- Used for permanent disabling

#### Unmask Service
```bash
sudo systemctl unmask mushpi
```
- Re-enables a masked service

#### Reset Failed State
```bash
sudo systemctl reset-failed mushpi
```
- Clears failed state from a crashed service
- Allows restart after fixing issues

---

## Logs & Monitoring

### Using journalctl

**journalctl** is the systemd log viewer. All MushPi logs go here.

### Basic Log Commands

#### View Recent Logs
```bash
sudo journalctl -u mushpi
```
- Shows all logs for mushpi service
- Oldest first
- Press `q` to quit

#### View Latest Logs
```bash
sudo journalctl -u mushpi -n 50
```
- Shows last 50 lines
- Replace 50 with any number

#### Follow Logs (Live)
```bash
sudo journalctl -u mushpi -f
```
- **Most useful for real-time monitoring**
- Shows new logs as they appear
- Press `Ctrl+C` to stop

#### Logs Since Boot
```bash
sudo journalctl -u mushpi -b
```
- Shows logs since last boot only

#### Logs Since Time
```bash
# Last hour
sudo journalctl -u mushpi --since "1 hour ago"

# Last 5 minutes
sudo journalctl -u mushpi --since "5 minutes ago"

# Specific date/time
sudo journalctl -u mushpi --since "2025-11-17 10:00:00"

# Date range
sudo journalctl -u mushpi --since "2025-11-17" --until "2025-11-18"
```

#### Logs with Timestamps
```bash
sudo journalctl -u mushpi -f -o short-iso
```
- `-o short-iso` - ISO 8601 timestamps
- Other formats: `short`, `verbose`, `json`

### Filtering Logs

#### Search for Specific Text
```bash
sudo journalctl -u mushpi | grep "BLE"
```
- Shows only lines containing "BLE"

#### Multiple Filters
```bash
sudo journalctl -u mushpi -f | grep -E "BLE|sensor|error"
```
- Shows lines matching any of: BLE, sensor, error

#### Show Errors Only
```bash
sudo journalctl -u mushpi -p err
```
- `-p err` - Priority level: error
- Levels: `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`

### Log Analysis

#### Key Logs to Watch For

**Successful Startup:**
```
BLE GATT service initialized successfully
BLE GATT service started - advertising as 'MushPi-OysterPinning'
Environmental data updated: T=22.5°C, RH=65.0%, CO2=450ppm
```

**BLE Connection:**
```
Device connected: XX:XX:XX:XX:XX:XX
Subscribed to notifications: Environmental Measurements
Subscribed to notifications: Status Flags
```

**Sensor Readings:**
```
Sensors - Reading: temp=22.5°C, humidity=65.0%, co2=450ppm, light=78
Environmental data updated
```

**Errors to Watch For:**
```
❌ Failed to initialize BLE adapter
❌ GPIO libraries not available
❌ Sensor read failed
❌ Database error
```

### Export Logs

#### Save Logs to File
```bash
sudo journalctl -u mushpi > mushpi.log
```

#### Last 1000 Lines
```bash
sudo journalctl -u mushpi -n 1000 > recent.log
```

#### JSON Format (for parsing)
```bash
sudo journalctl -u mushpi -o json > mushpi.json
```

### Log Rotation

**journald automatically manages log size:**

#### Check Journal Size
```bash
journalctl --disk-usage
```

#### Clean Old Logs
```bash
# Keep only last 7 days
sudo journalctl --vacuum-time=7d

# Keep only 100M of logs
sudo journalctl --vacuum-size=100M
```

---

## Configuration

### Environment Variables

**Location:** `/home/pi/mushpi/.env`

#### Core Settings

```bash
# BLE Configuration
MUSHPI_BLE_ENABLED=true                    # Enable/disable BLE
MUSHPI_BLE_SERVICE_UUID=12345678-1234-5678-1234-56789abcdef0
MUSHPI_BLE_NAME_PREFIX=MushPi              # BLE device name prefix

# Simulation Mode (for testing without hardware)
MUSHPI_SIMULATION_MODE=false               # true = fake sensors/GPIO

# Logging
MUSHPI_LOG_LEVEL=INFO                      # DEBUG, INFO, WARNING, ERROR

# Paths
MUSHPI_APP_DIR=/home/pi/mushpi
MUSHPI_DATA_DIR=/home/pi/mushpi/data
MUSHPI_CONFIG_DIR=/home/pi/mushpi/app/config
MUSHPI_VENV_PATH=/home/pi/mushpi/venv
```

#### GPIO Configuration

```bash
# Relay Pins (BCM numbering)
MUSHPI_RELAY_FAN=17                        # Exhaust fan
MUSHPI_RELAY_MIST=27                       # Humidifier/mist
MUSHPI_RELAY_LIGHT=22                      # Grow light
MUSHPI_RELAY_HEATER=23                     # Heater (optional)

# Sensor Pins
MUSHPI_DHT22_PIN=4                         # DHT22 data pin

# Relay Active Level
MUSHPI_RELAY_ACTIVE_LOW=true               # true = ON when LOW
```

#### I2C Sensor Configuration

```bash
# I2C Addresses (usually auto-detected)
MUSHPI_SCD41_ADDRESS=0x62                  # CO2 sensor
MUSHPI_ADS1115_ADDRESS=0x48                # ADC for light sensor
```

#### Database Configuration

```bash
# Database
MUSHPI_DB_PATH=/home/pi/mushpi/data/sensors.db
```

### Editing Configuration

#### Edit .env File
```bash
nano /home/pi/mushpi/.env
```

#### Apply Changes
```bash
# Restart service to load new configuration
sudo systemctl restart mushpi
```

#### Verify Configuration Loaded
```bash
sudo journalctl -u mushpi -n 20
```
- Look for log lines showing loaded configuration

### Service File Configuration

**Location:** `/etc/systemd/system/mushpi.service`

#### Common Modifications

**Change User:**
```ini
User=youruser
```

**Change Working Directory:**
```ini
WorkingDirectory=/your/custom/path
```

**Add Environment Variables:**
```ini
Environment=MY_VAR=value
Environment=ANOTHER_VAR=value
```

**Change Restart Behavior:**
```ini
Restart=always          # Always restart (even on clean exit)
Restart=on-failure      # Only restart on crash (default)
Restart=no              # Never auto-restart
```

**After Editing Service File:**
```bash
sudo systemctl daemon-reload       # Load changes
sudo systemctl restart mushpi      # Apply changes
```

---

## Troubleshooting

### Service Won't Start

#### Check Status
```bash
sudo systemctl status mushpi
```

**Look for:**
- Exit code (if crashed)
- Error messages
- PID information

#### Check Recent Logs
```bash
sudo journalctl -u mushpi -n 100 --no-pager
```

#### Common Issues & Fixes

**1. Python Not Found**
```
Failed to start mushpi.service: No such file or directory
```

**Fix:**
```bash
# Verify Python path
ls /home/pi/mushpi/venv/bin/python

# If missing, recreate venv
cd /home/pi/mushpi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**2. Permission Denied**
```
PermissionError: [Errno 13] Permission denied
```

**Fix:**
```bash
sudo chown -R pi:pi /home/pi/mushpi
sudo chmod -R 755 /home/pi/mushpi
```

**3. Module Not Found**
```
ModuleNotFoundError: No module named 'bluezero'
```

**Fix:**
```bash
cd /home/pi/mushpi
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart mushpi
```

**4. Bluetooth Not Available**
```
ERROR: Failed to initialize BLE adapter
```

**Fix:**
```bash
# Check Bluetooth status
sudo systemctl status bluetooth

# Restart Bluetooth
sudo systemctl restart bluetooth

# Enable Bluetooth adapter
sudo hciconfig hci0 up

# Check adapter
hciconfig -a
```

**5. GPIO Not Available**
```
WARNING: GPIO libraries not available
```

**Fix:**
```bash
# Install GPIO libraries
pip install RPi.GPIO

# Add user to gpio group
sudo usermod -a -G gpio pi

# Reboot to apply group changes
sudo reboot
```

**6. Database Locked**
```
attempt to write a readonly database
```

**Fix:**
```bash
cd /home/pi/mushpi
bash fix_db_permissions.sh

# Or manually:
sudo chown -R pi:pi data/
chmod 755 data/
```

**7. Port Already in Use**
```
Address already in use
```

**Fix:**
```bash
# Find process using Bluetooth
sudo lsof -i :bluetooth

# Kill old process
sudo pkill -f main.py

# Restart service
sudo systemctl restart mushpi
```

### Service Crashes Repeatedly

#### Check Restart Count
```bash
sudo systemctl show mushpi | grep NRestarts
```

#### View Crash Logs
```bash
sudo journalctl -u mushpi -p err -n 50
```

#### Disable Auto-Restart (for debugging)
```bash
# Edit service file
sudo nano /etc/systemd/system/mushpi.service

# Change:
Restart=no

# Reload and try manual start
sudo systemctl daemon-reload
sudo systemctl start mushpi
```

#### Run Manually for Debugging
```bash
# Stop service
sudo systemctl stop mushpi

# Run manually to see full output
cd /home/pi/mushpi
source venv/bin/activate
sudo python3 main.py
```

### BLE Not Advertising

#### Check Bluetooth Status
```bash
sudo systemctl status bluetooth
hciconfig -a
```

**Should show:**
```
hci0:   Type: Primary  Bus: UART
        UP RUNNING PSCAN ISCAN
```

#### Enable Adapter
```bash
sudo hciconfig hci0 up
sudo hciconfig hci0 piscan
```

#### Check BLE Advertising
```bash
# Install if needed
sudo apt-get install bluez-tools

# Scan for devices
sudo hcitool lescan
```

#### Restart Bluetooth Stack
```bash
sudo systemctl restart bluetooth
sudo systemctl restart mushpi
```

### High CPU/Memory Usage

#### Check Resource Usage
```bash
# Show resource usage
sudo systemctl status mushpi

# Detailed process info
top -p $(pgrep -f main.py)
```

#### Check for Loops
```bash
# Watch logs for repeated errors
sudo journalctl -u mushpi -f | grep -E "error|ERROR|retry"
```

#### Limit Resources (if needed)
Edit service file:
```ini
[Service]
MemoryLimit=256M
CPUQuota=50%
```

### Cannot Stop Service

#### Force Stop
```bash
sudo systemctl kill mushpi
```

#### Kill Process Directly
```bash
# Find PID
sudo systemctl status mushpi

# Kill process
sudo kill -9 <PID>
```

---

## Advanced Topics

### Custom Service Variants

#### Development Service (No Auto-Restart)

Create `/etc/systemd/system/mushpi-dev.service`:

```ini
[Unit]
Description=Mushroom Pi Control Service (Development)
After=network-online.target bluetooth.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/mushpi
ExecStart=/home/pi/mushpi/venv/bin/python -u /home/pi/mushpi/main.py
EnvironmentFile=-/home/pi/mushpi/.env
Environment=PYTHONPATH=/home/pi/mushpi
Environment=PYTHONUNBUFFERED=1
Environment=MUSHPI_LOG_LEVEL=DEBUG
Restart=no
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
```

Usage:
```bash
sudo systemctl start mushpi-dev
sudo journalctl -u mushpi-dev -f
```

#### Test Service (Simulation Mode)

Create `/etc/systemd/system/mushpi-test.service`:

```ini
[Unit]
Description=Mushroom Pi Control Service (Test/Simulation)

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/mushpi
ExecStart=/home/pi/mushpi/venv/bin/python -u /home/pi/mushpi/main.py
Environment=PYTHONPATH=/home/pi/mushpi
Environment=PYTHONUNBUFFERED=1
Environment=MUSHPI_SIMULATION_MODE=true
Environment=MUSHPI_LOG_LEVEL=DEBUG
Restart=no

[Install]
WantedBy=multi-user.target
```

### Resource Limits

Add to `[Service]` section:

```ini
# Memory limits
MemoryLimit=512M                    # Hard limit
MemoryHigh=256M                     # Soft limit (throttle)

# CPU limits
CPUQuota=100%                       # 100% = 1 full core
CPUWeight=100                       # Priority (1-10000)

# Process limits
TasksMax=10                         # Max number of threads/processes

# File descriptor limits
LimitNOFILE=1024                    # Max open files
```

### Security Hardening

Add to `[Service]` section:

```ini
# Run with minimal privileges
NoNewPrivileges=true
PrivateTmp=true

# Restrict system calls
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Restrict file system access
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/pi/mushpi/data

# Restrict network access (if not needed)
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_BLUETOOTH

# Capabilities (for GPIO/Bluetooth without root)
AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN
```

### Logging Configuration

#### Custom Log Level via Service File

```ini
Environment=MUSHPI_LOG_LEVEL=DEBUG
```

#### Redirect stdout/stderr to Files

```ini
StandardOutput=append:/var/log/mushpi/stdout.log
StandardError=append:/var/log/mushpi/stderr.log
```

**Create log directory:**
```bash
sudo mkdir -p /var/log/mushpi
sudo chown pi:pi /var/log/mushpi
```

### Multiple Service Instances

Run multiple MushPi instances (e.g., for different grow chambers):

#### Template Service File

Create `/etc/systemd/system/mushpi@.service`:

```ini
[Unit]
Description=Mushroom Pi Control Service (%i)
After=network-online.target bluetooth.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/mushpi-%i
ExecStart=/home/pi/mushpi-%i/venv/bin/python -u /home/pi/mushpi-%i/main.py
EnvironmentFile=-/home/pi/mushpi-%i/.env
Environment=PYTHONPATH=/home/pi/mushpi-%i
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

#### Usage

```bash
# Start chamber1
sudo systemctl start mushpi@chamber1

# Start chamber2
sudo systemctl start mushpi@chamber2

# Status
sudo systemctl status 'mushpi@*'
```

### Pre/Post Start Commands

#### Run Commands Before/After Start

```ini
[Service]
ExecStartPre=/home/pi/mushpi/scripts/check_hardware.sh
ExecStartPost=/home/pi/mushpi/scripts/notify_started.sh
ExecStopPost=/home/pi/mushpi/scripts/cleanup.sh
```

### Watchdog / Health Monitoring

Enable service watchdog:

```ini
[Service]
WatchdogSec=60                      # Expect ping every 60 seconds
Restart=on-watchdog                 # Restart if watchdog timeout
```

Requires Python code to call:
```python
import systemd.daemon
systemd.daemon.notify('WATCHDOG=1')
```

---

## Quick Reference

### Essential Commands

```bash
# Status & Info
sudo systemctl status mushpi              # Check status
sudo systemctl show mushpi                # Detailed info
sudo systemctl is-active mushpi           # Running?
sudo systemctl is-enabled mushpi          # Auto-start enabled?

# Start/Stop/Restart
sudo systemctl start mushpi               # Start now
sudo systemctl stop mushpi                # Stop now
sudo systemctl restart mushpi             # Restart now
sudo systemctl reload mushpi              # Reload config (if supported)

# Enable/Disable Auto-Start
sudo systemctl enable mushpi              # Auto-start on boot
sudo systemctl disable mushpi             # Don't auto-start
sudo systemctl enable --now mushpi        # Enable + start now
sudo systemctl disable --now mushpi       # Disable + stop now

# After Editing Service File
sudo systemctl daemon-reload              # Required!
sudo systemctl restart mushpi             # Apply changes

# Logs
sudo journalctl -u mushpi -f              # Follow live logs
sudo journalctl -u mushpi -n 50           # Last 50 lines
sudo journalctl -u mushpi -b              # Since boot
sudo journalctl -u mushpi --since "1 hour ago"
sudo journalctl -u mushpi | grep ERROR    # Filter errors

# Troubleshooting
sudo systemctl reset-failed mushpi        # Clear failed state
sudo systemctl kill mushpi                # Force stop
sudo systemctl mask mushpi                # Prevent start
sudo systemctl unmask mushpi              # Allow start again
```

### File Locations

```
Service File:     /etc/systemd/system/mushpi.service
Source Template:  /home/pi/mushpi/app/service/mushpi.service
Application:      /home/pi/mushpi/main.py
Virtual Env:      /home/pi/mushpi/venv/
Configuration:    /home/pi/mushpi/.env
Data Directory:   /home/pi/mushpi/data/
Logs:             sudo journalctl -u mushpi
```

### Installation Scripts

```
Full Setup:       sudo bash install_mushpi_service.sh
Quick Start:      bash start_mushpi.sh
DB Permissions:   bash fix_db_permissions.sh
```

### One-Liner Checks

```bash
# Is service running?
systemctl is-active mushpi && echo "Running" || echo "Not running"

# Show last error
sudo journalctl -u mushpi -p err -n 1

# Restart if not running
systemctl is-active mushpi || sudo systemctl start mushpi

# Show startup time
sudo systemd-analyze blame | grep mushpi

# Count restarts
sudo systemctl show mushpi | grep NRestarts

# Show memory usage
sudo systemctl status mushpi | grep Memory
```

---

## Additional Resources

### systemd Documentation

- [systemd.service man page](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [systemd.unit man page](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
- [systemctl man page](https://www.freedesktop.org/software/systemd/man/systemctl.html)
- [journalctl man page](https://www.freedesktop.org/software/systemd/man/journalctl.html)

### MushPi Documentation

- `README.md` - General setup and usage
- `BASELINE.md` - Project history and changes
- `MUSHPI_SERVICE_SETUP.md` - Service-specific setup
- `BLE_TROUBLESHOOTING.md` - Bluetooth issues
- `mushpi/README.md` - Backend documentation

### Getting Help

```bash
# systemctl help
man systemctl

# Service file format help
man systemd.service

# Journal help
man journalctl

# Check MushPi logs for errors
sudo journalctl -u mushpi -p err
```

---

## Changelog

- **2025-11-17** - Initial comprehensive systemctl guide created
- Covers installation, management, troubleshooting, and advanced topics
- Includes detailed service file explanation
- Added quick reference section

---

**End of Guide**
