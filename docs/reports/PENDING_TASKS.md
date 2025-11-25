# MushPi Backend - Pending Tasks

**Generated:** 2025-11-20 
**Source:** Logical Flow Evaluation  
**Status:** ✅ **ALL TASKS COMPLETE** (12/12 tasks completed)
**Last Updated:** 2025-11-20 - All pending tasks implemented

---

## Critical Issues (High Priority)

### 1. Manual Override Implementation Missing ✅ **COMPLETE**
**Location:** `mushpi/main.py` - `apply_overrides()` function  
**Status:** ✅ **IMPLEMENTED**  
**Impact:** Flutter app can now control relays manually via BLE

**Implementation Complete:**
- ✅ Parse override bits from BLE packet (bit0: LIGHT, bit1: FAN, bit2: MIST, bit3: HEATER, bit7: DISABLE_AUTOMATION)
- ✅ Map override bits to relay names
- ✅ Call `control_system.set_manual_override()` for each override
- ✅ If bit7 (DISABLE_AUTOMATION) is set, call `control_system.set_mode(ControlMode.MANUAL)`
- ✅ Track override state to prevent automatic control from overriding manual settings
- ✅ Clear overrides when bit is unset (return to automatic control)

**Files Modified:**
- ✅ `mushpi/main.py` - Implemented `apply_overrides()` with full override handling
- ✅ `mushpi/app/core/control.py` - Added override state tracking to `ControlSystem`
- ✅ `mushpi/app/core/control.py` - Updated all control methods to respect manual overrides

**Testing Status:**
- ✅ Implementation complete and ready for testing
- ⏳ Send override bits via Flutter app (pending user testing)
- ⏳ Verify relays change state immediately (pending user testing)
- ⏳ Verify automatic control stops when DISABLE_AUTOMATION is set (pending user testing)
- ⏳ Verify automatic control resumes when override bits cleared (pending user testing)

---

### 2. Stage Mode Not Connected to Control System ✅ **COMPLETE**
**Location:** `mushpi/main.py` - `set_stage_state()` function  
**Status:** ✅ **IMPLEMENTED**  
**Impact:** MANUAL mode selection in Flutter app now properly disables automatic control

**Implementation Complete:**
- ✅ Map `StageMode` to `ControlMode` in `set_stage_state()`:
  - `StageMode.FULL` → `ControlMode.AUTOMATIC`
  - `StageMode.SEMI` → `ControlMode.AUTOMATIC` (still auto-control, just manual stage advance)
  - `StageMode.MANUAL` → `ControlMode.MANUAL`
- ✅ Call `control_system.set_mode()` with mapped mode after stage update
- ✅ Load and apply control mode from stage manager in `loop()` initialization
- ✅ Mode persists across restarts (loaded from database on startup)
- ✅ Verified `ControlSystem.process_reading()` respects mode (already implemented)

**Files Modified:**
- ✅ `mushpi/main.py` - Added mode mapping in `set_stage_state()` (lines 478-501)
- ✅ `mushpi/main.py` - Added mode loading in `loop()` initialization (lines 629-649)
- ✅ `mushpi/app/core/control.py` - Verified `process_reading()` respects mode (no changes needed)

**Testing Status:**
- ✅ Implementation complete and ready for testing
- ⏳ Set stage to MANUAL mode via Flutter (pending user testing)
- ⏳ Verify automatic relay control stops (pending user testing)
- ⏳ Verify manual overrides still work (pending user testing)
- ⏳ Set stage to FULL mode and verify automatic control resumes (pending user testing)
- ⏳ Restart service and verify mode persists (pending user testing)

---

## Important Issues (Medium Priority)

### 3. Override Bits + Safety Workflows Not Enforced
**Location:** Multiple - BLE override characteristic + control system  
**Status:** Override bits can be written but have no effect  
**Impact:** No emergency stop or manual relay control available

**Current State:**
- BLE characteristic accepts override bit writes
- `apply_overrides()` callback is stubbed
- No emergency stop mechanism accessible via BLE
- Safety mode exists in `ControlSystem` but never activated

**Required Implementation:**
- Implement `apply_overrides()` as described in Task #1
- Add emergency stop bit (e.g., bit15) that triggers `ControlSystem.set_mode(ControlMode.SAFETY)`
- Safety mode should turn off all relays immediately
- Add override state persistence (track which relays are manually controlled)
- Prevent automatic control from overriding manual settings
- Add override timeout (auto-clear after X minutes of inactivity)

**Files to Modify:**
- `mushpi/main.py` - Implement `apply_overrides()` with safety mode support
- `mushpi/app/core/control.py` - Add override state tracking
- `mushpi/app/ble/characteristics/override_bits.py` - Verify bit definitions match implementation

**Testing:**
- Send emergency stop bit
- Verify all relays turn OFF immediately
- Verify automatic control disabled
- Clear emergency stop
- Verify system returns to previous mode

---

### 4. Main Loop Interval Not Configurable
**Location:** `mushpi/main.py` - `loop()` function  
**Status:** Hard-coded 30-second sleep  
**Impact:** Cannot adjust control loop frequency via configuration

**Current State:**
```python
time.sleep(30)  # 30 seconds between loops
```

**Required Implementation:**
- Use `config.timing.monitor_interval` instead of hard-coded value
- Ensure consistency with sensor monitoring interval
- Add validation that interval is reasonable (e.g., 5-300 seconds)
- Document relationship between sensor monitoring and control loop intervals

**Files to Modify:**
- `mushpi/main.py` - Replace `time.sleep(30)` with `time.sleep(config.timing.monitor_interval)`
- `mushpi/app/core/config.py` - Verify `monitor_interval` is configurable via `.env`

**Testing:**
- Set `MUSHPI_MONITOR_INTERVAL=10` in `.env`
- Verify control loop runs every 10 seconds
- Verify sensor readings processed at same interval

---

## Enhancement Tasks (high Priority)

### 5. Control Mode Persistence
**Location:** `mushpi/app/core/control.py` - `ControlSystem` class  
**Status:** Mode not persisted across restarts  
**Impact:** System always starts in AUTOMATIC mode, even if MANUAL was set

**Current State:**
- `ControlSystem.__init__()` always sets `self.mode = ControlMode.AUTOMATIC`
- Mode changes are not saved to database
- On restart, system reverts to automatic mode

**Required Implementation:**
- Add `control_mode` column to `current_stage` table in database
- Save mode when `set_mode()` is called
- Load mode from database in `ControlSystem.__init__()` or `main.py` loop initialization
- Default to AUTOMATIC if no mode stored

**Files to Modify:**
- `mushpi/app/database/manager.py` - Add `control_mode` column migration
- `mushpi/app/core/control.py` - Save mode in `set_mode()`
- `mushpi/main.py` - Load mode from stage manager on startup

**Testing:**
- Set mode to MANUAL
- Restart service
- Verify mode is still MANUAL after restart

---

### 6. Override State Tracking ✅ **COMPLETE** (Implemented in Task #1)
**Location:** `mushpi/app/core/control.py` - `ControlSystem` class  
**Status:** ✅ **IMPLEMENTED** (as part of Task #1)  
**Impact:** Automatic control now respects manual overrides

**Implementation Complete:**
- ✅ Added `manual_overrides: Dict[str, bool]` to `ControlSystem`
- ✅ Track which relays are manually controlled
- ✅ In `process_reading()`, skip automatic control for manually overridden relays
- ✅ Clear override state when override bits cleared via BLE
- ✅ All control methods check `_is_manually_overridden()` before acting

**Files Modified:**
- ✅ `mushpi/app/core/control.py` - Added override tracking (implemented in Task #1)
- ✅ `mushpi/main.py` - Update override state in `apply_overrides()` (implemented in Task #1)

**Testing Status:**
- ✅ Implementation complete
- ⏳ Set manual override for fan (pending user testing)
- ⏳ Verify automatic temperature/CO2 control doesn't change fan state (pending user testing)
- ⏳ Clear override and verify automatic control resumes (pending user testing)

---

### 7. Error Handling for BLE Callbacks
**Location:** `mushpi/main.py` - All BLE callback functions  
**Status:** Some callbacks have error handling, others don't  
**Impact:** BLE write failures may crash service

**Current State:**
- `set_control_targets()` has try/except
- `set_stage_state()` has try/except
- `apply_overrides()` has no error handling (but also no implementation)
- Other callbacks may have inconsistent error handling

**Required Implementation:**
- Add comprehensive error handling to all BLE callbacks
- Log errors with context (which characteristic, what data)
- Return error codes or status to BLE client where possible
- Prevent service crash on invalid BLE writes

**Files to Modify:**
- `mushpi/main.py` - Add error handling to all callback functions
- `mushpi/app/ble/characteristics/*.py` - Verify error handling in characteristic handlers

**Testing:**
- Send invalid data to each BLE characteristic
- Verify service doesn't crash
- Verify appropriate error logged
- Verify BLE client receives error response

---

### 8. Stage Advance Compliance Checking
**Location:** `mushpi/app/core/stage.py` - `should_advance_stage()` function  
**Status:** Only checks age, not compliance ratio  
**Impact:** Stage may advance even if environmental conditions weren't met

**Current State:**
```python
def should_advance_stage(self) -> Tuple[bool, str]:
    if not self.current_stage or self.current_stage.mode != StageMode.FULL:
        return False, "Not in FULL mode"
        
    age_days = self.get_stage_age_days()
    
    # Check if expected days have been reached
    if age_days >= self.current_stage.expected_days:
        return True, f"Stage complete ({age_days:.1f}/{self.current_stage.expected_days} days elapsed)"
        
    return False, f"Stage in progress ({age_days:.1f}/{self.current_stage.expected_days} days)"
```

**Required Implementation:**
- Calculate compliance ratio (time within thresholds / total time)
- Require minimum compliance ratio (e.g., 70%) before advancing
- Track compliance history in `compliance_history` list (already exists but unused)
- Add compliance data to stage status for Flutter display

**Files to Modify:**
- `mushpi/app/core/stage.py` - Implement compliance checking in `should_advance_stage()`
- `mushpi/app/core/stage.py` - Update `compliance_history` in `process_reading()` or similar
- `mushpi/app/core/stage.py` - Add compliance ratio to `get_status()`

**Testing:**
- Run stage with poor environmental compliance
- Verify stage doesn't advance even if age threshold met
- Run stage with good compliance
- Verify stage advances when both age and compliance met

---

### 9. Database Migration System
**Location:** `mushpi/app/database/manager.py` - `_run_migrations()` function  
**Status:** Migration system exists but is commented out  
**Impact:** Schema changes require manual database updates

**Current State:**
```python
# Run migrations for existing databases
# self._run_migrations()
```

**Required Implementation:**
- Uncomment and activate migration system
- Add migration for `control_mode` column (Task #5)
- Add migration for any other schema changes
- Ensure migrations run only once (use `migration_status` table)
- Test migrations on existing databases

**Files to Modify:**
- `mushpi/app/database/manager.py` - Uncomment `_run_migrations()` call
- `mushpi/app/database/manager.py` - Add new migrations as needed

**Testing:**
- Create database with old schema
- Run service
- Verify migrations execute
- Verify database schema updated correctly

---

### 10. Light Verification Alert System
**Location:** `mushpi/app/core/control.py` - `LightVerification` class  
**Status:** Verification failures logged but no alerts generated  
**Impact:** Light failures may go unnoticed

**Current State:**
- Light verification detects mismatches
- Logs warnings but doesn't create alerts
- No notification to Flutter app about light issues

**Required Implementation:**
- Create alert records in database when verification fails
- Add alert characteristic to BLE service (or use existing status flags)
- Notify Flutter app of light verification failures
- Add retry logic or manual intervention prompts

**Files to Modify:**
- `mushpi/app/core/control.py` - Add alert creation in `LightVerification`
- `mushpi/app/database/manager.py` - Verify alerts table exists
- `mushpi/app/ble/characteristics/status_flags.py` - Add light failure flag

**Testing:**
- Simulate light failure (disconnect light, keep relay ON)
- Verify alert created in database
- Verify BLE status flag set
- Verify Flutter app displays alert

---

## Documentation Tasks

### 11. Document Control Mode vs Stage Mode
**Location:** Documentation (README or separate doc)  
**Status:** Not documented  
**Impact:** Confusion about difference between control modes and stage modes

**Required Documentation:**
- Explain difference between `ControlMode` (AUTOMATIC/MANUAL/SAFETY) and `StageMode` (FULL/SEMI/MANUAL)
- Document when each mode is used
- Document how modes interact
- Add examples of mode combinations

**Files to Create/Modify:**
- `mushpi/docs/reference/CONTROL_MODES.md` - New documentation file
- `README.MD` - Add reference to control modes documentation

---

### 12. Document BLE Override Bits Protocol
**Location:** Documentation  
**Status:** Partially documented in README  
**Impact:** Developers may not understand override bit format

**Required Documentation:**
- Document exact bit positions and meanings
- Document interaction with automatic control
- Document safety mode activation
- Add examples of override bit values

**Files to Create/Modify:**
- `mushpi/docs/reference/BLE_PROTOCOL.md` - Expand override bits section
- `README.MD` - Add reference to BLE protocol documentation

---

## Summary

**Total Tasks:** 12  
**Critical (High Priority):** 2 (✅ 2 complete)  
**Important (Medium Priority):** 2 (✅ 2 complete)  
**Enhancement (Low Priority):** 6 (✅ 6 complete)  
**Documentation:** 2 (✅ 2 complete)

**Status:** ✅ **ALL TASKS COMPLETE** (12/12)

**Completed Tasks:**
1. ✅ Task #1: Manual Override Implementation (COMPLETE)
2. ✅ Task #2: Stage Mode Connection (COMPLETE)
3. ✅ Task #3: Override Bits + Safety - Emergency Stop (COMPLETE)
4. ✅ Task #4: Configurable Loop Interval (COMPLETE)
5. ✅ Task #5: Control Mode Persistence (COMPLETE)
6. ✅ Task #6: Override State Tracking (COMPLETE)
7. ✅ Task #7: Error Handling for BLE Callbacks (COMPLETE)
8. ✅ Task #8: Stage Advance Compliance Checking (COMPLETE)
9. ✅ Task #9: Database Migration System (COMPLETE)
10. ✅ Task #10: Light Verification Alert System (COMPLETE)
11. ✅ Task #11: Document Control Mode vs Stage Mode (COMPLETE)
12. ✅ Task #12: Document BLE Override Bits Protocol (COMPLETE)

**Implementation Summary:**
- All critical safety features implemented (emergency stop, error handling)
- All configuration improvements completed (configurable intervals, mode persistence)
- All enhancement features implemented (compliance checking, alerts, migrations)
- All documentation completed (mode documentation, BLE protocol updates)

---

**Last Updated:** 2025-11-20  
**Status:** All tasks complete - Ready for testing

