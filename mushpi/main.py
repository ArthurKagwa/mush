# main.py
from app.core import sensors, control, stage, ble_gatt
from app.core.control import ControlSystem
from app.core.stage import StageManager, StageMode
from app.core.config import config
from app.database.manager import DatabaseManager
from app.models.dataclasses import Threshold
import logging
import time
import json

logger = logging.getLogger(__name__)

# Initialize main components
db = DatabaseManager()
control_system = ControlSystem()
stage_manager = StageManager()


def convert_stage_thresholds_to_threshold_objects(thresholds_dict: dict) -> dict:
    """Convert stage manager threshold dict to Threshold dataclass objects
    
    Args:
        thresholds_dict: Dict from stage_manager.get_current_thresholds()
            Example: {
                'temp_min': 24.0,
                'temp_max': 28.0,
                'rh_min': 80.0,
                'co2_max': 5000,
                'light': {'mode': 'off'}
            }
    
    Returns:
        Dict[str, Threshold]: Threshold objects keyed by parameter name
            Example: {'temperature': Threshold(...), 'humidity': Threshold(...)}
    """
    threshold_objects = {}
    
    # Temperature thresholds
    if 'temp_min' in thresholds_dict or 'temp_max' in thresholds_dict:
        threshold_objects['temperature'] = Threshold(
            parameter='temperature',
            min_value=thresholds_dict.get('temp_min'),
            max_value=thresholds_dict.get('temp_max'),
            hysteresis=1.0,  # Default from config
            active=True
        )
        logger.debug(f"Temperature threshold: {thresholds_dict.get('temp_min')}°C - {thresholds_dict.get('temp_max')}°C")
    
    # Humidity thresholds
    if 'rh_min' in thresholds_dict:
        threshold_objects['humidity'] = Threshold(
            parameter='humidity',
            min_value=thresholds_dict.get('rh_min'),
            max_value=thresholds_dict.get('rh_max'),  # Optional
            hysteresis=3.0,  # Default from config
            active=True
        )
        logger.debug(f"Humidity threshold: min {thresholds_dict.get('rh_min')}%")
    
    # CO2 thresholds
    if 'co2_max' in thresholds_dict:
        threshold_objects['co2'] = Threshold(
            parameter='co2',
            min_value=None,
            max_value=thresholds_dict.get('co2_max'),
            hysteresis=100.0,  # Default from config
            active=True
        )
        logger.debug(f"CO2 threshold: max {thresholds_dict.get('co2_max')} ppm")
    
    # Light thresholds (if defined)
    if 'light_min' in thresholds_dict or 'light_max' in thresholds_dict:
        threshold_objects['light'] = Threshold(
            parameter='light',
            min_value=thresholds_dict.get('light_min'),
            max_value=thresholds_dict.get('light_max'),
            hysteresis=50.0,
            active=True
        )
    
    return threshold_objects


def get_sensor_data():
    """Callback to get current sensor readings for BLE"""
    reading = sensors.get_current_readings()
    if reading:
        return {
            'temperature': reading.temperature_c,
            'humidity': reading.humidity_percent,
            'co2': reading.co2_ppm,
            'light': reading.light_level
        }
    return None


def get_control_data():
    """Callback to get current control system data for BLE (relay states + reason codes)
    
    CRITICAL: Returns actual hardware GPIO states, not just tracked states,
    to ensure accurate actuator status display in Flutter app.
    
    Returns:
        dict: Contains relay states (bool) and reason codes (int) for each actuator:
            {
                'fan': bool,
                'mist': bool,
                'light': bool,
                'heater': bool,
                'mode': str,
                'fan_reason': int,
                'mist_reason': int,
                'light_reason': int,
                'heater_reason': int
            }
    """
    # Get relay manager for direct GPIO state reads
    relay_manager = control_system.relay_manager
    
    # Read actual GPIO states (provides ground truth)
    # These methods fall back to tracked state if GPIO read fails
    fan_state = relay_manager.get_actual_gpio_state('exhaust_fan')
    mist_state = relay_manager.get_actual_gpio_state('humidifier')
    light_state = relay_manager.get_actual_gpio_state('grow_light')
    heater_state = relay_manager.get_actual_gpio_state('heater')
    
    # Get reason codes from control system
    reason_codes = control_system.relay_reasons
    
    # Get control mode
    status = control_system.get_status()
    
    # Map RelayState enum to boolean values for BLE
    from mushpi.app.core.control import RelayState
    control_data = {
        'fan': fan_state == RelayState.ON if fan_state else False,
        'mist': mist_state == RelayState.ON if mist_state else False,
        'light': light_state == RelayState.ON if light_state else False,
        'heater': heater_state == RelayState.ON if heater_state else False,
        'mode': status.get('mode', 'automatic'),
        'fan_reason': reason_codes.get('exhaust_fan', 0),
        'mist_reason': reason_codes.get('humidifier', 0),
        'light_reason': reason_codes.get('grow_light', 0),
        'heater_reason': reason_codes.get('heater', 0)
    }
    
    # Log control data that will be exposed via actuator_status characteristic.
    logger.info(
        "BLE get_control_data: mode=%s fan=%s(mist=%s,light=%s,heater=%s) "
        "reasons=[fan:%d,mist:%d,light:%d,heater:%d]",
        control_data['mode'],
        control_data['fan'],
        control_data['mist'],
        control_data['light'],
        control_data['heater'],
        control_data['fan_reason'],
        control_data['mist_reason'],
        control_data['light_reason'],
        control_data['heater_reason'],
    )
    
    return control_data


def get_control_targets():
    """Callback to get current control thresholds for BLE
    
    Returns the currently applied control thresholds, which match the current stage's
    thresholds that were loaded into the control system.
    """
    # Get current stage thresholds from database
    current_thresholds = stage_manager.get_current_thresholds()
    
    if not current_thresholds:
        # Return safe defaults if no stage configured
        logger.warning("No current thresholds available, returning defaults")
        return {
            'temp_min': 20.0,
            'temp_max': 26.0,
            'rh_min': 60.0,
            'co2_max': 1000,
            'light': {'mode': 'off', 'on_min': 0, 'off_min': 0}
        }
    
    # Return thresholds in the format expected by control_targets characteristic
    result = {}
    
    # Temperature thresholds
    if 'temp_min' in current_thresholds:
        result['temp_min'] = current_thresholds['temp_min']
    if 'temp_max' in current_thresholds:
        result['temp_max'] = current_thresholds['temp_max']
    
    # Humidity threshold
    if 'rh_min' in current_thresholds:
        result['rh_min'] = current_thresholds['rh_min']
    
    # CO2 threshold
    if 'co2_max' in current_thresholds:
        result['co2_max'] = current_thresholds['co2_max']
    
    # Light schedule
    light_schedule = control_system.get_status().get('light_schedule', {})
    result['light'] = {
        'mode': light_schedule.get('mode', 'off'),
        'on_min': light_schedule.get('on_minutes', 0),
        'off_min': light_schedule.get('off_minutes', 0)
    }
    
    return result


def set_control_targets(targets: dict):
    """Callback to set control targets from BLE
    
    Updates current stage's thresholds in database and reloads control system.
    This allows real-time threshold adjustments via the Flutter app's control page.
    
    Args:
        targets: Dict with threshold values (temp_min, temp_max, rh_min, co2_max, light)
    """
    try:
        logger.info(f"🎯 BLE control targets received: {targets}")
        
        # Validate input
        if not isinstance(targets, dict):
            logger.error(f"Invalid control targets data type: {type(targets)}")
            return
        
        # Get current stage info
        current_stage = stage_manager.get_current_stage()
        if not current_stage:
            logger.error("Cannot update targets: No current stage configured")
            return
        # Update current stage's thresholds in database
        success = stage_manager.update_current_stage_thresholds(targets)
        
        if success:
            # Reload thresholds from database
            updated_thresholds = stage_manager.get_current_thresholds()
            
            # Convert to Threshold objects for ControlSystem
            threshold_objects = convert_stage_thresholds_to_threshold_objects(updated_thresholds)
            
            # Update control system with new thresholds
            control_system.update_thresholds(threshold_objects)
            
            # Update light schedule if provided
            if 'light' in targets and isinstance(targets['light'], dict):
                light_config = targets['light']
                control_system.update_light_schedule(
                    mode=light_config.get('mode', 'off'),
                    on_minutes=light_config.get('on_min', 0),
                    off_minutes=light_config.get('off_min', 0)
                )
            
            # Log success with specific values
            log_parts = []
            if 'temp_min' in targets or 'temp_max' in targets:
                temp_str = f"T={targets.get('temp_min', '?')}-{targets.get('temp_max', '?')}°C"
                log_parts.append(temp_str)
            if 'rh_min' in targets:
                log_parts.append(f"RH≥{targets['rh_min']}%")
            if 'co2_max' in targets:
                log_parts.append(f"CO2≤{targets['co2_max']}ppm")
            if 'light' in targets:
                light_mode = targets['light'].get('mode', 'off') if isinstance(targets['light'], dict) else 'unknown'
                log_parts.append(f"Light={light_mode}")
            
            logger.info(f"✅ Updated {current_stage.species}-{current_stage.stage} thresholds: {', '.join(log_parts)}")
            logger.info(f"♻️  Control system reloaded with {len(threshold_objects)} threshold controllers")
        else:
            logger.error("Failed to update stage thresholds in database")
            
    except Exception as e:
        logger.error(f"Error updating control targets: {e}", exc_info=True)


def get_stage_data():
    """Callback to get current stage data for BLE"""
    status = stage_manager.get_status()
    if status.get('configured', False):
        # Map species names to IDs
        species_map = {'Oyster': 1, 'Shiitake': 2, 'Lion\'s Mane': 3}
        species_id = species_map.get(status.get('species', 'Oyster'), 0)
        
        # Map stage names to IDs
        stage_map = {'Incubation': 1, 'Pinning': 2, 'Fruiting': 3, 'Harvest': 4}
        stage_id = stage_map.get(status.get('stage', 'Incubation'), 0)
        
        # Map mode strings to IDs (0=FULL, 1=SEMI, 2=MANUAL)
        mode_map = {'full': 0, 'semi': 1, 'manual': 2}
        mode_str = status.get('mode', 'semi')
        mode_id = mode_map.get(mode_str, 1)  # Default to SEMI (1)
        logger.info(f"🔍 MODE DEBUG: mode_str='{mode_str}' → mode_id={mode_id} (0=FULL, 1=SEMI, 2=MANUAL)")
        
        # Convert ISO format start_time to Unix timestamp
        stage_start_ts = 0
        if 'start_time' in status:
            try:
                from datetime import datetime
                start_dt = datetime.fromisoformat(status['start_time'])
                stage_start_ts = int(start_dt.timestamp())
                logger.debug(f"Converted start_time '{status['start_time']}' to timestamp {stage_start_ts}")
            except (ValueError, TypeError) as e:
                logger.warning(f"Could not parse start_time '{status.get('start_time')}': {e}")
        else:
            logger.warning("No start_time in status")
        
        return {
            'species': status.get('species', 'Unknown'),
            'species_id': species_id,
            'stage': status.get('stage', 'Init'),
            'stage_id': stage_id,
            'mode': mode_id,  # Now returns numeric ID instead of string
            'age_days': status.get('age_days', 0),
            'stage_start_ts': stage_start_ts,
            'expected_days': status.get('expected_days', 0)
        }
    return None


def get_stage_thresholds_for_ble(species: str, stage: str) -> dict:
    """Callback to get thresholds for any species/stage (for Stage page in Flutter)
    
    Provides backward compatibility by falling back to thresholds.json if database is empty.
    Returns start_time from the database if available.
    """
    try:
        logger.info(f"📖 BLE requesting thresholds for: {species} - {stage}")
        
        # Validate input
        if not isinstance(species, str) or not isinstance(stage, str):
            logger.error(f"Invalid species or stage type: species={type(species)}, stage={type(stage)}")
            return {}
        
        # Try database first (includes start_time from database)
        thresholds = stage_manager.get_stage_thresholds(species, stage)
        
        if thresholds:
            logger.debug(f"✅ Returning thresholds from database for {species} - {stage}")
            return thresholds
        
        # Fallback: Try reading from thresholds.json directly
        logger.warning(f"⚠️ No database thresholds found for {species} - {stage}, trying thresholds.json fallback")
        
        try:
            thresholds_path = config.thresholds_path
            if thresholds_path.exists():
                with open(thresholds_path, 'r') as f:
                    thresholds_data = json.load(f)
                
                # Navigate to the correct species and stage
                # Support both flat format: {"Oyster": {"Incubation": {...}}}
                # and nested format: {"species": {"Oyster": {"stages": {"Incubation": {...}}}}}
                species_data = thresholds_data.get(species)
                if not species_data:
                    # Try nested format
                    species_data = thresholds_data.get('species', {}).get(species, {})
                
                if species_data:
                    # Try direct stage access (flat format)
                    stage_data = species_data.get(stage)
                    if not stage_data:
                        # Try nested format with 'stages' key
                        stage_data = species_data.get('stages', {}).get(stage, {})
                    
                    if stage_data:
                        logger.info(f"✅ Returning thresholds from thresholds.json for {species} - {stage}")
                        
                        # Format to match expected structure (with light as nested dict)
                        result = {}
                        
                        # Copy threshold values
                        if 'temp_min' in stage_data:
                            result['temp_min'] = stage_data['temp_min']
                        if 'temp_max' in stage_data:
                            result['temp_max'] = stage_data['temp_max']
                        if 'rh_min' in stage_data:
                            result['rh_min'] = stage_data['rh_min']
                        if 'rh_max' in stage_data:
                            result['rh_max'] = stage_data['rh_max']
                        if 'co2_max' in stage_data:
                            result['co2_max'] = stage_data['co2_max']
                        if 'expected_days' in stage_data:
                            result['expected_days'] = stage_data['expected_days']
                        
                        # Handle light settings
                        if 'light' in stage_data:
                            result['light'] = stage_data['light']
                        else:
                            # Default light settings if not present
                            result['light'] = {
                                'mode': 'off',
                                'on_min': 0,
                                'off_min': 0
                            }
                        
                        return result
                    else:
                        logger.error(f"❌ Stage {stage} not found for species {species} in thresholds.json")
                else:
                    logger.error(f"❌ Species {species} not found in thresholds.json")
            else:
                logger.error(f"❌ thresholds.json not found at {thresholds_path}")
        except Exception as e:
            logger.error(f"❌ Error reading thresholds.json: {e}", exc_info=True)
        
        # Return empty dict if all fallbacks fail
        return {}
    except Exception as e:
        logger.error(f"Error getting stage thresholds from BLE: {e}", exc_info=True)
        return {}


def set_stage_thresholds_from_ble(species: str, stage: str, thresholds: dict) -> bool:
    """Callback to set thresholds for any species/stage (for Stage page in Flutter)"""
    try:
        logger.info(f"✏️  BLE updating thresholds for: {species} - {stage}")
        
        # Validate input
        if not isinstance(species, str) or not isinstance(stage, str):
            logger.error(f"Invalid species or stage type: species={type(species)}, stage={type(stage)}")
            return False
        
        if not isinstance(thresholds, dict):
            logger.error(f"Invalid thresholds data type: {type(thresholds)}")
            return False
        
        # Check if this is the current active stage
        current_stage = stage_manager.get_current_stage()
        is_current_stage = current_stage and current_stage.species == species and current_stage.stage == stage
        
        # If start_time is not provided in thresholds, preserve existing start_time from database
        if 'start_time' not in thresholds or thresholds.get('start_time') is None:
            existing_thresholds = stage_manager.get_stage_thresholds(species, stage)
            if existing_thresholds and 'start_time' in existing_thresholds:
                thresholds['start_time'] = existing_thresholds['start_time']
                logger.info(f"Preserving existing start_time: {thresholds['start_time']}")
        else:
            logger.info(f"Using start_time from BLE: {thresholds['start_time']}")
        
        # Preserve expected_days from existing thresholds if not provided by BLE
        if 'expected_days' not in thresholds or thresholds.get('expected_days', 0) == 0:
            existing_thresholds = stage_manager.get_stage_thresholds(species, stage)
            if existing_thresholds and existing_thresholds.get('expected_days', 0) > 0:
                thresholds['expected_days'] = existing_thresholds['expected_days']
                logger.info(f"📅 Preserving expected_days={thresholds['expected_days']} for {species} - {stage}")
            else:
                # Fall back to thresholds.json to get expected_days
                try:
                    thresholds_path = config.thresholds_path
                    if thresholds_path.exists():
                        with open(thresholds_path, 'r') as f:
                            thresholds_data = json.load(f)
                        species_data = thresholds_data.get(species, {})
                        stage_data = species_data.get(stage, {})
                        json_expected_days = stage_data.get('expected_days', 0)
                        if json_expected_days > 0:
                            thresholds['expected_days'] = json_expected_days
                            logger.info(f"📅 Using expected_days={json_expected_days} from thresholds.json for {species} - {stage}")
                except Exception as e:
                    logger.warning(f"Could not read expected_days from thresholds.json: {e}")
        
        success = stage_manager.update_stage_thresholds(species, stage, thresholds)
        
        if success:
            # If this is the current stage, also reload control system
            if is_current_stage:
                logger.info(f"♻️  Reloading control system (current stage updated)")
                threshold_objects = convert_stage_thresholds_to_threshold_objects(thresholds)
                control_system.update_thresholds(threshold_objects)
                
                # Update light schedule if provided
                if 'light' in thresholds:
                    light_config = thresholds['light']
                    if isinstance(light_config, dict):
                        control_system.update_light_schedule(
                            mode=light_config.get('mode', 'off'),
                            on_minutes=light_config.get('on_min', 0),
                            off_minutes=light_config.get('off_min', 0)
                        )
        
        return success
    except Exception as e:
        logger.error(f"Error setting stage thresholds from BLE: {e}", exc_info=True)
        return False


def set_stage_state(stage_data: dict):
    """Callback to set stage state from BLE"""
    try:
        logger.info(f"BLE stage state received: {stage_data}")
        
        # Validate input
        if not isinstance(stage_data, dict):
            logger.error(f"Invalid stage state data type: {type(stage_data)}")
            return
        
        # Extract data from BLE packet
        species = stage_data.get('species', 'Oyster')
        stage = stage_data.get('stage', 'Pinning')
        
        # Validate species and stage
        if not isinstance(species, str) or not isinstance(stage, str):
            logger.error(f"Invalid species or stage type: species={type(species)}, stage={type(stage)}")
            return
        
        # Extract mode if provided (0=FULL, 1=SEMI, 2=MANUAL)
        mode_id = stage_data.get('mode')
        mode = None
        if mode_id is not None:
            try:
                from app.core.stage import StageMode
                mode_map = {0: StageMode.FULL, 1: StageMode.SEMI, 2: StageMode.MANUAL}
                mode = mode_map.get(mode_id)
                if mode is None:
                    logger.warning(f"Invalid mode ID: {mode_id}, using default")
            except Exception as e:
                logger.error(f"Error parsing stage mode: {e}")
        
        # Extract start_time if provided (Unix timestamp)
        start_time = None
        stage_start_ts = stage_data.get('stage_start_ts', 0)
        if stage_start_ts and stage_start_ts > 0:
            try:
                from datetime import datetime
                start_time = datetime.fromtimestamp(stage_start_ts)
                logger.info(f"Using BLE-provided start_time: {start_time.isoformat()}")
            except (ValueError, OSError) as e:
                logger.error(f"Invalid start_time timestamp: {stage_start_ts}, error: {e}")
        
        # Update stage manager with all parameters
        success = stage_manager.set_stage(species, stage, mode=mode, start_time=start_time)
        
        if success:
            logger.info(f"Stage updated via BLE: {species}-{stage}")
            
            # CRITICAL: Map StageMode to ControlMode and update control system
            try:
                from app.core.control import ControlMode
                from app.core.stage import StageMode
                
                current_stage = stage_manager.get_current_stage()
                if current_stage:
                    stage_mode = current_stage.mode
                    
                    # Map StageMode to ControlMode
                    # FULL and SEMI both use automatic control (only difference is stage advancement)
                    # MANUAL disables automatic control
                    if stage_mode == StageMode.MANUAL:
                        control_mode = ControlMode.MANUAL
                    else:  # FULL or SEMI
                        control_mode = ControlMode.AUTOMATIC
                    
                    # Update control system mode
                    control_system.set_mode(control_mode)
                    logger.info(f"Control mode updated: {stage_mode.value} → {control_mode.value}")
                else:
                    logger.warning("Could not get current stage after update - cannot set control mode")
            except Exception as e:
                logger.error(f"Error mapping stage mode to control mode: {e}", exc_info=True)
            
            # Update light schedule based on new stage
            light_schedule = stage_manager.get_light_schedule()
            if light_schedule:
                light_mode = light_schedule.get('mode', 'off')
                on_minutes = light_schedule.get('on_minutes', 0)
                off_minutes = light_schedule.get('off_minutes', 0)
                control_system.update_light_schedule(light_mode, on_minutes, off_minutes)
                logger.info(f"Light schedule updated: {light_mode}")
            
            # CRITICAL: Update control system thresholds with new stage thresholds
            current_thresholds = stage_manager.get_current_thresholds()
            if current_thresholds:
                threshold_objects = convert_stage_thresholds_to_threshold_objects(current_thresholds)
                control_system.update_thresholds(threshold_objects)
                logger.info(f"Control system thresholds updated: {len(threshold_objects)} parameters")
            else:
                logger.warning("No thresholds found for new stage")
        else:
            logger.warning(f"Failed to update stage via BLE: {species}-{stage}")
    except Exception as e:
        logger.error(f"Error setting stage state from BLE: {e}", exc_info=True)


def apply_overrides(overrides: dict):
    """Callback to apply manual overrides from BLE
    
    Args:
        overrides: Dictionary with override settings from DataConverter.override_bits_to_dict():
            {
                'light_override': bool,
                'fan_override': bool,
                'mist_override': bool,
                'heater_override': bool,
                'disable_automation': bool,
                'emergency_stop': bool,
                'raw_bits': int
            }
    """
    try:
        logger.info(f"🎛️  BLE overrides received: {overrides}")
        
        # Validate input
        if not isinstance(overrides, dict):
            logger.error(f"Invalid overrides data type: {type(overrides)}")
            return
        from app.core.control import ControlMode
        
        # Map override flags to relay names
        relay_mapping = {
            'light_override': 'grow_light',
            'fan_override': 'exhaust_fan',
            'mist_override': 'humidifier',
            'heater_override': 'heater'
        }
        
        # Process each relay override
        for override_key, relay_name in relay_mapping.items():
            is_overridden = overrides.get(override_key, False)
            
            if is_overridden:
                # Enable manual override for this relay
                # When override is enabled, we maintain the current state
                # (The Flutter app can send separate commands to change state if needed)
                control_system.set_manual_override(relay_name, True, state=None)
                logger.info(f"✅ Manual override enabled for {relay_name}")
            else:
                # Clear manual override - return to automatic control
                control_system.set_manual_override(relay_name, False)
                logger.debug(f"Manual override cleared for {relay_name}")
        
        # Handle EMERGENCY_STOP bit (bit15) - highest priority
        emergency_stop = overrides.get('emergency_stop', False)
        if emergency_stop:
            # Set control system to SAFETY mode (emergency stop)
            control_system.set_mode(ControlMode.SAFETY)
            logger.warning("🚨 EMERGENCY STOP ACTIVATED - All relays OFF, automatic control disabled")
            # Emergency stop turns off all relays immediately (handled in set_mode)
            return  # Don't process other overrides during emergency stop
        
        # Handle DISABLE_AUTOMATION bit (bit7)
        disable_automation = overrides.get('disable_automation', False)
        if disable_automation:
            # Set control system to MANUAL mode (disables all automatic control)
            control_system.set_mode(ControlMode.MANUAL)
            logger.info("🔒 Automation disabled - system in MANUAL mode")
        else:
            # Return to AUTOMATIC mode if automation is re-enabled
            # Only switch back if no individual overrides are active
            has_any_override = any([
                overrides.get('light_override', False),
                overrides.get('fan_override', False),
                overrides.get('mist_override', False),
                overrides.get('heater_override', False)
            ])
            
            # If we're in SAFETY mode and emergency stop is cleared, return to previous mode
            if control_system.mode == ControlMode.SAFETY:
                if not has_any_override:
                    control_system.set_mode(ControlMode.AUTOMATIC)
                    logger.info("🔄 Emergency stop cleared - system returning to AUTOMATIC mode")
                else:
                    control_system.set_mode(ControlMode.MANUAL)
                    logger.info("🔄 Emergency stop cleared but overrides active - system in MANUAL mode")
            elif not has_any_override and control_system.mode == ControlMode.MANUAL:
                # Only return to automatic if no overrides are active
                control_system.set_mode(ControlMode.AUTOMATIC)
                logger.info("🔄 Automation re-enabled - system in AUTOMATIC mode")
            elif has_any_override:
                # Individual overrides are active, but automation bit is cleared
                # Keep in MANUAL mode since individual overrides take precedence
                logger.debug("Individual overrides active - keeping MANUAL mode")
        
        # Notify BLE clients of actuator status change
        try:
            ble_gatt.notify_actuator_status()
        except Exception as e:
            logger.debug(f"Actuator status notify failed: {e}")
            
    except Exception as e:
        logger.error(f"Error applying overrides: {e}", exc_info=True)


def loop():
    """Main control loop"""
    # Register BLE callbacks before starting service
    ble_gatt.set_callbacks(
        get_sensor_data=get_sensor_data,
        get_control_data=get_control_data,
        get_control_targets=get_control_targets,
        set_control_targets=set_control_targets,
        get_stage_data=get_stage_data,
        set_stage_state=set_stage_state,
        apply_overrides=apply_overrides,
        get_stage_thresholds=get_stage_thresholds_for_ble,
        set_stage_thresholds=set_stage_thresholds_from_ble
    )
    logger.info("BLE callbacks registered")
    
    # Start BLE GATT service
    if ble_gatt.start_ble_service():
        logger.info("BLE GATT service started")
    else:
        logger.warning("BLE GATT service failed to start (continuing without BLE)")
    
    # CRITICAL: Initialize control system with current stage thresholds and mode
    logger.info("Initializing control system with stage thresholds...")
    stage_info = stage_manager.get_current_stage()
    if stage_info:
        logger.info(f"Current stage: {stage_info.species} - {stage_info.stage} (mode: {stage_info.mode.value})")
        
        # CRITICAL: Load and apply control mode from database or stage manager
        try:
            from app.core.control import ControlMode
            from app.core.stage import StageMode
            
            # Try to load persisted control mode from database first
            stage_data = db.get_current_stage()
            persisted_control_mode = None
            if stage_data and stage_data.get('control_mode'):
                try:
                    persisted_control_mode = ControlMode(stage_data['control_mode'])
                    logger.info(f"📦 Loaded persisted control mode from database: {persisted_control_mode.value}")
                except (ValueError, KeyError):
                    logger.debug("No valid persisted control mode in database")
            
            # If no persisted mode, derive from stage mode
            if persisted_control_mode is None:
                stage_mode = stage_info.mode
                
                # Map StageMode to ControlMode
                # FULL and SEMI both use automatic control (only difference is stage advancement)
                # MANUAL disables automatic control
                if stage_mode == StageMode.MANUAL:
                    control_mode = ControlMode.MANUAL
                else:  # FULL or SEMI
                    control_mode = ControlMode.AUTOMATIC
                
                logger.info(f"📊 Derived control mode from stage mode: {stage_mode.value} → {control_mode.value}")
            else:
                control_mode = persisted_control_mode
            
            # Apply control mode to control system (will persist to database)
            control_system.set_mode(control_mode)
            logger.info(f"✅ Control mode initialized: {control_mode.value}")
        except Exception as e:
            logger.error(f"Error loading control mode: {e}", exc_info=True)
            logger.warning("Defaulting to AUTOMATIC mode")
            control_system.set_mode(ControlMode.AUTOMATIC)
        
        # Get thresholds for current stage
        current_thresholds = stage_manager.get_current_thresholds()
        if current_thresholds:
            # Convert to Threshold objects and update control system
            threshold_objects = convert_stage_thresholds_to_threshold_objects(current_thresholds)
            control_system.update_thresholds(threshold_objects)
            logger.info(f"✅ Control system initialized with {len(threshold_objects)} thresholds")
            
            # Log the thresholds being used
            for param, threshold in threshold_objects.items():
                if threshold.min_value is not None and threshold.max_value is not None:
                    logger.info(f"  {param}: {threshold.min_value} - {threshold.max_value}")
                elif threshold.min_value is not None:
                    logger.info(f"  {param}: min {threshold.min_value}")
                elif threshold.max_value is not None:
                    logger.info(f"  {param}: max {threshold.max_value}")
        else:
            logger.warning("⚠️  No thresholds found for current stage - control system will not act")
        
        # Initialize light schedule
        light_schedule = stage_manager.get_light_schedule()
        if light_schedule:
            mode = light_schedule.get('mode', 'off')
            on_minutes = light_schedule.get('on_minutes', 0)
            off_minutes = light_schedule.get('off_minutes', 0)
            control_system.update_light_schedule(mode, on_minutes, off_minutes)
            logger.info(f"Light schedule initialized: {mode}")
    else:
        logger.warning("⚠️  No stage configuration found - using default control settings")
    
    # Start sensor monitoring
    sensors.start_sensor_monitoring()
    logger.info("Sensor monitoring started")
    
    try:
        while True:
            # Get current sensor readings
            reading = sensors.get_current_readings()
            
            if reading:
                # Log current stage and automation mode
                current_stage_info = stage_manager.get_current_stage()
                if current_stage_info:
                    age_days = stage_manager.get_stage_age_days()
                    logger.info(f"📊 Stage: {current_stage_info.species}-{current_stage_info.stage} | "
                              f"Mode: {current_stage_info.mode.value.upper()} | "
                              f"Age: {age_days:.1f} days")
                else:
                    logger.info("📊 Stage: Not configured")
                
                logger.info(f"Sensors - Temp: {reading.temperature_c}°C, "
                          f"RH: {reading.humidity_percent}%, "
                          f"CO2: {reading.co2_ppm}ppm, "
                          f"Light: {reading.light_level}")
                
                # Record compliance for stage advancement checking
                if stage_manager.current_stage:
                    current_thresholds = stage_manager.get_current_thresholds()
                    if current_thresholds:
                        stage_manager.record_compliance(reading, current_thresholds)
                
                # Process sensor reading and update control system
                actions = control_system.process_reading(reading)
                if actions:
                    logger.info(f"🎛️  Control actions taken: {len(actions)} relays updated")
                    for action_name, action in actions.items():
                        logger.info(f"  {action.relay}: {action.state.name} ({action.reason})")
                    # Push actuator status update to BLE when relays change
                    try:
                        ble_gatt.notify_actuator_status()
                    except Exception as e:
                        logger.debug(f"Actuator status notify failed: {e}")
                else:
                    logger.debug("No control actions needed")
                
                # Get control system status
                status = control_system.get_status()
                logger.debug(f"Control status: mode={status['mode']}, "
                           f"controllers={status['controllers_active']}, "
                           f"condensation_guard={status['condensation_guard_active']}")
                
                # Check for automatic stage progression (FULL mode only)
                current_stage_info = stage_manager.get_current_stage()
                if current_stage_info and current_stage_info.mode == StageMode.FULL:
                    should_advance, reason = stage_manager.should_advance_stage()
                    if should_advance:
                        logger.info(f"🔄 Auto-advancing stage: {reason}")
                        success = stage_manager.advance_stage()
                        if success:
                            logger.info(f"✅ Advanced to next stage")
                            # Update control system with new stage thresholds
                            new_thresholds = stage_manager.get_current_thresholds()
                            if new_thresholds:
                                threshold_objects = convert_stage_thresholds_to_threshold_objects(new_thresholds)
                                control_system.update_thresholds(threshold_objects)
                                logger.info(f"🎯 Control thresholds updated for new stage")
                            # Update light schedule
                            light_schedule = stage_manager.get_light_schedule()
                            if light_schedule:
                                control_system.update_light_schedule(
                                    light_schedule.get('mode', 'off'),
                                    light_schedule.get('on_minutes', 0),
                                    light_schedule.get('off_minutes', 0)
                                )
                        else:
                            logger.warning(f"❌ Failed to advance stage")
                
                # Log BLE connection status
                connection_count = ble_gatt.get_connection_count()
                if connection_count > 0:
                    logger.info(f"🔗 BLE Status: {connection_count} device(s) connected")
                else:
                    logger.debug("🔗 BLE Status: No devices connected")
                
                # Update BLE with current environmental data
                try:
                    ble_gatt.notify_env_packet(
                        reading.temperature_c or 0.0,
                        reading.humidity_percent or 0.0,
                        reading.co2_ppm or 0,
                        reading.light_level or 0.0
                    )
                except Exception as e:
                    logger.warning(f"BLE notification failed: {e}")
            else:
                logger.warning("No sensor readings available")
            
            # Sleep for monitor interval (configurable via MUSHPI_MONITOR_INTERVAL env var)
            monitor_interval = config.timing.monitor_interval
            # Validate interval is reasonable (5-300 seconds)
            if monitor_interval < 5:
                logger.warning(f"Monitor interval {monitor_interval}s is too short, using minimum 5s")
                monitor_interval = 5
            elif monitor_interval > 300:
                logger.warning(f"Monitor interval {monitor_interval}s is too long, using maximum 300s")
                monitor_interval = 300
            time.sleep(monitor_interval)
            
    except KeyboardInterrupt:
        logger.info("Shutdown requested")
    finally:
        # Cleanup
        ble_gatt.stop_ble_service()
        sensors.stop_sensor_monitoring()
        control_system.cleanup()
        logger.info("Shutdown complete")


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    logger.info("MushPi starting...")
    try:
        loop()
    except KeyboardInterrupt:
        logger.info("MushPi stopped by user")
    except Exception as e:
        logger.error(f"MushPi crashed: {e}", exc_info=True)
        raise
