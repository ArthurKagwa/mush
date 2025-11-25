"""
MushPi Control System

Relay control logic with hysteresis, safety features, and duty cycle management.
Manages FAN, MIST, LIGHT, and HEATER actuators based on sensor readings and thresholds.
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple, List
from dataclasses import dataclass
from enum import Enum, IntEnum
from collections import deque

from .config import config
from ..models.dataclasses import SensorReading, Threshold

# Import GPIO handling with fallback for development
try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    GPIO_AVAILABLE = False

logger = logging.getLogger(__name__)


class RelayReasonCode(IntEnum):
    """Compact reason codes for relay state changes (1 byte each for BLE efficiency)
    
    These codes are transmitted via BLE and decoded in the Flutter app to show
    the same detailed reasoning that appears in Pi logs.
    
    Code ranges:
    0-9: System states
    10-29: Temperature control
    30-49: Humidity control
    50-69: CO2 control
    70-89: Light control
    90-109: Duty cycle limits
    110-129: Safety/guards
    130-149: Manual/overrides
    150-255: Reserved for future use
    """
    # System states (0-9)
    INITIALIZED = 0
    NO_CHANGE = 1
    RATE_LIMITED = 2
    SYSTEM_ERROR = 3
    
    # Temperature control (10-29)
    TEMP_TOO_HIGH = 10          # Fan cooling: temp >= max threshold
    TEMP_NORMAL_HIGH = 11       # Fan off: temp <= max - hysteresis
    TEMP_TOO_LOW = 12           # Heater on: temp <= min threshold
    TEMP_NORMAL_LOW = 13        # Heater off: temp >= min + hysteresis
    TEMP_NO_THRESHOLD = 14      # No temp threshold configured
    
    # Humidity control (30-49)
    HUMIDITY_TOO_LOW = 30       # Mist on: RH <= min threshold
    HUMIDITY_NORMAL = 31        # Mist off: RH >= min + hysteresis
    HUMIDITY_TOO_HIGH = 32      # Fan on for dehumidification
    HUMIDITY_NO_THRESHOLD = 33  # No humidity threshold configured
    
    # CO2 control (50-69)
    CO2_TOO_HIGH = 50           # Fan on: CO2 >= max threshold
    CO2_NORMAL = 51             # Fan off: CO2 <= max - hysteresis
    CO2_NO_THRESHOLD = 52       # No CO2 threshold configured
    
    # Light control (70-89)
    LIGHT_SCHEDULE_ON = 70      # Light on per schedule
    LIGHT_SCHEDULE_OFF = 71     # Light off per schedule
    LIGHT_ALWAYS_ON = 72        # Light mode: always on
    LIGHT_ALWAYS_OFF = 73       # Light mode: always off/disabled
    LIGHT_CYCLE = 74            # Light in cycle mode
    LIGHT_VERIFICATION_FAIL = 75  # Light failed verification
    
    # Duty cycle limits (90-109)
    DUTY_CYCLE_MAXED = 90       # Relay at max duty cycle percentage
    DUTY_CYCLE_AVAILABLE = 91   # Duty cycle within limits
    
    # Safety/Guards (110-129)
    CONDENSATION_GUARD_ACTIVE = 110    # Mist blocked by condensation guard
    CONDENSATION_GUARD_INACTIVE = 111  # Condensation guard cleared
    EMERGENCY_STOP = 112        # Emergency stop activated
    
    # Manual/Overrides (130-149)
    MANUAL_OVERRIDE_ON = 130    # Manually forced ON
    MANUAL_OVERRIDE_OFF = 131   # Manually forced OFF
    MANUAL_MODE_ACTIVE = 132    # System in manual mode
    
    # Unknown/Default (250-255)
    UNKNOWN = 255


class RelayState(Enum):
    """Relay state enumeration"""
    OFF = 0
    ON = 1


class ControlMode(Enum):
    """Control mode enumeration"""
    MANUAL = "manual"      # Manual override only
    AUTOMATIC = "automatic"  # Full automatic control
    SAFETY = "safety"      # Emergency safety mode


@dataclass
class RelayAction:
    """Record of a relay action"""
    timestamp: datetime
    relay: str
    state: RelayState
    reason: str
    duration_ms: Optional[int] = None


@dataclass
class DutyCycleTracker:
    """Track duty cycle for a relay over time windows"""
    relay_name: str
    window_minutes: int = 30
    max_on_percent: float = 50.0  # Maximum % time relay can be ON
    
    def __init__(self, relay_name: str, window_minutes: int = 30, max_on_percent: float = 50.0):
        self.relay_name = relay_name
        self.window_minutes = window_minutes
        self.max_on_percent = max_on_percent
        self.actions: deque = deque()  # Store (timestamp, state) tuples
        
    def add_action(self, timestamp: datetime, state: RelayState) -> None:
        """Add a relay action to the tracker"""
        self.actions.append((timestamp, state))
        self._cleanup_old_actions(timestamp)
        
    def _cleanup_old_actions(self, current_time: datetime) -> None:
        """Remove actions older than the window"""
        cutoff_time = current_time - timedelta(minutes=self.window_minutes)
        while self.actions and self.actions[0][0] < cutoff_time:
            self.actions.popleft()
            
    def get_on_time_percent(self, current_time: datetime) -> float:
        """Calculate percentage of time relay was ON in the current window"""
        self._cleanup_old_actions(current_time)
        
        if not self.actions:
            return 0.0
            
        window_start = current_time - timedelta(minutes=self.window_minutes)
        total_on_time = 0.0
        
        # Calculate ON time by going through state changes
        current_state = RelayState.OFF
        last_change_time = window_start
        
        for timestamp, state in self.actions:
            if current_state == RelayState.ON:
                total_on_time += (timestamp - last_change_time).total_seconds()
            current_state = state
            last_change_time = timestamp
            
        # Account for current state if still ON
        if current_state == RelayState.ON:
            total_on_time += (current_time - last_change_time).total_seconds()
            
        window_seconds = self.window_minutes * 60
        return (total_on_time / window_seconds) * 100.0
        
    def can_turn_on(self, current_time: datetime) -> bool:
        """Check if relay can be turned ON without exceeding duty cycle"""
        return self.get_on_time_percent(current_time) < self.max_on_percent


class HysteresisController:
    """Hysteresis controller for smooth relay operation"""
    
    def __init__(self, relay_name: str, threshold_low: float, threshold_high: float, 
                 current_state: RelayState = RelayState.OFF):
        self.relay_name = relay_name
        self.threshold_low = threshold_low  # Turn OFF threshold
        self.threshold_high = threshold_high  # Turn ON threshold
        self.current_state = current_state
        self.last_change_time = datetime.now()
        self.min_state_duration = 30.0  # Minimum seconds between state changes
        
    def update(self, current_value: float, current_time: datetime) -> Tuple[RelayState, str]:
        """Update controller state based on current value"""
        time_since_change = (current_time - self.last_change_time).total_seconds()
        
        # Prevent rapid state changes
        if time_since_change < self.min_state_duration:
            return self.current_state, f"Rate limited (min {self.min_state_duration}s)"
            
        new_state = self.current_state
        reason = "No change"
        
        if self.current_state == RelayState.OFF and current_value >= self.threshold_high:
            new_state = RelayState.ON
            reason = f"Value {current_value:.1f} >= threshold {self.threshold_high:.1f}"
        elif self.current_state == RelayState.ON and current_value <= self.threshold_low:
            new_state = RelayState.OFF  
            reason = f"Value {current_value:.1f} <= threshold {self.threshold_low:.1f}"
            
        if new_state != self.current_state:
            self.current_state = new_state
            self.last_change_time = current_time
            
        return self.current_state, reason


class CondensationGuard:
    """Prevent excessive condensation by monitoring humidity and temperature"""
    
    def __init__(self, critical_rh: float = 96.0, critical_duration_minutes: int = 5):
        self.critical_rh = critical_rh
        self.critical_duration = timedelta(minutes=critical_duration_minutes)
        self.high_rh_start: Optional[datetime] = None
        self.active = False
        
    def update(self, humidity: float, temperature: float, current_time: datetime) -> bool:
        """Update guard state and return True if condensation protection should activate"""
        
        # Check for critically high humidity
        if humidity >= self.critical_rh:
            if self.high_rh_start is None:
                self.high_rh_start = current_time
                logger.info(f"High humidity detected: {humidity:.1f}% >= {self.critical_rh:.1f}%")
                
            # Check if high humidity has persisted too long
            if current_time - self.high_rh_start >= self.critical_duration:
                if not self.active:
                    logger.warning(f"Condensation guard activated: RH {humidity:.1f}% for {self.critical_duration}")
                    self.active = True
                return True
        else:
            # Reset if humidity drops
            if self.high_rh_start is not None:
                logger.info(f"Humidity normalized: {humidity:.1f}%")
                self.high_rh_start = None
                if self.active:
                    logger.info("Condensation guard deactivated")
                    self.active = False
                    
        return self.active


class LightSchedule:
    """Manage light timing based on stage configuration"""
    
    def __init__(self):
        self.mode = "off"  # "off", "on", "cycle"
        self.on_minutes = 0
        self.off_minutes = 0
        self.cycle_start: Optional[datetime] = None
        
    def update_schedule(self, mode: str, on_minutes: int = 0, off_minutes: int = 0) -> None:
        """Update light schedule parameters"""
        self.mode = mode.lower()
        self.on_minutes = on_minutes
        self.off_minutes = off_minutes
        if mode == "cycle" and self.cycle_start is None:
            self.cycle_start = datetime.now()
            
    def should_light_be_on(self, current_time: datetime) -> Tuple[bool, str]:
        """Determine if light should be on based on schedule"""
        if self.mode == "off":
            return False, "Schedule: OFF mode"
        elif self.mode == "on":
            return True, "Schedule: ON mode"
        elif self.mode == "cycle":
            if self.cycle_start is None:
                self.cycle_start = current_time
                
            elapsed_minutes = (current_time - self.cycle_start).total_seconds() / 60
            cycle_duration = self.on_minutes + self.off_minutes
            
            if cycle_duration <= 0:
                return False, "Schedule: Invalid cycle duration"
                
            position_in_cycle = elapsed_minutes % cycle_duration
            
            if position_in_cycle < self.on_minutes:
                return True, f"Schedule: ON phase ({position_in_cycle:.0f}/{self.on_minutes}min)"
            else:
                off_position = position_in_cycle - self.on_minutes
                return False, f"Schedule: OFF phase ({off_position:.0f}/{self.off_minutes}min)"
        
        return False, f"Schedule: Unknown mode '{self.mode}'"


class LightVerification:
    """Monitor and verify light functionality using photoresistor feedback"""
    
    def __init__(self, on_threshold: float = 200.0, off_threshold: float = 50.0, 
                 verification_delay: float = 30.0):
        self.on_threshold = on_threshold    # Light level when light should be detected as ON
        self.off_threshold = off_threshold  # Light level when light should be detected as OFF
        self.verification_delay = verification_delay  # Seconds to wait before verifying
        self.last_state_change: Optional[datetime] = None
        self.last_verification_alert: Optional[datetime] = None
        self.verification_failures = 0
        
    def verify_light_operation(self, expected_state: RelayState, actual_light_level: float, 
                             current_time: datetime) -> Tuple[bool, str]:
        """Verify that light operation matches expected state
        
        Args:
            expected_state: Whether light should be ON or OFF
            actual_light_level: Current light sensor reading (0-1000)
            current_time: Current timestamp
            
        Returns:
            (is_correct, status_message)
        """
        # Don't verify immediately after state change - allow time for light to stabilize
        if (self.last_state_change and 
            (current_time - self.last_state_change).total_seconds() < self.verification_delay):
            return True, f"Verification pending (waiting {self.verification_delay}s)"
            
        # Determine if light reading matches expected state
        if expected_state == RelayState.ON:
            is_correct = actual_light_level >= self.on_threshold
            expected_desc = f"bright (≥{self.on_threshold})"
        else:
            is_correct = actual_light_level <= self.off_threshold  
            expected_desc = f"dark (≤{self.off_threshold})"
            
        # Generate status message
        if is_correct:
            if self.verification_failures > 0:
                logger.info(f"Light verification recovered after {self.verification_failures} failures")
                self.verification_failures = 0
            return True, f"Light verified: {actual_light_level:.0f} units ({expected_desc})"
        else:
            self.verification_failures += 1
            
            # Rate limit alerts to avoid spam
            should_alert = (self.last_verification_alert is None or 
                          (current_time - self.last_verification_alert).total_seconds() > 300)  # 5 min
            
            if should_alert:
                self.last_verification_alert = current_time
                logger.warning(f"Light verification FAILED: expected {expected_desc}, "
                             f"got {actual_light_level:.0f} units (failure #{self.verification_failures})")
                
            return False, f"Light mismatch: {actual_light_level:.0f} units (expected {expected_desc})"
            
    def record_state_change(self, new_state: RelayState, timestamp: datetime) -> None:
        """Record when light state changes to reset verification timer"""
        self.last_state_change = timestamp
        logger.debug(f"Light verification: state changed to {new_state.name} at {timestamp}")


class RelayManager:
    """Manage GPIO relay operations with simulation support"""
    
    def __init__(self):
        self.simulation_mode = config.development.simulation_mode
        self.relay_pins = config.gpio.get_relay_pins()
        self.active_high = config.control.relay_active_high
        self.relay_states: Dict[str, RelayState] = {}
        
        if not self.simulation_mode and GPIO_AVAILABLE:
            self._init_gpio()
        else:
            logger.info("Running in simulation mode - GPIO operations will be logged only")
            
        # Initialize all relays to OFF
        for relay_name in self.relay_pins.keys():
            self.set_relay(relay_name, RelayState.OFF)
            
    def _init_gpio(self) -> None:
        """Initialize GPIO for relay control"""
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            
            for relay_name, pin in self.relay_pins.items():
                GPIO.setup(pin, GPIO.OUT)
                # Set to OFF state initially
                off_value = GPIO.LOW if self.active_high else GPIO.HIGH
                GPIO.output(pin, off_value)
                logger.info(f"Initialized relay {relay_name} on pin {pin}")
                
        except Exception as e:
            logger.error(f"Failed to initialize GPIO: {e}")
            self.simulation_mode = True
            
    def set_relay(self, relay_name: str, state: RelayState) -> bool:
        """Set relay state
        
        CRITICAL: Only updates relay_states dict if hardware write succeeds,
        ensuring single source of truth between software state and hardware.
        """
        if relay_name not in self.relay_pins:
            logger.error(f"Unknown relay: {relay_name}")
            return False
            
        pin = self.relay_pins[relay_name]
        
        if self.simulation_mode or not GPIO_AVAILABLE:
            logger.info(f"[SIMULATION] Relay {relay_name} (pin {pin}) -> {state.name}")
            # Update state dict only after "successful" simulation
            self.relay_states[relay_name] = state
            return True
            
        try:
            if state == RelayState.ON:
                gpio_value = GPIO.HIGH if self.active_high else GPIO.LOW
            else:
                gpio_value = GPIO.LOW if self.active_high else GPIO.HIGH
                
            GPIO.output(pin, gpio_value)
            logger.debug(f"Relay {relay_name} (pin {pin}) -> {state.name}")
            
            # ✅ FIXED: Update state dict ONLY after successful GPIO write
            self.relay_states[relay_name] = state
            return True
            
        except Exception as e:
            logger.error(f"Failed to set relay {relay_name}: {e}")
            # ✅ FIXED: Do NOT update relay_states on failure
            return False
            
    def get_relay_state(self, relay_name: str) -> Optional[RelayState]:
        """Get current relay state from internal tracking dict
        
        Returns the last known state from relay_states dict.
        For hardware verification, use get_actual_gpio_state() instead.
        """
        return self.relay_states.get(relay_name)
    
    def get_actual_gpio_state(self, relay_name: str) -> Optional[RelayState]:
        """Read actual relay state directly from GPIO hardware
        
        This provides ground truth by reading the physical pin state,
        useful for verification and debugging state synchronization issues.
        
        Returns:
            RelayState if hardware can be read, None if unavailable
        """
        if relay_name not in self.relay_pins:
            logger.error(f"Unknown relay: {relay_name}")
            return None
            
        # In simulation mode, return tracked state
        if self.simulation_mode or not GPIO_AVAILABLE:
            return self.relay_states.get(relay_name)
        
        try:
            pin = self.relay_pins[relay_name]
            gpio_value = GPIO.input(pin)
            
            # Convert GPIO level to RelayState based on active_high config
            if self.active_high:
                # Active high: HIGH=ON, LOW=OFF
                return RelayState.ON if gpio_value == GPIO.HIGH else RelayState.OFF
            else:
                # Active low: LOW=ON, HIGH=OFF
                return RelayState.ON if gpio_value == GPIO.LOW else RelayState.OFF
                
        except Exception as e:
            logger.error(f"Failed to read GPIO state for {relay_name}: {e}")
            # Fallback to tracked state
            return self.relay_states.get(relay_name)
    
    def verify_relay_states(self) -> Dict[str, bool]:
        """Verify all relay states match hardware
        
        Returns dict of {relay_name: matches} where matches=True if
        tracked state equals hardware state.
        """
        results = {}
        for relay_name in self.relay_pins.keys():
            tracked = self.relay_states.get(relay_name)
            actual = self.get_actual_gpio_state(relay_name)
            results[relay_name] = (tracked == actual)
            
            if tracked != actual:
                logger.warning(
                    f"State mismatch for {relay_name}: "
                    f"tracked={tracked.name if tracked else 'None'}, "
                    f"actual={actual.name if actual else 'None'}"
                )
        
        return results
        
    def emergency_stop(self) -> None:
        """Turn off all relays immediately"""
        logger.warning("Emergency stop - turning off all relays")
        for relay_name in self.relay_pins.keys():
            self.set_relay(relay_name, RelayState.OFF)
            
    def cleanup(self) -> None:
        """Cleanup GPIO resources"""
        if not self.simulation_mode and GPIO_AVAILABLE:
            try:
                GPIO.cleanup()
                logger.info("GPIO cleanup completed")
            except Exception as e:
                logger.error(f"GPIO cleanup failed: {e}")


class ControlSystem:
    """Main control system coordinating all actuators"""
    
    def __init__(self):
        self.relay_manager = RelayManager()
        self.mode = ControlMode.AUTOMATIC
        self.last_reading: Optional[SensorReading] = None
        self.action_history: List[RelayAction] = []
        
        # Track current reason code for each relay's state (for BLE/app display)
        # Key: relay_name, Value: reason code (u8, 0-255)
        # These codes are decoded in Flutter app to show same reasons as Pi logs
        self.relay_reasons: Dict[str, int] = {
            'exhaust_fan': int(RelayReasonCode.INITIALIZED),
            'circulation_fan': int(RelayReasonCode.INITIALIZED),
            'humidifier': int(RelayReasonCode.INITIALIZED),
            'grow_light': int(RelayReasonCode.INITIALIZED),
            'heater': int(RelayReasonCode.INITIALIZED)
        }
        
        # Initialize controllers with hysteresis from config
        self.temp_hysteresis = config.control.temp_hysteresis
        self.humidity_hysteresis = config.control.humidity_hysteresis  
        self.co2_hysteresis = config.control.co2_hysteresis
        
        # Control state
        self.controllers: Dict[str, HysteresisController] = {}
        self.duty_trackers: Dict[str, DutyCycleTracker] = {}
        self.condensation_guard = CondensationGuard()
        self.light_schedule = LightSchedule()
        self.light_verification = LightVerification(
            on_threshold=config.control.light_on_threshold,
            off_threshold=config.control.light_off_threshold,
            verification_delay=config.control.light_verification_delay
        )
        
        # Current thresholds (will be updated by external systems)
        self.current_thresholds: Dict[str, Threshold] = {}
        
        # Initialize duty cycle trackers
        self.duty_trackers['fan'] = DutyCycleTracker('fan', window_minutes=30, max_on_percent=60.0)
        self.duty_trackers['mist'] = DutyCycleTracker('mist', window_minutes=30, max_on_percent=40.0)
        
        # Manual override state tracking
        # Key: relay_name, Value: bool (True if manually overridden)
        # When a relay is manually overridden, automatic control should not change its state
        self.manual_overrides: Dict[str, bool] = {
            'exhaust_fan': False,
            'circulation_fan': False,
            'humidifier': False,
            'grow_light': False,
            'heater': False
        }
        
        logger.info("Control system initialized")
        
    def update_thresholds(self, thresholds: Dict[str, Threshold]) -> None:
        """Update control thresholds and reinitialize controllers"""
        self.current_thresholds = thresholds
        self._update_controllers()
        
    def _update_controllers(self) -> None:
        """Update hysteresis controllers based on current thresholds
        
        Hysteresis logic:
        - For "turn ON when too HIGH" (cooling): threshold_low = max - hysteresis, threshold_high = max
          Turn ON when value >= max, turn OFF when value <= max - hysteresis
        - For "turn ON when too LOW" (heating/humidifying): threshold_low = min, threshold_high = min + hysteresis  
          Turn ON when value <= min, turn OFF when value >= min + hysteresis
        """
        current_time = datetime.now()
        
        # Temperature controllers (fan and heater)
        if 'temperature' in self.current_thresholds:
            temp_threshold = self.current_thresholds['temperature']
            
            # Fan controller (cooling) - turn ON when TOO HOT
            if temp_threshold.max_value is not None:
                fan_high = temp_threshold.max_value  # Turn ON at this temp
                fan_low = fan_high - self.temp_hysteresis  # Turn OFF at this temp
                self.controllers['fan_temp'] = HysteresisController(
                    'fan_temp', fan_low, fan_high
                )
                logger.debug(f"Fan cooling: ON >= {fan_high}°C, OFF <= {fan_low}°C")
                
            # Heater controller (heating) - turn ON when TOO COLD
            # INVERTED LOGIC: For heating, we want ON when value is LOW
            # HysteresisController: Turn ON when value >= high, OFF when value <= low
            # To turn ON when COLD: high = min (turn ON threshold), low = min - hysteresis (turn OFF threshold)
            if temp_threshold.min_value is not None:
                heater_high = temp_threshold.min_value  # Turn ON below this temp
                heater_low = heater_high - self.temp_hysteresis  # Turn OFF below this temp
                # NOTE: Controller will trigger ON when temp <= heater_high (inverted in process function)
                self.controllers['heater'] = HysteresisController(
                    'heater', heater_low, heater_high
                )
                logger.debug(f"Heater: ON <= {heater_high}°C, OFF >= {heater_high + self.temp_hysteresis}°C")
                
        # Humidity controller (mist) - turn ON when TOO DRY
        # INVERTED LOGIC: For humidifying, we want ON when value is LOW
        if 'humidity' in self.current_thresholds:
            humidity_threshold = self.current_thresholds['humidity']
            if humidity_threshold.min_value is not None:
                mist_high = humidity_threshold.min_value  # Turn ON below this RH
                mist_low = mist_high - self.humidity_hysteresis  # Turn OFF below this RH
                # NOTE: Controller will trigger ON when RH <= mist_high (inverted in process function)
                self.controllers['mist'] = HysteresisController(
                    'mist', mist_low, mist_high
                )
                logger.debug(f"Mist: ON <= {mist_high}%, OFF >= {mist_high + self.humidity_hysteresis}%")
                
        # CO2 controller (fan) - turn ON when TOO HIGH
        if 'co2' in self.current_thresholds:
            co2_threshold = self.current_thresholds['co2']
            if co2_threshold.max_value is not None:
                fan_co2_high = co2_threshold.max_value  # Turn ON at this CO2
                fan_co2_low = fan_co2_high - self.co2_hysteresis  # Turn OFF at this CO2
                self.controllers['fan_co2'] = HysteresisController(
                    'fan_co2', fan_co2_low, fan_co2_high
                )
                logger.debug(f"Fan ventilation: ON >= {fan_co2_high}ppm, OFF <= {fan_co2_low}ppm")
                
        logger.info(f"Updated {len(self.controllers)} controllers with new thresholds")
        
    def update_light_schedule(self, mode: str, on_minutes: int = 0, off_minutes: int = 0) -> None:
        """Update light schedule"""
        self.light_schedule.update_schedule(mode, on_minutes, off_minutes)
        logger.info(f"Light schedule updated: {mode}, on={on_minutes}min, off={off_minutes}min")
        
    def process_reading(self, reading: SensorReading) -> Dict[str, RelayAction]:
        """Process sensor reading and update relay states"""
        if self.mode != ControlMode.AUTOMATIC:
            return {}
            
        self.last_reading = reading
        current_time = reading.timestamp
        actions = {}
        
        # Check for valid sensor data
        if not self._has_valid_data(reading):
            logger.warning("Invalid sensor reading - skipping control update")
            return {}
            
        # Update condensation guard
        if reading.humidity_percent is not None and reading.temperature_c is not None:
            condensation_active = self.condensation_guard.update(
                reading.humidity_percent, reading.temperature_c, current_time
            )
            
            # If condensation guard is active, force ventilation and stop misting
            if condensation_active:
                actions['condensation_fan'] = self._set_relay_with_tracking(
                    'exhaust_fan', RelayState.ON, 
                    RelayReasonCode.CONDENSATION_GUARD_ACTIVE,
                    'Condensation guard',
                    current_time
                )
                actions['condensation_mist'] = self._set_relay_with_tracking(
                    'humidifier', RelayState.OFF, 
                    RelayReasonCode.CONDENSATION_GUARD_ACTIVE,
                    'Condensation guard',
                    current_time
                )
                return actions
                
        # Process each control loop
        actions.update(self._process_temperature_control(reading, current_time))
        actions.update(self._process_humidity_control(reading, current_time))
        actions.update(self._process_co2_control(reading, current_time))
        actions.update(self._process_light_control(reading, current_time))
        
        return actions
        
    def _has_valid_data(self, reading: SensorReading) -> bool:
        """Check if reading has sufficient valid data for control decisions"""
        return (reading.temperature_c is not None or 
                reading.humidity_percent is not None or 
                reading.co2_ppm is not None)
    
    def _is_manually_overridden(self, relay_name: str) -> bool:
        """Check if a relay is currently under manual override control"""
        return self.manual_overrides.get(relay_name, False)
                
    def _process_temperature_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process temperature-based fan and heater control"""
        actions = {}
        
        if reading.temperature_c is None:
            return actions
            
        # Fan control for cooling (turn ON when TOO HOT)
        # Skip if fan is manually overridden
        if 'fan_temp' in self.controllers and not self._is_manually_overridden('exhaust_fan'):
            controller = self.controllers['fan_temp']
            new_state, reason = controller.update(reading.temperature_c, current_time)
            
            if new_state == RelayState.ON and self.duty_trackers['fan'].can_turn_on(current_time):
                reason_code = RelayReasonCode.TEMP_TOO_HIGH
                actions['fan_temp'] = self._set_relay_with_tracking(
                    'exhaust_fan', new_state, reason_code, f"Temperature {reason}", current_time
                )
            elif new_state == RelayState.OFF:
                reason_code = RelayReasonCode.TEMP_NORMAL_HIGH
                actions['fan_temp'] = self._set_relay_with_tracking(
                    'exhaust_fan', new_state, reason_code, f"Temperature {reason}", current_time
                )
                
        # Heater control for heating (turn ON when TOO COLD)
        # Skip if heater is manually overridden
        # INVERTED: HysteresisController expects ON when value >= high
        # But we want ON when temp <= threshold, so we invert the controller state
        if 'heater' in self.controllers and not self._is_manually_overridden('heater'):
            controller = self.controllers['heater']
            # Pass temperature value to controller (it will check if temp <= threshold)
            controller_state, reason = controller.update(reading.temperature_c, current_time)
            
            # INVERT: If controller says OFF (temp >= threshold), we want heater ON
            # If controller says ON (temp <= threshold), we want heater OFF
            # Actually, let's use inverted value comparison
            if reading.temperature_c <= controller.threshold_high:
                # Temperature is below minimum - turn heater ON
                if controller.current_state == RelayState.OFF:
                    new_state = RelayState.ON
                    reason = f"Value {reading.temperature_c:.1f} <= threshold {controller.threshold_high:.1f}"
                else:
                    new_state = RelayState.ON
                    reason = "No change"
            elif reading.temperature_c >= controller.threshold_high + self.temp_hysteresis:
                # Temperature is above minimum + hysteresis - turn heater OFF  
                if controller.current_state == RelayState.ON:
                    new_state = RelayState.OFF
                    reason = f"Value {reading.temperature_c:.1f} >= threshold {controller.threshold_high + self.temp_hysteresis:.1f}"
                else:
                    new_state = RelayState.OFF
                    reason = "No change"
            else:
                # In hysteresis zone - maintain current state
                new_state = controller.current_state
                reason = "In hysteresis zone"
            
            # Update controller state
            controller.current_state = new_state
            controller.last_change_time = current_time
            
            reason_code = RelayReasonCode.TEMP_TOO_LOW if new_state == RelayState.ON else RelayReasonCode.TEMP_NORMAL_LOW
            actions['heater'] = self._set_relay_with_tracking(
                'heater', new_state, reason_code, f"Temperature {reason}", current_time
            )
            
        return actions
        
    def _process_humidity_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process humidity-based mist control (turn ON when TOO DRY)"""
        actions = {}
        
        # Skip if mist is manually overridden
        if reading.humidity_percent is None or 'mist' not in self.controllers or self._is_manually_overridden('humidifier'):
            return actions
            
        controller = self.controllers['mist']
        
        # INVERTED LOGIC: Turn mist ON when humidity is LOW (below threshold)
        if reading.humidity_percent <= controller.threshold_high:
            # Humidity is below minimum - turn mist ON
            if controller.current_state == RelayState.OFF:
                new_state = RelayState.ON
                reason = f"Value {reading.humidity_percent:.1f} <= threshold {controller.threshold_high:.1f}"
            else:
                new_state = RelayState.ON
                reason = "No change"
        elif reading.humidity_percent >= controller.threshold_high + self.humidity_hysteresis:
            # Humidity is above minimum + hysteresis - turn mist OFF
            if controller.current_state == RelayState.ON:
                new_state = RelayState.OFF
                reason = f"Value {reading.humidity_percent:.1f} >= threshold {controller.threshold_high + self.humidity_hysteresis:.1f}"
            else:
                new_state = RelayState.OFF
                reason = "No change"
        else:
            # In hysteresis zone - maintain current state
            new_state = controller.current_state
            reason = "In hysteresis zone"
        
        # Check duty cycle before turning on
        if new_state == RelayState.ON and not self.duty_trackers['mist'].can_turn_on(current_time):
            logger.warning("Mist duty cycle limit reached - skipping ON command")
            return actions
        
        # Update controller state
        controller.current_state = new_state
        controller.last_change_time = current_time
        
        reason_code = RelayReasonCode.HUMIDITY_TOO_LOW if new_state == RelayState.ON else RelayReasonCode.HUMIDITY_NORMAL
        actions['mist'] = self._set_relay_with_tracking(
            'humidifier', new_state, reason_code, f"Humidity {reason}", current_time
        )
        
        return actions
        
    def _process_co2_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process CO2-based fan control (turn ON when TOO HIGH)
        
        NOTE: This shares the exhaust_fan relay with temperature control.
        Fan should be ON if EITHER temperature OR CO2 is too high.
        We use OR logic by checking if fan is already ON from temp control.
        """
        actions = {}
        
        # Skip if fan is manually overridden
        if reading.co2_ppm is None or 'fan_co2' not in self.controllers or self._is_manually_overridden('exhaust_fan'):
            return actions
            
        controller = self.controllers['fan_co2']
        new_state, reason = controller.update(reading.co2_ppm, current_time)
        
        # Check current fan state - don't turn OFF if temperature control wants it ON
        current_fan_state = self.relay_manager.get_relay_state('exhaust_fan')
        
        if new_state == RelayState.ON:
            # CO2 too high - turn fan ON (regardless of temp control)
            if self.duty_trackers['fan'].can_turn_on(current_time):
                actions['fan_co2'] = self._set_relay_with_tracking(
                    'exhaust_fan', new_state, RelayReasonCode.CO2_TOO_HIGH, f"CO2 {reason}", current_time
                )
        elif new_state == RelayState.OFF:
            # CO2 is OK - but only turn fan OFF if temp control also doesn't need it
            # Check if fan_temp controller exists and wants fan ON
            temp_wants_fan_on = False
            if 'fan_temp' in self.controllers and reading.temperature_c is not None:
                temp_controller = self.controllers['fan_temp']
                # Check if temperature is above threshold
                if reading.temperature_c >= temp_controller.threshold_high:
                    temp_wants_fan_on = True
            
            # Only turn fan OFF if neither CO2 nor temperature needs it
            if not temp_wants_fan_on:
                actions['fan_co2'] = self._set_relay_with_tracking(
                    'exhaust_fan', RelayState.OFF, RelayReasonCode.CO2_NORMAL, f"CO2 {reason} (temp OK)", current_time
                )
            else:
                logger.debug("CO2 normal but temperature still high - keeping fan ON")
            
        return actions
        
    def _process_light_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process light schedule control with photoresistor verification"""
        actions = {}
        
        # Skip if light is manually overridden
        if self._is_manually_overridden('grow_light'):
            return actions
        
        should_be_on, reason = self.light_schedule.should_light_be_on(current_time)
        desired_state = RelayState.ON if should_be_on else RelayState.OFF
        
        current_state = self.relay_manager.get_relay_state('grow_light')
        
        # Control light based on schedule
        if current_state != desired_state:
            # Determine reason code based on schedule mode and desired state
            if "Always on" in reason:
                reason_code = RelayReasonCode.LIGHT_ALWAYS_ON
            elif "Always off" in reason:
                reason_code = RelayReasonCode.LIGHT_ALWAYS_OFF
            elif desired_state == RelayState.ON:
                reason_code = RelayReasonCode.LIGHT_SCHEDULE_ON
            else:
                reason_code = RelayReasonCode.LIGHT_SCHEDULE_OFF
                
            actions['light'] = self._set_relay_with_tracking(
                'grow_light', desired_state, reason_code, reason, current_time
            )
            # Record state change for verification timing
            self.light_verification.record_state_change(desired_state, current_time)
            
        # Verify light operation using photoresistor
        if reading.light_level is not None:
            current_relay_state = self.relay_manager.get_relay_state('grow_light')
            if current_relay_state is not None:
                is_correct, verification_msg = self.light_verification.verify_light_operation(
                    current_relay_state, reading.light_level, current_time
                )
                
                # Log verification results
                if is_correct:
                    logger.debug(f"Light verification: {verification_msg}")
                else:
                    logger.warning(f"Light verification: {verification_msg}")
                    # Create alert for light verification failure
                    try:
                        from ..database.manager import DatabaseManager
                        db = DatabaseManager()
                        db.create_alert(
                            alert_type='light_verification_failure',
                            severity='warning',
                            message=verification_msg,
                            component='grow_light',
                            metadata=f'{{"expected_state": "{current_relay_state.name}", "actual_light_level": {reading.light_level}, "failures": {self.light_verification.verification_failures}}}'
                        )
                    except Exception as e:
                        logger.error(f"Failed to create light verification alert: {e}")
                    
        return actions
            
        return actions
        
    def _set_relay_with_tracking(self, relay_name: str, state: RelayState, 
                                reason_code: RelayReasonCode, reason_details: str,
                                timestamp: datetime) -> RelayAction:
        """Set relay state and track the action
        
        Args:
            relay_name: Name of relay to control
            state: ON or OFF
            reason_code: Compact reason code for BLE transmission
            reason_details: Human-readable reason for logs (e.g., "Value 22.5°C >= threshold 24.0°C")
            timestamp: Action timestamp
            
        The reason_code is stored for BLE/app display, while reason_details
        is used for Pi logs to maintain detailed logging.
        """
        success = self.relay_manager.set_relay(relay_name, state)
        
        action = RelayAction(
            timestamp=timestamp,
            relay=relay_name,
            state=state,
            reason=reason_details  # Full string for logs/history
        )
        
        # Update duty cycle tracking
        if relay_name in ['exhaust_fan', 'circulation_fan']:
            self.duty_trackers['fan'].add_action(timestamp, state)
        elif relay_name == 'humidifier':
            self.duty_trackers['mist'].add_action(timestamp, state)
        
        # Store compact reason code for BLE/app display
        self.relay_reasons[relay_name] = int(reason_code)
            
        self.action_history.append(action)
        
        # Keep only recent history
        cutoff_time = timestamp - timedelta(hours=24)
        self.action_history = [a for a in self.action_history if a.timestamp > cutoff_time]
        
        if success:
            logger.info(f"Relay action: {relay_name} -> {state.name} ({reason_details})")
        else:
            logger.error(f"Failed relay action: {relay_name} -> {state.name} ({reason_details})")
            
        return action
        
    def set_mode(self, mode: ControlMode) -> None:
        """Set control mode and persist to database"""
        old_mode = self.mode
        self.mode = mode
        logger.info(f"Control mode changed: {old_mode.value} -> {mode.value}")
        
        if mode == ControlMode.MANUAL:
            logger.info("Manual mode - automatic control disabled")
        elif mode == ControlMode.SAFETY:
            logger.warning("Safety mode - emergency stop activated")
            self.relay_manager.emergency_stop()
        
        # Persist control mode to database
        try:
            from ..database.manager import DatabaseManager
            db = DatabaseManager()
            # Get current stage info to save control mode
            stage_data = db.get_current_stage()
            if stage_data:
                db.save_current_stage(
                    species=stage_data['species'],
                    stage=stage_data['stage'],
                    mode=stage_data['mode'],
                    start_time=float(stage_data['start_time']),
                    expected_days=stage_data['expected_days'],
                    control_mode=mode.value
                )
                logger.debug(f"Control mode persisted to database: {mode.value}")
        except Exception as e:
            logger.warning(f"Failed to persist control mode to database: {e}")
    
    def set_manual_override(self, relay_name: str, override: bool, state: Optional[RelayState] = None) -> bool:
        """Set or clear manual override for a relay
        
        Args:
            relay_name: Name of relay to override (e.g., 'grow_light', 'exhaust_fan')
            override: True to enable manual override, False to clear and return to automatic
            state: Optional relay state to set when enabling override. If None, maintains current state.
            
        Returns:
            True if successful, False otherwise
        """
        if relay_name not in self.manual_overrides:
            logger.error(f"Unknown relay name for override: {relay_name}")
            return False
        
        if override:
            # Enable manual override
            self.manual_overrides[relay_name] = True
            
            # Set relay state if provided, otherwise maintain current state
            if state is not None:
                success = self.relay_manager.set_relay(relay_name, state)
                if success:
                    # Update reason code
                    self.relay_reasons[relay_name] = int(RelayReasonCode.MANUAL_OVERRIDE_ON if state == RelayState.ON else RelayReasonCode.MANUAL_OVERRIDE_OFF)
                    logger.info(f"Manual override enabled for {relay_name} -> {state.name}")
                else:
                    logger.error(f"Failed to set relay state for manual override: {relay_name}")
                    return False
            else:
                # Maintain current state, just mark as overridden
                current_state = self.relay_manager.get_relay_state(relay_name)
                if current_state:
                    self.relay_reasons[relay_name] = int(RelayReasonCode.MANUAL_OVERRIDE_ON if current_state == RelayState.ON else RelayReasonCode.MANUAL_OVERRIDE_OFF)
                logger.info(f"Manual override enabled for {relay_name} (maintaining current state)")
        else:
            # Clear manual override - return to automatic control
            self.manual_overrides[relay_name] = False
            self.relay_reasons[relay_name] = int(RelayReasonCode.MANUAL_MODE_ACTIVE)
            logger.info(f"Manual override cleared for {relay_name} - returning to automatic control")
        
        return True
    
    def clear_all_overrides(self) -> None:
        """Clear all manual overrides and return all relays to automatic control"""
        for relay_name in list(self.manual_overrides.keys()):
            self.set_manual_override(relay_name, False)
        logger.info("All manual overrides cleared")
            
    def get_status(self) -> Dict:
        """Get current control system status"""
        current_time = datetime.now()
        
        relay_states = {}
        for relay_name in self.relay_manager.relay_pins.keys():
            state = self.relay_manager.get_relay_state(relay_name)
            relay_states[relay_name] = state.name if state else "UNKNOWN"
            
        duty_cycles = {}
        for name, tracker in self.duty_trackers.items():
            duty_cycles[name] = {
                'on_time_percent': tracker.get_on_time_percent(current_time),
                'max_percent': tracker.max_on_percent,
                'can_turn_on': tracker.can_turn_on(current_time)
            }
            
        return {
            'mode': self.mode.value,
            'relay_states': relay_states,
            'duty_cycles': duty_cycles,
            'condensation_guard_active': self.condensation_guard.active,
            'light_schedule': {
                'mode': self.light_schedule.mode,
                'on_minutes': self.light_schedule.on_minutes,
                'off_minutes': self.light_schedule.off_minutes
            },
            'light_verification': {
                'on_threshold': self.light_verification.on_threshold,
                'off_threshold': self.light_verification.off_threshold,
                'failures': self.light_verification.verification_failures,
                'last_alert': self.light_verification.last_verification_alert
            },
            'controllers_active': len(self.controllers),
            'recent_actions': len([a for a in self.action_history 
                                 if a.timestamp > current_time - timedelta(hours=1)])
        }
        
    def cleanup(self) -> None:
        """Cleanup control system resources"""
        logger.info("Control system cleanup")
        self.relay_manager.cleanup()


# Export main classes for external use
__all__ = [
    'ControlSystem', 'RelayState', 'ControlMode', 'RelayAction',
    'HysteresisController', 'CondensationGuard', 'LightSchedule', 'LightVerification'
]
