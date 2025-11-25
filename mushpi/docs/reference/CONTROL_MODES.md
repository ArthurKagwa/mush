# Control Modes vs Stage Modes

This document explains the difference between **Control Modes** and **Stage Modes** in the MushPi system, and how they interact.

## Overview

MushPi uses two separate mode systems that work together:

1. **Stage Mode** - Controls stage advancement behavior
2. **Control Mode** - Controls automatic relay control behavior

These modes serve different purposes and can be combined in various ways.

---

## Stage Modes

**Location:** `mushpi/app/core/stage.py` - `StageMode` enum

Stage modes control **how stages advance** through the cultivation cycle.

### Stage Mode Values

| Mode | Value | Description |
|------|-------|-------------|
| `FULL` | `"full"` | Automatic stage advancement + automatic relay control |
| `SEMI` | `"semi"` | Manual stage advancement + automatic relay control |
| `MANUAL` | `"manual"` | Manual stage advancement + **no automatic relay control** |

### Stage Mode Behavior

- **FULL Mode:**
  - Stages advance automatically when age threshold AND compliance ratio are met
  - Automatic relay control is enabled
  - Best for hands-off operation

- **SEMI Mode:**
  - Stages advance only when manually triggered (via Flutter app)
  - Automatic relay control is enabled
  - Best for monitoring and manual intervention

- **MANUAL Mode:**
  - Stages advance only when manually triggered
  - **Automatic relay control is disabled**
  - All relay control must be done manually via override bits
  - Best for troubleshooting or custom control

---

## Control Modes

**Location:** `mushpi/app/core/control.py` - `ControlMode` enum

Control modes control **whether the control system automatically adjusts relays** based on sensor readings.

### Control Mode Values

| Mode | Value | Description |
|------|-------|-------------|
| `AUTOMATIC` | `"automatic"` | Full automatic relay control based on sensor readings |
| `MANUAL` | `"manual"` | No automatic control; relays only change via manual overrides |
| `SAFETY` | `"safety"` | Emergency stop; all relays OFF, no automatic control |

### Control Mode Behavior

- **AUTOMATIC Mode:**
  - Control system processes sensor readings every monitor interval
  - Relays are automatically turned ON/OFF based on thresholds
  - Manual overrides can still be applied for individual relays
  - Used when stage mode is FULL or SEMI

- **MANUAL Mode:**
  - Control system ignores sensor readings
  - Relays only change when manually overridden via BLE override bits
  - Used when stage mode is MANUAL, or when DISABLE_AUTOMATION bit is set

- **SAFETY Mode:**
  - Emergency stop activated
  - All relays are immediately turned OFF
  - No automatic control
  - Activated when EMERGENCY_STOP bit (bit15) is set via BLE

---

## Mode Mapping

Stage modes are automatically mapped to control modes:

| Stage Mode | Control Mode | Notes |
|------------|--------------|-------|
| `FULL` | `AUTOMATIC` | Full automation enabled |
| `SEMI` | `AUTOMATIC` | Auto-control enabled, but stage advance is manual |
| `MANUAL` | `MANUAL` | No automatic control |

**Implementation:** `mushpi/main.py` - `set_stage_state()` and `loop()` initialization

---

## Mode Interactions

### Example 1: FULL Stage Mode
```
Stage Mode: FULL
Control Mode: AUTOMATIC (derived from stage mode)
Result: 
  - Stages advance automatically
  - Relays controlled automatically
  - Manual overrides still work for individual relays
```

### Example 2: SEMI Stage Mode
```
Stage Mode: SEMI
Control Mode: AUTOMATIC (derived from stage mode)
Result:
  - Stages advance manually (user must trigger)
  - Relays controlled automatically
  - Manual overrides still work for individual relays
```

### Example 3: MANUAL Stage Mode
```
Stage Mode: MANUAL
Control Mode: MANUAL (derived from stage mode)
Result:
  - Stages advance manually
  - Relays controlled manually only (via override bits)
  - No automatic control
```

### Example 4: Emergency Stop
```
Stage Mode: (any)
Control Mode: SAFETY (via override bit)
Result:
  - All relays OFF immediately
  - No automatic control
  - Stage advancement paused
```

### Example 5: Disable Automation Bit
```
Stage Mode: FULL or SEMI
Control Mode: MANUAL (via override bit)
Result:
  - Stage mode unchanged (still FULL/SEMI)
  - Automatic relay control disabled
  - Manual overrides required for relay control
```

---

## Mode Persistence

### Stage Mode Persistence
- Stored in `current_stage` table in database
- Persists across service restarts
- Loaded on service startup

### Control Mode Persistence
- Stored in `current_stage.control_mode` column in database
- Persists across service restarts
- Loaded on service startup
- If no persisted control mode exists, derived from stage mode

**Implementation:** `mushpi/app/core/control.py` - `set_mode()` saves to database

---

## Changing Modes

### Changing Stage Mode
- Via Flutter app: Stage configuration page
- Via BLE: `STAGE_STATE` characteristic
- Immediately updates control mode based on mapping

### Changing Control Mode
- Automatically: When stage mode changes
- Via BLE: Override bits (DISABLE_AUTOMATION, EMERGENCY_STOP)
- Directly: `control_system.set_mode()` (for internal use)

---

## Best Practices

1. **Use FULL mode** for hands-off operation when environmental conditions are stable
2. **Use SEMI mode** when you want to monitor and manually advance stages
3. **Use MANUAL mode** for troubleshooting, custom control, or when sensors are unreliable
4. **Use emergency stop** (bit15) for immediate safety shutdown
5. **Use DISABLE_AUTOMATION bit** (bit7) to temporarily disable automatic control without changing stage mode

---

## Technical Details

### Mode Loading on Startup
1. Service starts
2. Loads stage mode from database
3. Loads persisted control mode from database (if exists)
4. If no persisted control mode, derives from stage mode
5. Applies control mode to control system

**Code:** `mushpi/main.py` - `loop()` initialization

### Mode Updates at Runtime
1. Stage mode changed via BLE
2. Maps stage mode to control mode
3. Updates control system mode
4. Persists control mode to database

**Code:** `mushpi/main.py` - `set_stage_state()`

---

## Summary

- **Stage Modes** control stage advancement behavior
- **Control Modes** control automatic relay control behavior
- Stage modes automatically map to control modes
- Control modes can be overridden via BLE override bits
- Both modes persist across service restarts
- Emergency stop (SAFETY mode) takes highest priority






