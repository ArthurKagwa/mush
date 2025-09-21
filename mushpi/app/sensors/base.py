"""
MushPi Base Sensor Classes

Base classes and error definitions for all sensor implementations.
"""

import logging
from abc import ABC, abstractmethod
from typing import Optional, Any

# Logging Setup
logger = logging.getLogger(__name__)


class SensorError(Exception):
    """Base sensor error"""
    pass


class SCD41Error(SensorError):
    """SCD41 sensor specific error"""
    pass


class DHT22Error(SensorError):
    """DHT22 sensor specific error"""  
    pass


class LightSensorError(SensorError):
    """Light sensor specific error"""
    pass


class BaseSensor(ABC):
    """Base class for all sensor implementations"""
    
    def __init__(self, sensor_name: str):
        self.sensor_name = sensor_name
        self.sensor = None
        self.last_reading_time = 0
        self.reading_interval = 1.0  # Default minimum interval
        
    @abstractmethod
    def _initialize_sensor(self) -> bool:
        """Initialize the specific sensor hardware"""
        pass
        
    @abstractmethod
    def read_sensor(self) -> Optional[Any]:
        """Read data from the sensor"""
        pass
        
    @abstractmethod
    def _validate_reading(self, *args) -> bool:
        """Validate sensor readings are within reasonable ranges"""
        pass
        
    def is_available(self) -> bool:
        """Check if sensor hardware is available"""
        return self.sensor is not None
        
    def get_sensor_info(self) -> dict:
        """Get sensor information"""
        return {
            'name': self.sensor_name,
            'available': self.is_available(),
            'last_reading_time': self.last_reading_time,
            'reading_interval': self.reading_interval
        }