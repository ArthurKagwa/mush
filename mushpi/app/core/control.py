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
from enum import Enum
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
        """Set relay state"""
        if relay_name not in self.relay_pins:
            logger.error(f"Unknown relay: {relay_name}")
            return False
            
        pin = self.relay_pins[relay_name]
        self.relay_states[relay_name] = state
        
        if self.simulation_mode or not GPIO_AVAILABLE:
            logger.info(f"[SIMULATION] Relay {relay_name} (pin {pin}) -> {state.name}")
            return True
            
        try:
            if state == RelayState.ON:
                gpio_value = GPIO.HIGH if self.active_high else GPIO.LOW
            else:
                gpio_value = GPIO.LOW if self.active_high else GPIO.HIGH
                
            GPIO.output(pin, gpio_value)
            logger.debug(f"Relay {relay_name} (pin {pin}) -> {state.name}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to set relay {relay_name}: {e}")
            return False
            
    def get_relay_state(self, relay_name: str) -> Optional[RelayState]:
        """Get current relay state"""
        return self.relay_states.get(relay_name)
        
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
        
        # Initialize controllers with hysteresis from config
        self.temp_hysteresis = config.control.temp_hysteresis
        self.humidity_hysteresis = config.control.humidity_hysteresis  
        self.co2_hysteresis = config.control.co2_hysteresis
        
        # Control state
        self.controllers: Dict[str, HysteresisController] = {}
        self.duty_trackers: Dict[str, DutyCycleTracker] = {}
        self.condensation_guard = CondensationGuard()
        self.light_schedule = LightSchedule()
        
        # Current thresholds (will be updated by external systems)
        self.current_thresholds: Dict[str, Threshold] = {}
        
        # Initialize duty cycle trackers
        self.duty_trackers['fan'] = DutyCycleTracker('fan', window_minutes=30, max_on_percent=60.0)
        self.duty_trackers['mist'] = DutyCycleTracker('mist', window_minutes=30, max_on_percent=40.0)
        
        logger.info("Control system initialized")
        
    def update_thresholds(self, thresholds: Dict[str, Threshold]) -> None:
        """Update control thresholds and reinitialize controllers"""
        self.current_thresholds = thresholds
        self._update_controllers()
        
    def _update_controllers(self) -> None:
        """Update hysteresis controllers based on current thresholds"""
        current_time = datetime.now()
        
        # Temperature controllers (fan and heater)
        if 'temperature' in self.current_thresholds:
            temp_threshold = self.current_thresholds['temperature']
            
            # Fan controller (cooling)
            if temp_threshold.max_value is not None:
                fan_high = temp_threshold.max_value
                fan_low = fan_high - self.temp_hysteresis
                self.controllers['fan_temp'] = HysteresisController(
                    'fan_temp', fan_low, fan_high
                )
                
            # Heater controller (heating)
            if temp_threshold.min_value is not None:
                heater_low = temp_threshold.min_value
                heater_high = heater_low + self.temp_hysteresis
                self.controllers['heater'] = HysteresisController(
                    'heater', heater_low, heater_high
                )
                
        # Humidity controller (mist)
        if 'humidity' in self.current_thresholds:
            humidity_threshold = self.current_thresholds['humidity']
            if humidity_threshold.min_value is not None:
                mist_low = humidity_threshold.min_value + self.humidity_hysteresis
                mist_high = humidity_threshold.min_value
                self.controllers['mist'] = HysteresisController(
                    'mist', mist_low, mist_high
                )
                
        # CO2 controller (fan)
        if 'co2' in self.current_thresholds:
            co2_threshold = self.current_thresholds['co2']
            if co2_threshold.max_value is not None:
                fan_co2_high = co2_threshold.max_value
                fan_co2_low = fan_co2_high - self.co2_hysteresis
                self.controllers['fan_co2'] = HysteresisController(
                    'fan_co2', fan_co2_low, fan_co2_high
                )
                
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
                    'exhaust_fan', RelayState.ON, 'Condensation guard', current_time
                )
                actions['condensation_mist'] = self._set_relay_with_tracking(
                    'humidifier', RelayState.OFF, 'Condensation guard', current_time
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
                
    def _process_temperature_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process temperature-based fan and heater control"""
        actions = {}
        
        if reading.temperature_c is None:
            return actions
            
        # Fan control for cooling
        if 'fan_temp' in self.controllers:
            controller = self.controllers['fan_temp']
            new_state, reason = controller.update(reading.temperature_c, current_time)
            
            if new_state == RelayState.ON and self.duty_trackers['fan'].can_turn_on(current_time):
                actions['fan_temp'] = self._set_relay_with_tracking(
                    'exhaust_fan', new_state, f"Temperature {reason}", current_time
                )
            elif new_state == RelayState.OFF:
                actions['fan_temp'] = self._set_relay_with_tracking(
                    'exhaust_fan', new_state, f"Temperature {reason}", current_time
                )
                
        # Heater control for heating
        if 'heater' in self.controllers:
            controller = self.controllers['heater']
            new_state, reason = controller.update(reading.temperature_c, current_time)
            
            actions['heater'] = self._set_relay_with_tracking(
                'heater', new_state, f"Temperature {reason}", current_time
            )
            
        return actions
        
    def _process_humidity_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process humidity-based mist control"""
        actions = {}
        
        if reading.humidity_percent is None or 'mist' not in self.controllers:
            return actions
            
        controller = self.controllers['mist']
        new_state, reason = controller.update(reading.humidity_percent, current_time)
        
        # Check duty cycle before turning on
        if new_state == RelayState.ON and not self.duty_trackers['mist'].can_turn_on(current_time):
            logger.warning("Mist duty cycle limit reached - skipping ON command")
            return actions
            
        actions['mist'] = self._set_relay_with_tracking(
            'humidifier', new_state, f"Humidity {reason}", current_time
        )
        
        return actions
        
    def _process_co2_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process CO2-based fan control"""
        actions = {}
        
        if reading.co2_ppm is None or 'fan_co2' not in self.controllers:
            return actions
            
        controller = self.controllers['fan_co2']
        new_state, reason = controller.update(reading.co2_ppm, current_time)
        
        if new_state == RelayState.ON and self.duty_trackers['fan'].can_turn_on(current_time):
            actions['fan_co2'] = self._set_relay_with_tracking(
                'exhaust_fan', new_state, f"CO2 {reason}", current_time
            )
        elif new_state == RelayState.OFF:
            actions['fan_co2'] = self._set_relay_with_tracking(
                'exhaust_fan', new_state, f"CO2 {reason}", current_time
            )
            
        return actions
        
    def _process_light_control(self, reading: SensorReading, current_time: datetime) -> Dict[str, RelayAction]:
        """Process light schedule control"""
        actions = {}
        
        should_be_on, reason = self.light_schedule.should_light_be_on(current_time)
        desired_state = RelayState.ON if should_be_on else RelayState.OFF
        
        current_state = self.relay_manager.get_relay_state('grow_light')
        if current_state != desired_state:
            actions['light'] = self._set_relay_with_tracking(
                'grow_light', desired_state, reason, current_time
            )
            
        return actions
        
    def _set_relay_with_tracking(self, relay_name: str, state: RelayState, 
                                reason: str, timestamp: datetime) -> RelayAction:
        """Set relay state and track the action"""
        success = self.relay_manager.set_relay(relay_name, state)
        
        action = RelayAction(
            timestamp=timestamp,
            relay=relay_name,
            state=state,
            reason=reason
        )
        
        # Update duty cycle tracking
        if relay_name in ['exhaust_fan', 'circulation_fan']:
            self.duty_trackers['fan'].add_action(timestamp, state)
        elif relay_name == 'humidifier':
            self.duty_trackers['mist'].add_action(timestamp, state)
            
        self.action_history.append(action)
        
        # Keep only recent history
        cutoff_time = timestamp - timedelta(hours=24)
        self.action_history = [a for a in self.action_history if a.timestamp > cutoff_time]
        
        if success:
            logger.info(f"Relay action: {relay_name} -> {state.name} ({reason})")
        else:
            logger.error(f"Failed relay action: {relay_name} -> {state.name} ({reason})")
            
        return action
        
    def set_mode(self, mode: ControlMode) -> None:
        """Set control mode"""
        old_mode = self.mode
        self.mode = mode
        logger.info(f"Control mode changed: {old_mode.value} -> {mode.value}")
        
        if mode == ControlMode.MANUAL:
            logger.info("Manual mode - automatic control disabled")
        elif mode == ControlMode.SAFETY:
            logger.warning("Safety mode - emergency stop activated")
            self.relay_manager.emergency_stop()
            
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
    'HysteresisController', 'CondensationGuard', 'LightSchedule'
]
