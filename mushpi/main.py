# main.py
from app.core import sensors, control, stage, ble_gatt
from app.core.control import ControlSystem
from app.core.stage import StageManager
from app.database.manager import DatabaseManager
from app.models.ble_dataclasses import StatusFlags
from app.core import ble_gatt as ble_api
import logging
import time

logger = logging.getLogger(__name__)

# Initialize main components
db = DatabaseManager()
control_system = ControlSystem()
stage_manager = StageManager()


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
    """Callback to get current control system data for BLE"""
    status = control_system.get_status()
    relay_states = status.get('relay_states', {})
    
    # Map relay states to boolean values for BLE
    return {
        'fan': relay_states.get('exhaust_fan', 'OFF') == 'ON',
        'mist': relay_states.get('humidifier', 'OFF') == 'ON',
        'light': relay_states.get('grow_light', 'OFF') == 'ON',
        'heater': relay_states.get('heater', 'OFF') == 'ON',
        'mode': status.get('mode', 'automatic')
    }


def set_control_targets(targets: dict):
    """Callback to set control targets from BLE"""
    logger.info(f"BLE control targets received: {targets}")
    # TODO: Implement control target updates
    # This would update thresholds in the control system


def get_stage_data():
    """Callback to get current stage data for BLE"""
    status = stage_manager.get_status()
    if status.get('configured', False):
        # Map species names to IDs (simplified - could use a proper mapping)
        species_map = {'Oyster': 1, 'Shiitake': 2, 'Lion\'s Mane': 3}
        species_id = species_map.get(status.get('species', 'Oyster'), 0)
        
        # Map stage names to IDs (simplified)
        stage_map = {'Incubation': 1, 'Pinning': 2, 'Fruiting': 3, 'Harvest': 4}
        stage_id = stage_map.get(status.get('stage', 'Incubation'), 0)
        
        return {
            'species': status.get('species', 'Unknown'),
            'species_id': species_id,
            'stage': status.get('stage', 'Init'),
            'stage_id': stage_id,
            'mode': status.get('mode', 'semi'),
            'age_days': status.get('age_days', 0)
        }
    return None


def set_stage_state(stage_data: dict):
    """Callback to set stage state from BLE"""
    logger.info(f"BLE stage state received: {stage_data}")
    
    # Extract species and stage from the data
    species = stage_data.get('species', 'Oyster')
    stage = stage_data.get('stage', 'Pinning')
    
    # Update stage manager
    success = stage_manager.set_stage(species, stage)
    
    if success:
        logger.info(f"Stage updated via BLE: {species}-{stage}")
        
        # Update light schedule based on new stage
        light_schedule = stage_manager.get_light_schedule()
        if light_schedule:
            mode = light_schedule.get('mode', 'off')
            on_minutes = light_schedule.get('on_minutes', 0)
            off_minutes = light_schedule.get('off_minutes', 0)
            control_system.update_light_schedule(mode, on_minutes, off_minutes)
            logger.info(f"Light schedule updated: {mode}")
    else:
        logger.warning(f"Failed to update stage via BLE: {species}-{stage}")


def apply_overrides(overrides: dict):
    """Callback to apply manual overrides from BLE"""
    logger.info(f"BLE overrides received: {overrides}")
    # TODO: Implement override handling
    # This would allow manual relay control via BLE


def loop():
    """Main control loop"""
    # Register BLE callbacks before starting service
    ble_gatt.set_callbacks(
        get_sensor_data=get_sensor_data,
        get_control_data=get_control_data,
        set_control_targets=set_control_targets,
        get_stage_data=get_stage_data,
        set_stage_state=set_stage_state,
        apply_overrides=apply_overrides
    )
    logger.info("BLE callbacks registered")
    
    # Start BLE GATT service
    if ble_gatt.start_ble_service():
        logger.info("BLE GATT service started")
    else:
        logger.warning("BLE GATT service failed to start (continuing without BLE)")
    
    # Start sensor monitoring
    sensors.start_sensor_monitoring()
    logger.info("Sensor monitoring started")
    
    try:
        while True:
            # Get current sensor readings
            reading = sensors.get_current_readings()
            
            if reading:
                logger.info(f"Sensors - Temp: {reading.temperature_c}°C, "
                          f"RH: {reading.humidity_percent}%, "
                          f"CO2: {reading.co2_ppm}ppm, "
                          f"Light: {reading.light_level}")
                
                # Process sensor reading and update control system
                actions = control_system.process_reading(reading)
                if actions:
                    logger.info(f"Control actions: {actions}")
                
                # Get control system status (includes relay states)
                status = control_system.get_status()
                relay_states = status.get('relay_states', {})
                logger.debug(f"Control status: {status}")

                # Build status flags including actuator live states
                try:
                    flags = StatusFlags(0)
                    # Preserve existing simulation flag
                    if control_system.simulation_mode:
                        flags |= StatusFlags.SIMULATION
                    # Sensor/control error indicators
                    if status.get('sensor_error'):
                        flags |= StatusFlags.SENSOR_ERROR
                    if status.get('control_error'):
                        flags |= StatusFlags.CONTROL_ERROR
                    # Threshold alarm
                    if status.get('threshold_alarm'):
                        flags |= StatusFlags.THRESHOLD_ALARM
                    # Stage readiness (placeholder - implement real check later)
                    if status.get('stage_ready'):
                        flags |= StatusFlags.STAGE_READY
                    # Actuator live states (Option A extension)
                    if relay_states.get('grow_light') == 'ON':
                        flags |= StatusFlags.LIGHT_ON
                    if relay_states.get('exhaust_fan') == 'ON' or relay_states.get('circulation_fan') == 'ON':
                        flags |= StatusFlags.FAN_ON
                    if relay_states.get('humidifier') == 'ON':
                        flags |= StatusFlags.MIST_ON
                    if relay_states.get('heater') == 'ON':
                        flags |= StatusFlags.HEATER_ON

                    # Push updated status flags (connectivity bit added inside characteristic)
                    ble_api.update_status_flags(flags)
                except Exception as e:
                    logger.debug(f"Could not update status flags: {e}")
                
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
            
            # Sleep for monitor interval
            time.sleep(30)  # 30 seconds between loops
            
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
