# MushPi Tests

Comprehensive test suite for the MushPi mushroom growing controller.

## Directory Structure

```
tests/
├── unit/           # Unit tests for individual components
├── integration/    # Integration tests for system interactions
└── hardware/       # Hardware-specific tests (sensors, relays, GPIO)
```

## Test Categories

### Unit Tests (`unit/`)

Tests for individual modules and serializers without external dependencies:

- `test_actuator_feature_flag.py` - Feature flag functionality for actuator status
- `test_actuator_status_serializer.py` - Actuator status BLE packet serialization
- `test_environmental_serializer.py` - Environmental data BLE packet serialization
- `test_status_flags_minimal.py` - Minimal status flags functionality

**Run unit tests:**
```bash
cd mushpi
python3 -m pytest tests/unit/ -v
```

### Integration Tests (`integration/`)

Tests for BLE service integration, backend functionality, and system-wide features:

- `test_ble_advertisement.py` - BLE advertising and service registration
- `test_ble_backend_loop.py` - BLE backend event loop and lifecycle
- `test_ble_nonblocking.py` - Non-blocking BLE notification queue
- `test_modularization.py` - Module integration and dependencies

**Run integration tests:**
```bash
cd mushpi
python3 -m pytest tests/integration/ -v
```

### Hardware Tests (`hardware/`)

Tests requiring actual Raspberry Pi hardware (sensors, GPIO, relays):

- `test_dht11.py` - DHT11 temperature/humidity sensor
- `test_dht22.py` - DHT22 temperature/humidity sensor
- `test_fan.py` - Fan relay control
- `test_led.py` - LED/light relay control
- `test_photoresistor.py` - Photoresistor light sensor
- `test_sensors.py` - Multi-sensor coordination
- `dht22_test.py` - DHT22 sensor diagnostic
- `scd41_diagnose.py` - SCD41 CO2 sensor diagnostic

**Run hardware tests (on Pi only):**
```bash
cd mushpi
python3 -m pytest tests/hardware/ -v
```

**Run individual hardware test:**
```bash
cd mushpi
python3 tests/hardware/test_dht22.py
```

## Running Tests

### All Tests
```bash
# Run all tests
python3 -m pytest tests/ -v

# Run with coverage
python3 -m pytest tests/ --cov=app --cov-report=html
```

### Specific Test Files
```bash
# Run specific test
python3 -m pytest tests/unit/test_environmental_serializer.py -v

# Run specific test function
python3 -m pytest tests/unit/test_environmental_serializer.py::test_pack_nominal -v
```

### Test Modes

#### Simulation Mode
Most tests can run without hardware using simulation mode:
```bash
export MUSHPI_SIMULATION_MODE=true
python3 -m pytest tests/ -v
```

#### Hardware Mode (Pi only)
Hardware tests require actual Raspberry Pi with sensors connected:
```bash
export MUSHPI_SIMULATION_MODE=false
python3 -m pytest tests/hardware/ -v
```

## Test Requirements

### For All Tests
```bash
pip install pytest pytest-cov
```

### For Hardware Tests (Pi only)
```bash
# Additional requirements
pip install RPi.GPIO adafruit-blinka
pip install adafruit-circuitpython-dht
pip install adafruit-circuitpython-scd4x
pip install adafruit-circuitpython-ads1x15
```

## Writing New Tests

### Test File Naming
- Unit tests: `test_<component>_<feature>.py`
- Integration tests: `test_<system>_<integration>.py`
- Hardware tests: `test_<sensor/actuator>.py`

### Test Function Naming
- Use descriptive names: `test_<action>_<expected_result>`
- Examples: `test_pack_nominal`, `test_sensor_read_failure`

### Test Structure
```python
import pytest
from app.ble.serialization import EnvironmentalSerializer

def test_environmental_serializer_pack_nominal():
    """Test environmental serializer packs valid data correctly"""
    # Arrange
    serializer = EnvironmentalSerializer()
    
    # Act
    packed = serializer.pack(temp=22.5, rh=65.0, co2=450, light=78, uptime=1000)
    
    # Assert
    assert len(packed) == 12
    assert packed[0:2] == bytes([210, 1])  # CO2 = 450
```

### Fixtures
Use pytest fixtures for common setup:
```python
@pytest.fixture
def ble_service():
    """Fixture providing BLE service in simulation mode"""
    from app.ble.service import BLEGATTServiceManager
    service = BLEGATTServiceManager(simulation_mode=True)
    yield service
    service.stop()
```

## Continuous Integration

Tests are automatically run on:
- Every commit to main branch
- Every pull request
- Scheduled nightly runs

See `.github/workflows/` for CI configuration.

## Test Coverage

View test coverage report:
```bash
# Generate coverage report
python3 -m pytest tests/ --cov=app --cov-report=html

# Open in browser
open htmlcov/index.html
```

Target coverage: **80%+** for production code

## Troubleshooting

### Import Errors
```bash
# Ensure PYTHONPATH includes mushpi directory
export PYTHONPATH=/home/pi/mushpi:$PYTHONPATH
```

### Hardware Test Failures
- Check sensor connections (I2C, GPIO pins)
- Verify I2C is enabled: `sudo raspi-config`
- Check I2C devices: `i2cdetect -y 1`
- Verify GPIO permissions: `sudo usermod -a -G gpio $USER`

### Permission Errors
```bash
# Fix data directory permissions
bash scripts/setup/fix_db_permissions.sh
```

## Resources

- Main README: `../README.md`
- Troubleshooting: `../docs/troubleshooting/`
- Reference docs: `../docs/reference/QUICK_REFERENCE.md`
