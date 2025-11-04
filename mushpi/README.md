# MushPi - Mushroom Growing Environment Controller

Automated environmental control system for mushroom cultivation using Raspberry Pi, sensors, and relays.

## Quick Start (Raspberry Pi)

### 1. Initial Setup

```bash
# Clone or copy the project to your Raspberry Pi
cd ~/mushpi

# Run the setup script
bash setup_pi.sh

# Activate the virtual environment
source venv/bin/activate
```

### 2. Fix Database Permissions (if needed)

If you see "attempt to write a readonly database" error:

```bash
bash fix_db_permissions.sh
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

For production deployment, run MushPi as a systemd service:

```bash
# Copy service file
sudo cp app/service/mushpi.service /etc/systemd/system/

# Edit paths in service file if needed
sudo nano /etc/systemd/system/mushpi.service

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
├── main.py                 # Application entry point
├── app/
│   ├── core/              # Core functionality
│   │   ├── config.py      # Configuration management
│   │   ├── sensors.py     # Sensor coordination
│   │   ├── control.py     # Relay control
│   │   ├── stage.py       # Growth stage management
│   │   └── ble_gatt.py    # Bluetooth LE interface
│   ├── sensors/           # Sensor implementations
│   │   ├── scd41.py       # SCD41 CO2 sensor
│   │   ├── dht22.py       # DHT22 temp/humidity
│   │   └── light_sensor.py # ADS1115 + photoresistor
│   ├── managers/          # Data managers
│   │   ├── sensor_manager.py
│   │   └── threshold_manager.py
│   ├── database/          # Database operations
│   │   └── manager.py
│   └── config/            # Configuration files
│       └── thresholds.json
├── data/                  # Database and logs
├── .env                   # Environment configuration (create from .env.example)
└── .env.example           # Environment template
```

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
