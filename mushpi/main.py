# main.py
from app.core import sensors, control, stage, ble_gatt
from app.core.control import ControlSystem
from app.core.stage import StageManager
from app.database.manager import DatabaseManager
import logging
import time

logger = logging.getLogger(__name__)

# Initialize main components
db = DatabaseManager()
control_system = ControlSystem()
stage_manager = StageManager()

def loop():
    """Main control loop"""
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
                
                # Get control system status
                status = control_system.get_status()
                logger.debug(f"Control status: {status}")
                
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
