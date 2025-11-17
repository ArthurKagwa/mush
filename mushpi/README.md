# MushPi - Mushroom Growing Environment Controller

Automated environmental control system for mushroom cultivation using Raspberry Pi, sensors, and relays.

## Quick Start (Raspberry Pi)

### 1. Initial Setup

```bash
# Clone or copy the project to your Raspberry Pi
cd ~/mushpi

# Run the setup script
bash scripts/setup/setup_pi.sh

# Activate the virtual environment
source venv/bin/activate
```

### 2. Fix Database Permissions (if needed)

If you see "attempt to write a readonly database" error:

```bash
bash scripts/setup/fix_db_permissions.sh
```

### 3. Run the Application

```bash
# Make sure you're in the virtual environment
source venv/bin/activate

# Run (no sudo needed for /home/pi/mushpi setup)
python3 main.py
```

## Configuration

### Environment Variables (.env)

Copy and customize the environment file:

```bash
cp .env.example .env
nano .env
```

**Important paths** (for Raspberry Pi in home directory):
- `MUSHPI_APP_DIR=/home/pi/mushpi`
- `MUSHPI_DATA_DIR=/home/pi/mushpi/data`
- `MUSHPI_CONFIG_DIR=/home/pi/mushpi/app/config`

### GPIO Pin Configuration (BCM Numbering)

| BCM GPIO | Physical Pin | Default Use |
|----------|--------------|-------------|
| GPIO 4   | Pin 7        | DHT22 Temperature/Humidity sensor |
| GPIO 17  | Pin 11       | Fan exhaust relay |
| GPIO 27  | Pin 13       | Mist/Humidifier relay |
| GPIO 22  | Pin 15       | Grow light relay |
| GPIO 23  | Pin 16       | Heater relay |
| I2C SDA  | Pin 3        | SCD41 + ADS1115 (I2C Data) |
| I2C SCL  | Pin 5        | SCD41 + ADS1115 (I2C Clock) |

### I2C Sensors

**Enable I2C:**
```bash
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable
```

**Verify I2C devices:**
```bash
i2cdetect -y 1
```

Expected addresses:
- `0x48` - ADS1115 ADC (light sensor)
- `0x62` - SCD41 CO2/Temperature/Humidity sensor

## Hardware Requirements

### Sensors
- **SCD41** - CO2, Temperature, Humidity (I2C @ 0x62)
- **DHT22** - Backup Temperature/Humidity (GPIO 4)
- **ADS1115** - ADC for photoresistor light sensor (I2C @ 0x48)
- **Photoresistor** - Light level detection

### Relays (Active LOW)
- Fan/Exhaust (GPIO 17)
- Mist/Humidifier (GPIO 27)
- Grow Light (GPIO 22)
- Heater (GPIO 23) - optional

## Troubleshooting

## BLE Characteristics (env-control service)

The Pi now also sends actuator status so clients can reflect live relay states:

- env_measurements (notify/read): CO₂, temp, humidity, light, uptime
- control_targets (read/write): threshold configuration
- stage_state (read/write): current growth stage info
- override_bits (write): manual relay control
- status_flags (notify/read): system health flags
- actuator_status (notify/read): current actuator ON/OFF bitfield
   - UUID: `12345678-1234-5678-1234-56789abcdef6`
   - Bits (u16): bit0=LIGHT, bit1=FAN, bit2=MIST, bit3=HEATER

### "GPIO libraries not available" Warning

**Cause:** Missing Adafruit CircuitPython libraries

**Fix:**
```bash
source venv/bin/activate
pip install adafruit-blinka
pip install adafruit-circuitpython-ads1x15
pip install adafruit-circuitpython-scd4x
pip install adafruit-circuitpython-dht
```

**Verify:**
```bash
python3 -c "import board, busio; print('✓ board/busio OK')"
python3 -c "import adafruit_ads1x15; print('✓ ADS1115 OK')"
python3 -c "import adafruit_scd4x; print('✓ SCD4x OK')"
python3 -c "import adafruit_dht; print('✓ DHT OK')"
```

### "Invalid value for MUSHPI_RELAY_*" Error

**Cause:** Inline comments in `.env` file

**Fix:** The latest version strips inline comments automatically. If you still see this:
1. Make sure you have the latest `app/core/config.py`
2. Or remove inline comments from `.env`:
   ```bash
   # Before:
   MUSHPI_RELAY_FAN=17      # GPIO 17 (Physical Pin 11)
   
   # After:
   MUSHPI_RELAY_FAN=17
   ```

### "attempt to write a readonly database"

**Cause:** Database file or directory has wrong permissions

**Quick fix:**
```bash
bash fix_db_permissions.sh
```

**Manual fix:**
```bash
chmod 775 data
rm -f data/sensors.db*
python3 main.py  # Will recreate database
```

### No I2C Devices Detected

1. **Enable I2C interface:**
   ```bash
   sudo raspi-config
   # Interface Options → I2C → Enable
   ```

2. **Check connections:**
   - SDA to Pin 3 (GPIO 2)
   - SCL to Pin 5 (GPIO 3)
   - VCC to 3.3V
   - GND to Ground

3. **Scan bus:**
   ```bash
   i2cdetect -y 1
   ```

4. **Check permissions:**
   ```bash
   sudo usermod -a -G i2c,gpio,spi $USER
   # Logout and login again
   ```

## Running as a Service

For production deployment, run MushPi as a systemd service.

**Quick installation:**
```bash
sudo bash scripts/setup/install_mushpi_service.sh
```

**See detailed guide:** [SYSTEMCTL_README.md](../SYSTEMCTL_README.md)

**Manual service commands:**
```bash
# Enable and start service
sudo systemctl enable mushpi
sudo systemctl start mushpi

# Check status
sudo systemctl status mushpi

# View logs
sudo journalctl -u mushpi -f
```

## Development

### Local Development (Mac/Linux/Windows)

For development without Raspberry Pi hardware:

1. **Set simulation mode in `.env`:**
   ```bash
   MUSHPI_SIMULATION_MODE=true
   MUSHPI_DEBUG_MODE=true
   ```

2. **Use local paths:**
   ```bash
   MUSHPI_APP_DIR=/Users/yourname/dev/mushpi
   MUSHPI_DATA_DIR=/Users/yourname/dev/mushpi/data
   MUSHPI_CONFIG_DIR=/Users/yourname/dev/mushpi/app/config
   ```

3. **Run:**
   ```bash
   python3 main.py
   ```

Simulation mode will generate fake sensor readings and log relay operations without actual GPIO access.

## Project Structure

```
mushpi/
├── main.py                  # Application entry point
├── requirements.txt         # Python dependencies
├── .env.example            # Environment configuration template
│
├── app/                    # Application code
│   ├── core/              # Core functionality
│   ├── sensors/           # Sensor implementations
│   ├── managers/          # Data managers
│   ├── database/          # Database operations
│   ├── ble/              # BLE/GATT service
│   ├── models/           # Data models
│   ├── config/           # Configuration files
│   └── service/          # Systemd service files
│
├── tests/                 # Test suite
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── hardware/         # Hardware-specific tests
│
├── scripts/              # Utility scripts
│   ├── setup/           # Installation scripts
│   ├── diagnostic/      # Diagnostic tools
│   └── tools/           # Utility tools
│
├── docs/                # Documentation
│   ├── troubleshooting/ # Troubleshooting guides
│   ├── guides/          # How-to guides
│   └── reference/       # Reference docs
│
├── data/                # Database and logs
└── esp32_sensors_arduino/ # ESP32 integration
```

## Documentation

- **Main Guide:** [README.md](README.md) - This file
- **Service Management:** [SYSTEMCTL_README.md](../SYSTEMCTL_README.md) - Complete systemd guide
- **Tests:** [tests/README.md](tests/README.md) - Testing guide
- **Scripts:** [scripts/README.md](scripts/README.md) - Utility scripts
- **Docs:** [docs/README.md](docs/README.md) - All documentation

### Quick Links
- [Troubleshooting Bluetooth](docs/troubleshooting/BLUETOOTH_TROUBLESHOOTING.md)
- [Pin Reference](docs/guides/PIN_REVIEW.md)
- [Quick Reference](docs/reference/QUICK_REFERENCE.md)
- [Development Plan](docs/reference/PLAN.md)

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
