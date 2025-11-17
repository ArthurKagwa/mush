# ESP32 Sensor Test - DHT11 and SCD41

This is an ESP-IDF project for testing DHT11 and SCD41 sensors on ESP32.

## Hardware Connections

### DHT11 (Temperature & Humidity)
- VCC  → 3.3V
- Data → GPIO 4
- GND  → GND
- **NOTE:** Requires 10kΩ pull-up resistor between Data and VCC

### SCD41 (CO2, Temperature & Humidity - I²C)
- VCC → 3.3V
- SDA → GPIO 21 (default I2C SDA)
- SCL → GPIO 22 (default I2C SCL)
- GND → GND

## Prerequisites

1. Install ESP-IDF: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/
2. Install DHT sensor library:
   ```bash
   cd ~/esp
   git clone https://github.com/UncleRus/esp-idf-lib.git
   ```

## Build and Flash

1. Set up ESP-IDF environment:
   ```bash
   . $HOME/esp/esp-idf/export.sh
   ```

2. Configure the project (optional):
   ```bash
   idf.py menuconfig
   ```

3. Build the project:
   ```bash
   idf.py build
   ```

4. Flash to ESP32:
   ```bash
   idf.py -p /dev/ttyUSB0 flash
   ```

5. Monitor output:
   ```bash
   idf.py -p /dev/ttyUSB0 monitor
   ```

   Or combine flash and monitor:
   ```bash
   idf.py -p /dev/ttyUSB0 flash monitor
   ```

## Using the DHT Library

You'll need to add the esp-idf-lib component to your project. Add this to your project's `CMakeLists.txt`:

```cmake
set(EXTRA_COMPONENT_DIRS $ENV{HOME}/esp/esp-idf-lib/components)
```

Or add it to the top-level `CMakeLists.txt` before the `project()` line.

## Notes

- The SCD41 sensor takes about 5 seconds to provide the first measurement after startup.
- DHT11 requires at least 2 seconds between reads.
- The script reads sensors every 5 seconds to accommodate both sensors.
- Statistics are displayed after each reading cycle.

## Troubleshooting

- **DHT11 not found:** Check wiring and ensure the 10kΩ pull-up resistor is connected.
- **SCD41 I2C error:** Verify I2C connections (SDA/SCL) and ensure sensor is powered.
- **Compilation errors:** Make sure ESP-IDF and the DHT library are properly installed.
