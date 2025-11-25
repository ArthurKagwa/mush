# BLE Protocol Reference

Complete reference for the MushPi BLE GATT service protocol.

## Service UUID

**Main Service:** `12345678-1234-5678-1234-56789abcdef0`

---

## Characteristics

### 1. Environmental Measurements
**UUID:** `12345678-1234-5678-1234-56789abcdef1`  
**Properties:** Read, Notify  
**Data Size:** 12 bytes

**Format (little-endian):**
- Bytes 0-3: Temperature (float32, °C)
- Bytes 4-7: Humidity (float32, %)
- Bytes 8-11: CO2 (uint32, ppm)
- Bytes 12-15: Light level (float32, 0-1000)

---

### 2. Control Targets
**UUID:** `12345678-1234-5678-1234-56789abcdef2`  
**Properties:** Read, Write  
**Data Size:** Variable (JSON)

**Format:** JSON object with threshold values
```json
{
  "temp_min": 20.0,
  "temp_max": 26.0,
  "rh_min": 60.0,
  "co2_max": 1000,
  "light": {
    "mode": "cycle",
    "on_min": 900,
    "off_min": 540
  }
}
```

---

### 3. Stage State
**UUID:** `12345678-1234-5678-1234-56789abcdef3`  
**Properties:** Read, Write  
**Data Size:** Variable (JSON)

**Format:** JSON object with stage configuration
```json
{
  "species": "Oyster",
  "stage": "Incubation",
  "mode": 0,
  "stage_start_ts": 1234567890,
  "expected_days": 14
}
```

**Mode Values:**
- `0` = FULL (automatic stage advancement)
- `1` = SEMI (manual stage advancement)
- `2` = MANUAL (no automatic control)

---

### 4. Override Bits ⭐ **NEW**
**UUID:** `12345678-1234-5678-1234-56789abcdef4`  
**Properties:** Write Only  
**Data Size:** 2 bytes

**Format (little-endian):**
- Bytes 0-1: Override bits (unsigned 16-bit bit field)

#### Bit Definitions

| Bit | Flag | Relay/Function | Description |
|-----|------|----------------|-------------|
| 0 | `LIGHT` | `grow_light` | Manual override for grow light relay |
| 1 | `FAN` | `exhaust_fan` | Manual override for exhaust fan relay |
| 2 | `MIST` | `humidifier` | Manual override for humidifier/mist relay |
| 3 | `HEATER` | `heater` | Manual override for heater relay |
| 7 | `DISABLE_AUTO` | System-wide | Disable all automatic control |
| 15 | `EMERGENCY_STOP` | System-wide | Emergency stop - all relays OFF, SAFETY mode |

**Reserved Bits:** 4-6, 8-14 (must be set to 0)

#### Behavior

**Individual Relay Overrides (bits 0-3):**
- **When SET (1):** Relay is placed under manual control
  - Current relay state is maintained
  - Automatic control is bypassed for this relay
  - Reason code updated to `MANUAL_OVERRIDE_ON` or `MANUAL_OVERRIDE_OFF`
- **When CLEARED (0):** Relay returns to automatic control
  - Automatic control resumes for this relay
  - Relay state managed by sensor readings and thresholds

**Automation Disable (bit 7):**
- **When SET (1):** Entire system switches to `MANUAL` mode
  - All automatic control is disabled
  - All relays remain in current state
  - Individual overrides still respected
- **When CLEARED (0):** System returns to `AUTOMATIC` mode
  - Automatic control resumes (if no individual overrides active)
  - If individual overrides are active, system remains in MANUAL mode

**Emergency Stop (bit 15):**
- **When SET (1):** System switches to `SAFETY` mode
  - **All relays are immediately turned OFF**
  - All automatic control is disabled
  - Takes highest priority (overrides all other bits)
  - Emergency stop persists until bit is cleared
- **When CLEARED (0):** System returns to previous mode
  - If no individual overrides active: Returns to `AUTOMATIC` mode
  - If individual overrides active: Returns to `MANUAL` mode
  - Relays remain OFF until automatic control or manual overrides change them

#### Override Bit Examples

**Example 1: Enable light override only**
```
Bits: 0b00000001 (0x0001)
- bit0 = 1 (LIGHT override enabled)
- All other bits = 0
Result: Grow light under manual control, all other relays automatic
```

**Example 2: Enable fan and mist overrides**
```
Bits: 0b00000110 (0x0006)
- bit1 = 1 (FAN override enabled)
- bit2 = 1 (MIST override enabled)
- All other bits = 0
Result: Fan and mist under manual control, light and heater automatic
```

**Example 3: Disable all automation**
```
Bits: 0b10000000 (0x0080)
- bit7 = 1 (DISABLE_AUTO enabled)
- All other bits = 0
Result: Entire system in MANUAL mode, all automatic control disabled
```

**Example 4: Multiple overrides + disable automation**
```
Bits: 0b10000111 (0x0087)
- bit0 = 1 (LIGHT override)
- bit1 = 1 (FAN override)
- bit2 = 1 (MIST override)
- bit7 = 1 (DISABLE_AUTO)
Result: Light, fan, and mist under manual control, automation disabled
```

**Example 5: Emergency stop**
```
Bits: 0b1000000000000000 (0x8000)
- bit15 = 1 (EMERGENCY_STOP enabled)
- All other bits = 0
Result: All relays OFF immediately, system in SAFETY mode
```

**Example 6: Clear all overrides**
```
Bits: 0b00000000 (0x0000)
- All bits = 0
Result: All relays return to automatic control, system in AUTOMATIC mode
```

#### Interaction with Automatic Control

1. **When override is active:**
   - Automatic control methods (`_process_temperature_control()`, `_process_humidity_control()`, etc.) check `_is_manually_overridden()` before making changes
   - If relay is overridden, automatic control is skipped for that relay
   - Other non-overridden relays continue automatic control

2. **When override is cleared:**
   - Relay immediately returns to automatic control
   - Next sensor reading cycle will apply automatic control logic
   - Relay state may change based on current sensor readings

3. **Priority order:**
   - Emergency stop (bit15) - **HIGHEST PRIORITY**
   - Manual overrides (bits 0-3)
   - Safety features (condensation guard)
   - Automation disable (bit7)
   - Automatic control (lowest priority)

#### Reason Codes

When overrides are active, relay reason codes are updated:
- `MANUAL_OVERRIDE_ON` (130) - Relay manually forced ON
- `MANUAL_OVERRIDE_OFF` (131) - Relay manually forced OFF
- `MANUAL_MODE_ACTIVE` (132) - System in manual mode

#### Error Handling

- Invalid bit combinations (reserved bits set) are rejected
- Invalid data length (< 2 bytes) triggers warning log
- Override state is validated before application
- Errors are logged but do not crash the service

---

### 5. Status Flags
**UUID:** `12345678-1234-5678-1234-56789abcdef5`  
**Properties:** Read, Notify  
**Data Size:** 4 bytes

**Format (little-endian):**
- Bytes 0-3: Status flags (unsigned 32-bit bit field)

**Bit Definitions:**
- Bit 0: SENSOR_ERROR
- Bit 1: CONTROL_ERROR
- Bit 2: STAGE_READY
- Bit 3: THRESHOLD_ALARM
- Bit 4: CONNECTIVITY
- Bit 7: SIMULATION

---

### 6. Actuator Status
**UUID:** `12345678-1234-5678-1234-56789abcdef6`  
**Properties:** Read, Notify  
**Data Size:** 6 bytes

**Format (little-endian):**
- Bytes 0-1: Actuator state bits (unsigned 16-bit)
- Bytes 2-5: Reason codes (4 × uint8)

**Actuator State Bits:**
- Bit 0: LIGHT relay state (1=ON, 0=OFF)
- Bit 1: FAN relay state (1=ON, 0=OFF)
- Bit 2: MIST relay state (1=ON, 0=OFF)
- Bit 3: HEATER relay state (1=ON, 0=OFF)

**Reason Codes (one byte each):**
- Byte 2: Light reason code (0-255)
- Byte 3: Fan reason code (0-255)
- Byte 4: Mist reason code (0-255)
- Byte 5: Heater reason code (0-255)

---

## Protocol Notes

### Data Endianness
All multi-byte values use **little-endian** byte order.

### Write Characteristics
- `control_targets` - Updates current stage thresholds
- `stage_state` - Updates current stage configuration
- `override_bits` - Sets manual override flags

### Notify Characteristics
- `env_measurements` - Sent when new sensor readings available
- `status_flags` - Sent when system status changes
- `actuator_status` - Sent when relay states change

### Error Responses
- Invalid data length: Warning logged, operation skipped
- Invalid bit patterns: Warning logged, operation skipped
- Service errors: Error logged, operation fails gracefully

---

## References

- `mushpi/app/models/ble_dataclasses.py` - Data class definitions
- `mushpi/app/ble/serialization.py` - Serialization/deserialization logic
- `mushpi/app/ble/characteristics/` - Characteristic implementations
- `BASELINE.MD` - Implementation history and decisions

