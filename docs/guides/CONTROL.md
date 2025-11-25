# MushPi Control System Documentation

## Overview

The MushPi control system provides automated environmental control for mushroom cultivation through intelligent relay management. The system monitors sensor readings and controls actuators (fan, mist, light, heater) based on configurable thresholds with sophisticated safety features.

## Architecture

### Core Components

```
ControlSystem (Main Coordinator)
├── RelayManager (GPIO Control)
├── HysteresisController (Smooth Control)
├── DutyCycleTracker (Usage Limiting) 
├── CondensationGuard (Safety Protection)
└── LightSchedule (Time-based Control)
```

### Control Flow

1. **Sensor Reading** → Process environmental data
2. **Threshold Comparison** → Compare against configured limits
3. **Hysteresis Logic** → Apply deadband to prevent chattering
4. **Safety Checks** → Verify duty cycles and condensation guard
5. **Relay Action** → Update actuator states
6. **History Tracking** → Log actions for monitoring

---

## Actuator Controls

### 1. **FAN (Exhaust/Ventilation)**
- **GPIO Pin**: `MUSHPI_RELAY_FAN` (default: 17)
- **Triggers**:
  - Temperature > `temp_max` threshold
  - CO₂ > `co2_max` threshold
  - Condensation guard activation
- **Hysteresis**: 
  - Temperature: ±1.0°C (configurable via `MUSHPI_TEMP_HYSTERESIS`)
  - CO₂: ±100 ppm (configurable via `MUSHPI_CO2_HYSTERESIS`)
- **Duty Cycle Limit**: 60% over 30-minute rolling window
- **Logic**: OR condition (high temp OR high CO₂)

#### Operation Example:
```
Threshold: 24°C max, 1000 ppm CO₂ max
- Fan ON: temp ≥ 24.0°C OR CO₂ ≥ 1000 ppm
- Fan OFF: temp ≤ 23.0°C AND CO₂ ≤ 900 ppm
```

### 2. **MIST (Humidifier)**
- **GPIO Pin**: `MUSHPI_RELAY_MIST` (default: 27)
- **Triggers**:
  - Humidity < `humidity_min` threshold
- **Hysteresis**: +3% RH (configurable via `MUSHPI_HUMIDITY_HYSTERESIS`)
- **Duty Cycle Limit**: 40% over 30-minute rolling window
- **Safety**: Disabled when condensation guard is active

#### Operation Example:
```
Threshold: 85% RH minimum
- Mist ON: humidity ≤ 85.0%
- Mist OFF: humidity ≥ 88.0% (85% + 3% hysteresis)
```

### 3. **LIGHT (Grow Light)**
- **GPIO Pin**: `MUSHPI_RELAY_LIGHT` (default: 22)
- **Control Mode**: Schedule-based with photoresistor verification
- **Modes**:
  - **OFF**: Light always off
  - **ON**: Light always on
  - **CYCLE**: Timed on/off cycles
- **No Hysteresis**: Digital schedule control
- **No Duty Cycle Limit**: Schedule determines usage
- **Verification**: Photoresistor feedback confirms operation

#### Light Verification:
The system uses a photoresistor to verify that the grow light is working correctly:

**Verification Thresholds**:
```bash
MUSHPI_LIGHT_ON_THRESHOLD=200.0    # Light level when light should be detected as ON
MUSHPI_LIGHT_OFF_THRESHOLD=50.0    # Light level when light should be detected as OFF  
MUSHPI_LIGHT_VERIFICATION_DELAY=30.0  # Seconds to wait after state change
```

**Verification Logic**:
- When light relay is ON → photoresistor should read ≥ 200 units
- When light relay is OFF → photoresistor should read ≤ 50 units
- Verification occurs 30 seconds after any state change (allows stabilization)
- Failed verifications are logged and tracked for monitoring

**Benefits**:
- Detects burned-out bulbs or failed relays
- Confirms light fixture is properly connected
- Provides feedback for maintenance needs

#### Schedule Examples:
```
Mode: OFF
└── Light: Always OFF

Mode: ON  
└── Light: Always ON

Mode: CYCLE (12 hours on, 8 hours off)
├── Hour 0-12: Light ON
├── Hour 12-20: Light OFF
└── Hour 20-24: Light ON (cycle repeats)
```

### 4. **HEATER (Optional)**
- **GPIO Pin**: `MUSHPI_RELAY_HEATER` (default: 23)
- **Triggers**:
  - Temperature < `temp_min` threshold
- **Hysteresis**: +1.0°C (configurable via `MUSHPI_TEMP_HYSTERESIS`)
- **No Duty Cycle Limit**: Safety relies on temperature feedback
- **Mutual Exclusion**: Should not operate simultaneously with fan for temperature

#### Operation Example:
```
Threshold: 18°C minimum
- Heater ON: temp ≤ 18.0°C
- Heater OFF: temp ≥ 19.0°C (18°C + 1°C hysteresis)
```

---

## Safety Features

### 1. **Hysteresis Control**
Prevents rapid relay switching (chattering) by using different thresholds for ON and OFF states.

**Configuration**:
```bash
MUSHPI_TEMP_HYSTERESIS=1.0      # ±1.0°C deadband
MUSHPI_HUMIDITY_HYSTERESIS=3.0  # +3.0% RH deadband  
MUSHPI_CO2_HYSTERESIS=100.0     # ±100 ppm deadband
```

**Benefits**:
- Reduces relay wear
- Prevents oscillating control
- Smoother environmental transitions

### 2. **Duty Cycle Limiting**
Prevents over-operation of actuators by tracking usage over rolling time windows.

**Limits**:
- **Fan**: 60% maximum over 30 minutes
- **Mist**: 40% maximum over 30 minutes
- **Light**: No limit (schedule-controlled)
- **Heater**: No limit (temperature-limited)

**Protection**:
- Prevents equipment damage
- Reduces energy consumption
- Maintains equipment longevity

### 3. **Condensation Guard**
Monitors for excessive humidity that could cause condensation damage.

**Activation Conditions**:
- Humidity ≥ 95% (configurable)
- Duration ≥ 5 minutes (configurable)

**Actions When Active**:
- **Force fan ON** (ventilation)
- **Force mist OFF** (stop humidification)
- **Override normal control logic**

### 4. **Rate Limiting**
Prevents rapid state changes by enforcing minimum time between relay operations.

**Minimum Duration**: 30 seconds between state changes per relay

### 5. **Light Verification**
Monitors grow light operation using photoresistor feedback to detect failures.

**Verification Process**:
- Compares expected light state with actual photoresistor readings
- 30-second delay after state changes (configurable)
- Rate-limited failure alerts (every 5 minutes maximum)

**Configuration**:
```bash
MUSHPI_LIGHT_ON_THRESHOLD=200.0     # Brightness threshold for "light ON"
MUSHPI_LIGHT_OFF_THRESHOLD=50.0     # Darkness threshold for "light OFF"  
MUSHPI_LIGHT_VERIFICATION_DELAY=30.0 # Wait time after state changes
```

**Failure Detection**:
- Light scheduled ON but photoresistor reads < 200 units
- Light scheduled OFF but photoresistor reads > 50 units
- Failures logged with timestamps and failure counts
- Alerts rate-limited to prevent spam

### 6. **Emergency Stop**
Provides immediate shutdown capability for all relays.

**Triggers**:
- Manual emergency stop command
- Safety mode activation
- System initialization (fail-safe)

---

## Control Modes

### 1. **AUTOMATIC** (Default)
- Full sensor-based control
- All safety features active
- Responds to threshold violations

### 2. **MANUAL**
- Disables automatic control
- Manual relay commands only
- Safety features still active

### 3. **SAFETY**
- Emergency mode
- All relays forced OFF
- Requires manual intervention to clear

---

## GPIO Configuration

### Relay Wiring
**Current Configuration** (Active Low):
```bash
MUSHPI_RELAY_ACTIVE_HIGH=false  # Relays activate on LOW signal
```

**Pin Assignments**:
```bash
MUSHPI_RELAY_FAN=17      # Fan/Exhaust control
MUSHPI_RELAY_MIST=27     # Humidifier/Mist control  
MUSHPI_RELAY_LIGHT=22    # Grow light control
MUSHPI_RELAY_HEATER=23   # Heater control (optional)
```

**Light Verification Parameters**:
```bash
MUSHPI_LIGHT_ON_THRESHOLD=200.0     # Photoresistor reading when light ON
MUSHPI_LIGHT_OFF_THRESHOLD=50.0     # Photoresistor reading when light OFF
MUSHPI_LIGHT_VERIFICATION_DELAY=30.0 # Delay before verification (seconds)
```

### Wiring Diagram
```
GPIO Pin → Relay Board → Load
Pin 17   → Relay 1    → Exhaust Fan
Pin 27   → Relay 2    → Humidifier/Mister
Pin 22   → Relay 3    → Grow Light
Pin 23   → Relay 4    → Heater (optional)
```

**Important**: Current configuration uses **active LOW** relays:
- `GPIO HIGH` = Relay OFF
- `GPIO LOW` = Relay ON

---

## Threshold Configuration

Thresholds are loaded from the configuration system and can be updated dynamically:

```python
# Example threshold configuration
thresholds = {
    'temperature': Threshold('temperature', min_value=18.0, max_value=24.0),
    'humidity': Threshold('humidity', min_value=85.0),
    'co2': Threshold('co2', max_value=1000)
}
```

### Dynamic Updates
- Thresholds can be updated at runtime
- Controllers automatically reconfigure
- No system restart required

---

## Usage Examples

### Basic Control System Setup
```python
from mushpi.app.core.control import ControlSystem, ControlMode
from mushpi.app.models.dataclasses import SensorReading, Threshold

# Initialize control system
control = ControlSystem()
control.set_mode(ControlMode.AUTOMATIC)

# Configure thresholds
thresholds = {
    'temperature': Threshold('temperature', min_value=18.0, max_value=24.0),
    'humidity': Threshold('humidity', min_value=85.0),
    'co2': Threshold('co2', max_value=1000)
}
control.update_thresholds(thresholds)

# Set light schedule (12 hours on, 8 hours off)
control.update_light_schedule("cycle", on_minutes=720, off_minutes=480)
```

### Processing Sensor Readings
```python
from datetime import datetime

# Create sensor reading
reading = SensorReading(
    timestamp=datetime.now(),
    temperature_c=26.0,    # Above 24°C threshold
    humidity_percent=82.0, # Below 85% threshold  
    co2_ppm=1200          # Above 1000 ppm threshold
)

# Process reading and get actions taken
actions = control.process_reading(reading)

# Actions will include:
# - Fan ON (high temp and high CO₂)
# - Mist ON (low humidity)
# - Light control based on schedule
```

### Manual Control
```python
# Switch to manual mode
control.set_mode(ControlMode.MANUAL)

# Manual relay control
control.relay_manager.set_relay('exhaust_fan', RelayState.ON)
control.relay_manager.set_relay('humidifier', RelayState.OFF)
```

### Emergency Stop
```python
# Emergency stop all relays
control.set_mode(ControlMode.SAFETY)
# or
control.relay_manager.emergency_stop()
```

---

## Monitoring and Status

### System Status
```python
status = control.get_status()
print(f"Mode: {status['mode']}")
print(f"Relay States: {status['relay_states']}")
print(f"Duty Cycles: {status['duty_cycles']}")
print(f"Condensation Guard: {status['condensation_guard_active']}")
```

### Action History
The system maintains a 24-hour history of all relay actions:
```python
# Get recent actions
recent_actions = [a for a in control.action_history 
                 if a.timestamp > datetime.now() - timedelta(hours=1)]

for action in recent_actions:
    print(f"{action.timestamp}: {action.relay} -> {action.state.name} ({action.reason})")
```

### Duty Cycle Monitoring
```python
# Check current duty cycles
for name, tracker in control.duty_trackers.items():
    current_usage = tracker.get_on_time_percent(datetime.now())
    can_operate = tracker.can_turn_on(datetime.now())
    print(f"{name}: {current_usage:.1f}% (max: {tracker.max_on_percent}%) - Can operate: {can_operate}")
```

---

## Development and Testing

### Simulation Mode
For development without hardware:
```bash
MUSHPI_SIMULATION_MODE=true
```

**Simulation Features**:
- GPIO operations logged instead of executed
- All control logic functional
- Safe for development/testing
- Hardware abstraction maintained

### Debug Mode
```bash
MUSHPI_DEBUG_MODE=true
MUSHPI_LOG_LEVEL=DEBUG
```

**Debug Features**:
- Detailed logging of all operations
- State change explanations
- Timing information
- Threshold comparisons

---

## Troubleshooting

### Common Issues

#### 1. **Relays Not Responding**
**Symptoms**: GPIO commands sent but relays don't switch
**Causes**:
- Incorrect `MUSHPI_RELAY_ACTIVE_HIGH` setting
- Wrong GPIO pin assignments
- Power supply issues
- Faulty relay board

**Solutions**:
- Verify active high/low setting matches relay board
- Check GPIO pin assignments in `.env`
- Verify relay board power supply
- Test individual relays manually

#### 2. **Relay Chattering**
**Symptoms**: Relays rapidly switching on/off
**Causes**:
- Insufficient hysteresis
- Sensor noise near thresholds
- Rate limiting disabled

**Solutions**:
- Increase hysteresis values in configuration
- Check sensor calibration
- Verify minimum state duration setting

#### 3. **Duty Cycle Violations**
**Symptoms**: Actuators not responding despite threshold violations
**Causes**:
- Duty cycle limits exceeded
- Incorrect duty cycle window settings

**Solutions**:
- Monitor duty cycle usage
- Adjust duty cycle limits if appropriate
- Check for underlying issues causing over-operation

#### 4. **Condensation Guard False Triggers**
**Symptoms**: Unexpected mist shutoff and fan activation
**Causes**:
- Humidity sensor in mist stream
- Incorrect condensation guard thresholds
- Poor sensor placement

**Solutions**:
- Relocate humidity sensor away from mist output
- Adjust condensation guard thresholds
- Improve chamber airflow design

### Diagnostic Commands

#### Check GPIO States
```bash
# Manual GPIO testing (if available)
gpio readall

# Check specific pins
gpio read 17  # Fan relay
gpio read 27  # Mist relay
gpio read 22  # Light relay
gpio read 23  # Heater relay
```

#### Monitor Control System
```python
# In Python console
from mushpi.app.core.control import ControlSystem

control = ControlSystem()
status = control.get_status()
print("Current Status:", status)

# Monitor duty cycles
import datetime
for name, tracker in control.duty_trackers.items():
    usage = tracker.get_on_time_percent(datetime.datetime.now())
    print(f"{name} duty cycle: {usage:.1f}%")
```

---

## Best Practices

### 1. **Safety First**
- Always test in simulation mode first
- Verify relay wiring before powering on
- Use appropriate fuses and circuit protection
- Monitor system operation regularly

### 2. **Configuration Management**
- Use environment variables for all settings
- Document any configuration changes
- Test configuration changes in simulation
- Keep backup of working configurations

### 3. **Monitoring**
- Regularly check duty cycle usage
- Monitor for unusual relay patterns
- Keep action history for troubleshooting
- Set up alerts for safety system activations

### 4. **Maintenance**
- Periodically clean relay contacts
- Verify sensor accuracy
- Check for loose connections
- Update thresholds based on experience

---

## Related Documentation

- **[CONFIG.md](CONFIG.md)** - Environment variable configuration
- **[README.md](README.md)** - Overall system documentation  
- **[BASELINE.md](BASELINE.MD)** - Development progress tracking

## Support

For issues or questions:
1. Check simulation mode operation first
2. Review log files for error messages
3. Verify configuration settings
4. Test individual components separately
5. Consult troubleshooting section above