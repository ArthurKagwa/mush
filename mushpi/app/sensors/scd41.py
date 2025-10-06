"""
MushPi SCD41 Sensor

SCD41 CO2, Temperature, and Humidity Sensor (I2C) implementation.
"""

import time
import logging
from typing import Optional, Tuple

from .base import BaseSensor, SCD41Error
from ..core.config import config

try:
    import board
    import busio
    import adafruit_scd4x
    GPIO_AVAILABLE = True
except ImportError:
    logging.warning("GPIO libraries not available - running in simulation mode")
    GPIO_AVAILABLE = False

# Logging Setup
logger = logging.getLogger(__name__)


class SCD41Sensor(BaseSensor):
    """SCD41 CO2, Temperature, and Humidity Sensor (I2C)"""
    
    def __init__(self, i2c_address: Optional[int] = None):
        super().__init__("SCD41")
        self.i2c_address = i2c_address or config.i2c.scd41_address
        self.reading_interval = config.timing.scd41_interval
        self._initialize_sensor()
        
    def _initialize_sensor(self) -> bool:
        """Initialize SCD41 sensor via I2C"""
        if not GPIO_AVAILABLE:
            logger.warning("SCD41: GPIO not available, using simulation mode")
            return False
            
        try:
            i2c = busio.I2C(board.SCL, board.SDA)
            self.sensor = adafruit_scd4x.SCD4X(i2c)
            
            # Start periodic measurements
            self.sensor.start_periodic_measurement()
            logger.info("SCD41 sensor initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize SCD41 sensor: {e}")
            raise SCD41Error(f"SCD41 initialization failed: {e}")
            
    def is_data_ready(self) -> bool:
        """Check if new data is available"""
        if not self.sensor:
            return False
            
        try:
            return self.sensor.data_ready
        except Exception as e:
            logger.error(f"SCD41 data ready check failed: {e}")
            return False
            
    def read_sensor(self, max_retries: int = 3) -> Optional[Tuple[int, float, float]]:
        """Read CO2, temperature, and humidity from SCD41
        
        Returns:
            Tuple of (co2_ppm, temperature_c, humidity_percent) or None if failed
        """
        if not self.sensor:
            # Simulation mode
            import random
            return (
                random.randint(400, 1200),  # CO2 ppm
                random.uniform(18.0, 25.0),  # Temperature C
                random.uniform(75.0, 95.0)   # Humidity %
            )
            
        # Check timing interval
        current_time = time.time()
        if current_time - self.last_reading_time < self.reading_interval:
            return None
            
        for attempt in range(max_retries):
            try:
                if not self.is_data_ready():
                    time.sleep(1)
                    continue
                    
                co2 = self.sensor.CO2
                temp = self.sensor.temperature
                humidity = self.sensor.relative_humidity
                
                # Validate readings
                if self._validate_reading(co2, temp, humidity):
                    self.last_reading_time = current_time
                    logger.debug(f"SCD41 reading: CO2={co2}ppm, T={temp:.1f}°C, RH={humidity:.1f}%")
                    return (int(co2), float(temp), float(humidity))
                else:
                    logger.warning(f"SCD41 invalid reading: CO2={co2}, T={temp}, RH={humidity}")
                    
            except Exception as e:
                logger.error(f"SCD41 read attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(1)
                    
        raise SCD41Error("Failed to read SCD41 after multiple attempts")
        
    def _validate_reading(self, co2: float, temp: float, humidity: float) -> bool:
        """Validate sensor readings are within reasonable ranges"""
        return (
            0 <= co2 <= 40000 and           # CO2 range
            -40 <= temp <= 70 and           # Temperature range  
            0 <= humidity <= 100             # Humidity range
        )
        
    def stop_measurement(self) -> None:
        """Stop periodic measurements (for shutdown)"""
        if self.sensor:
            try:
                self.sensor.stop_periodic_measurement()
                logger.info("SCD41 measurements stopped")
            except Exception as e:
                logger.error(f"Error stopping SCD41 measurements: {e}")