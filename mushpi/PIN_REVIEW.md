# MushPi GPIO Pin Configuration Review

**Review Date:** October 14, 2025  
**Reviewed by:** System Analysis

---

## ✅ Pin Assignment Summary

### Actuator Relays (Digital Output)
| Actuator | Physical Pin | BCM GPIO | Config Variable | Code Reference | Status |
|----------|-------------|----------|-----------------|----------------|--------|
| **FAN**    | Pin 11 | **GPIO 17** | `MUSHPI_RELAY_FAN` | `config.gpio.relay_fan` | ✅ Verified |
| **MIST**   | Pin 13 | **GPIO 27** | `MUSHPI_RELAY_MIST` | `config.gpio.relay_mist` | ✅ Verified |
| **LIGHT**  | Pin 15 | **GPIO 22** | `MUSHPI_RELAY_LIGHT` | `config.gpio.relay_light` | ✅ Verified |
| **HEATER** | Pin 16 | **GPIO 23** | `MUSHPI_RELAY_HEATER` | `config.gpio.relay_heater` | ✅ Verified |

**Power Connections:**
- Relay VCC: 5V (Physical pins 2 or 4)
- Relay GND: GND (Physical pins 6, 9, 14, 20, 25, 30, 34, 39)
- Relay Logic: 3.3V (Physical pins 1 or 17) - if separate logic power needed

---

### DHT22 Temperature/Humidity Sensor
| Pin Function | Physical Pin | BCM GPIO | Config Variable | Code Reference | Status |
|--------------|-------------|----------|-----------------|----------------|--------|
| **Data** | Pin 7 | **GPIO 4** | `MUSHPI_DHT22_PIN` | `config.gpio.dht22_pin` | ✅ Verified |
| **VCC** | 3.3V | - | - | - | ✅ |
| **GND** | GND | - | - | - | ✅ |

**Required:** 10 kΩ pull-up resistor between Data (GPIO 4) and VCC (3.3V)

---

### I²C Sensors (SCD41 + ADS1115)
| Pin Function | Physical Pin | BCM GPIO | I²C Address | Config Variable | Status |
|--------------|-------------|----------|-------------|-----------------|--------|
| **SDA** | Pin 3 | **GPIO 2** | - | Built-in I²C | ✅ Verified |
| **SCL** | Pin 5 | **GPIO 3** | - | Built-in I²C | ✅ Verified |
| SCD41 | - | - | **0x62** | `MUSHPI_SCD41_ADDRESS` | ✅ Verified |
| ADS1115 | - | - | **0x48** | `MUSHPI_ADS1115_ADDRESS` | ✅ Verified |
| **VCC** | 3.3V | - | - | - | ✅ |
| **GND** | GND | - | - | - | ✅ |

**Note:** Both sensors share the same I²C bus (SDA/SCL). Addresses are unique so no conflicts.

---

### ADS1115 Analog Input (Light Sensor)
| Channel | Function | Config Variable | Code Reference | Status |
|---------|----------|-----------------|----------------|--------|
| **A0** | Photoresistor | `MUSHPI_LIGHT_SENSOR_CHANNEL=0` | `config.i2c.light_sensor_channel` | ✅ Verified |

**Circuit:** Voltage divider with photoresistor + 10kΩ fixed resistor

---

## 📊 Pin Configuration Sources

### 1. **pin_map.md** (Documentation)
- ✅ All pins match code implementation
- ✅ Physical pin numbers provided for easy wiring
- ✅ Notes about pull-up resistors and power requirements

### 2. **config.py** (Default Values)
```python
# Line 212-217 - GPIO Configuration
self.gpio = GPIOConfig(
    dht22_pin=4,        # GPIO 4 (Physical Pin 7)
    relay_fan=17,       # GPIO 17 (Physical Pin 11)
    relay_mist=27,      # GPIO 27 (Physical Pin 13)
    relay_light=22,     # GPIO 22 (Physical Pin 15)
    relay_heater=23     # GPIO 23 (Physical Pin 16)
)
```

### 3. **Environment Variables** (Override Mechanism)
All pins can be overridden via environment variables:
- `MUSHPI_DHT22_PIN` (default: 4)
- `MUSHPI_RELAY_FAN` (default: 17)
- `MUSHPI_RELAY_MIST` (default: 27)
- `MUSHPI_RELAY_LIGHT` (default: 22)
- `MUSHPI_RELAY_HEATER` (default: 23)
- `MUSHPI_SCD41_ADDRESS` (default: 0x62)
- `MUSHPI_ADS1115_ADDRESS` (default: 0x48)
- `MUSHPI_LIGHT_SENSOR_CHANNEL` (default: 0)

---

## 🔍 Code Implementation Verification

### RelayManager (control.py)
```python
# Line 308-313 - GPIO Initialization
GPIO.setmode(GPIO.BCM)  # ✅ Using BCM mode
for relay_name, pin in self.relay_pins.items():
    GPIO.setup(pin, GPIO.OUT)
```

**Pin Mapping:**
```python
self.relay_pins = {
    'fan': 17,
    'mist': 27,
    'light': 22,
    'heater': 23
}
```

### DHT22Sensor (dht22.py)
```python
# Line 31 - Pin assignment
self.pin = pin or config.gpio.dht22_pin  # Default: 4

# Line 42 - Initialization
self.sensor = adafruit_dht.DHT22(getattr(board, f'D{self.pin}'))
```

### I²C Sensors
- **SCD41** (scd41.py): Uses I²C bus, address 0x62
- **ADS1115** (light_sensor.py): Uses I²C bus, address 0x48, channel A0

---

## ⚠️ Important Notes

### GPIO Mode
- **BCM mode** is used throughout (GPIO.BCM)
- Pin numbers in code are **BCM numbers**, not physical pin numbers
- `pin_map.md` correctly provides both for reference

### Relay Logic Level
- Configurable via `MUSHPI_RELAY_ACTIVE_HIGH` (default: True)
- **Active HIGH**: GPIO HIGH = Relay ON
- **Active LOW**: GPIO HIGH = Relay OFF (inverted logic)
- Most relay boards expect **active LOW**, so you may need to set `MUSHPI_RELAY_ACTIVE_HIGH=False`

### I²C Bus
- Default Raspberry Pi I²C bus: `/dev/i2c-1` (GPIO 2/3)
- Must be enabled via `raspi-config`
- Verify with: `i2cdetect -y 1`

### DHT22 Pull-up
- **CRITICAL**: 10 kΩ pull-up resistor between GPIO 4 and 3.3V
- Without pull-up, readings will be unreliable or fail

---

## 🔧 Validation Checklist

- [x] All pin numbers in code match `pin_map.md`
- [x] BCM GPIO mode is used consistently
- [x] Environment variables provide override capability
- [x] I²C addresses don't conflict (0x62 vs 0x48)
- [x] Pin validation exists (0-40 range check in config.py line 288)
- [x] Simulation mode available for testing without hardware
- [x] All relays initialized to OFF state on startup

---

## 🚀 Recommended Actions

### Before First Run:
1. **Double-check physical wiring** against pin_map.md
2. **Add 10 kΩ pull-up** resistor for DHT22 (GPIO 4 to 3.3V)
3. **Verify relay board logic** - test if active HIGH or LOW
4. **Enable I²C** via `sudo raspi-config`
5. **Test I²C devices**: `i2cdetect -y 1` (should show 0x48 and 0x62)

### Configuration:
1. Create `.env` file if custom pins needed
2. Set `MUSHPI_RELAY_ACTIVE_HIGH=False` if using common active-LOW relays
3. Verify all addresses match your hardware

### Testing:
1. Start in simulation mode first: `MUSHPI_SIMULATION_MODE=True`
2. Check logs for pin initialization messages
3. Use `check_light.py` to test light relay and sensor
4. Use `test_modularization.py` for component testing

---

## 📝 Conclusion

**Overall Status: ✅ VERIFIED**

All pin assignments are:
- Internally consistent across codebase
- Well-documented in `pin_map.md`
- Configurable via environment variables
- Following Raspberry Pi GPIO best practices
- Properly initialized with safety defaults (all OFF)

The only potential issue is the relay active level - **verify your relay board's logic level** and set `MUSHPI_RELAY_ACTIVE_HIGH` accordingly in your `.env` file.
