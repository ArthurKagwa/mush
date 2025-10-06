# MushPi Configuration Guide

## Environment Configuration

MushPi now uses environment variables for all configuration instead of hardcoded values. This makes the system more flexible and easier to deploy in different environments.

## Quick Setup

1. **Copy the template**:
   ```bash
   cp .env.example .env
   ```

2. **Edit your configuration**:
   ```bash
   nano .env
   ```

3. **Customize values** for your hardware setup (GPIO pins, I2C addresses, file paths, etc.)

## Configuration Categories

### System Paths
- `MUSHPI_APP_DIR` - Application directory
- `MUSHPI_DATA_DIR` - Data storage directory
- `MUSHPI_CONFIG_DIR` - Configuration files directory

### Hardware Configuration
- `MUSHPI_DHT22_PIN` - DHT22 sensor GPIO pin
- `MUSHPI_RELAY_*` - Relay control GPIO pins
- `MUSHPI_SCD41_ADDRESS` - SCD41 I2C address
- `MUSHPI_ADS1115_ADDRESS` - ADS1115 I2C address

### Sensor Timing
- `MUSHPI_*_INTERVAL` - Reading intervals for different sensors
- `MUSHPI_MONITOR_INTERVAL` - Main monitoring loop interval

### Hardware Calibration
- `MUSHPI_LIGHT_*` - Light sensor calibration parameters

## Validation

The configuration system automatically validates all values at startup and provides clear error messages for invalid configurations.

## Backward Compatibility

All existing code continues to work unchanged. The configuration system maintains the same constant names and values as the original hardcoded system.

## Development vs Production

Use different `.env` files for different environments:

- **Development**: Use simulation mode, debug logging
- **Production**: Use actual hardware, info logging
- **Testing**: Use test mode, minimal hardware interaction

## See Also

- `.env.example` - Complete configuration template with documentation
- `mushpi/app/core/config.py` - Configuration management implementation