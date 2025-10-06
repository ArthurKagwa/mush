"""
MushPi Sensor Management Module

Modularized sensor system with individual components for better maintainability.
This file maintains backward compatibility by re-exporting all components.
"""

import logging
from typing import Optional, Dict, Any

# Import all modular components
from ..models.dataclasses import SensorReading, Threshold, ThresholdEvent
from ..database.manager import DatabaseManager
from ..managers.threshold_manager import ThresholdManager
from ..managers.sensor_manager import SensorManager
from ..sensors.base import SensorError, SCD41Error, DHT22Error, LightSensorError
from ..sensors.scd41 import SCD41Sensor
from ..sensors.dht22 import DHT22Sensor
from ..sensors.light_sensor import LightSensor
from .config import config

# Hardware Configuration Constants (maintained for compatibility - now from config)
DHT22_PIN = config.gpio.dht22_pin
RELAY_PINS = config.gpio.get_relay_pins()

# I2C Addresses (maintained for compatibility - now from config)
SCD41_ADDRESS = config.i2c.scd41_address
ADS1115_ADDRESS = config.i2c.ads1115_address

# Logging Setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize managers and main sensor system
db_manager = DatabaseManager()
threshold_manager = ThresholdManager(db_manager=db_manager)
sensor_manager = SensorManager(db_manager=db_manager, threshold_manager=threshold_manager)

# Public API functions for external use (maintaining backward compatibility)
def get_current_readings() -> Optional[SensorReading]:
    """Public API: Get current sensor readings"""
    return sensor_manager.get_current_reading()

def start_sensor_monitoring() -> None:
    """Public API: Start sensor monitoring"""
    sensor_manager.start_monitoring()

def stop_sensor_monitoring() -> None:
    """Public API: Stop sensor monitoring"""
    sensor_manager.stop_monitoring()

def get_sensor_status() -> Dict[str, Any]:
    """Public API: Get sensor system status"""
    return sensor_manager.get_sensor_status()

def update_thresholds(**kwargs) -> None:
    """Public API: Update threshold values"""
    for param, values in kwargs.items():
        if isinstance(values, dict):
            threshold_manager.update_threshold(param, **values)

def shutdown_sensors() -> None:
    """Public API: Shutdown sensor system"""
    sensor_manager.shutdown()

# Export all classes and functions for backward compatibility
__all__ = [
    # Data models
    'SensorReading', 'Threshold', 'ThresholdEvent',
    # Managers
    'DatabaseManager', 'ThresholdManager', 'SensorManager',
    # Sensors
    'SCD41Sensor', 'DHT22Sensor', 'LightSensor',
    # Errors
    'SensorError', 'SCD41Error', 'DHT22Error', 'LightSensorError',
    # Constants
    'DHT22_PIN', 'RELAY_PINS', 'SCD41_ADDRESS', 'ADS1115_ADDRESS',
    # Public API
    'get_current_readings', 'start_sensor_monitoring', 'stop_sensor_monitoring',
    'get_sensor_status', 'update_thresholds', 'shutdown_sensors',
    # Instances
    'db_manager', 'threshold_manager', 'sensor_manager'
]
