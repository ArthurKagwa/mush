"""
MushPi DHT22 Sensor

DHT22 Temperature and Humidity Sensor (GPIO) - Backup sensor implementation.
"""

import time
import logging
from typing import Optional, Tuple

from .base import BaseSensor, DHT22Error
from ..core.config import config

try:
    import board
    import adafruit_dht
    GPIO_AVAILABLE = True
except ImportError:
    logging.warning("GPIO libraries not available - running in simulation mode")
    GPIO_AVAILABLE = False

# Logging Setup
logger = logging.getLogger(__name__)


class DHT22Sensor(BaseSensor):
    """DHT22 Temperature and Humidity Sensor (GPIO) - Backup sensor"""
    
    def __init__(self, pin: Optional[int] = None):
        super().__init__("DHT22")
        self.pin = pin or config.gpio.dht22_pin
        self.reading_interval = config.timing.dht22_interval
        self._initialize_sensor()
        
    def _initialize_sensor(self) -> bool:
        """Initialize DHT22 sensor"""
        if not GPIO_AVAILABLE:
            logger.warning("DHT22: GPIO not available, using simulation mode")
            return False
            
        try:
            self.sensor = adafruit_dht.DHT22(getattr(board, f'D{self.pin}'))
            logger.info(f"DHT22 sensor initialized on pin {self.pin}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize DHT22 sensor: {e}")
            raise DHT22Error(f"DHT22 initialization failed: {e}")
            
    def read_sensor(self, max_retries: int = 5) -> Optional[Tuple[float, float]]:
        """Read temperature and humidity from DHT22
        
        Returns:
            Tuple of (temperature_c, humidity_percent) or None if failed
        """
        if not self.sensor:
            # Simulation mode
            import random
            return (
                random.uniform(18.0, 25.0),  # Temperature C
                random.uniform(75.0, 95.0)   # Humidity %
            )
            
        # Check timing interval
        current_time = time.time()
        if current_time - self.last_reading_time < self.reading_interval:
            return None
            
        for attempt in range(max_retries):
            try:
                temp = self.sensor.temperature
                humidity = self.sensor.humidity
                
                if temp is not None and humidity is not None:
                    if self._validate_reading(temp, humidity):
                        self.last_reading_time = current_time
                        logger.debug(f"DHT22 reading: T={temp:.1f}°C, RH={humidity:.1f}%")
                        return (float(temp), float(humidity))
                    else:
                        logger.warning(f"DHT22 invalid reading: T={temp}, RH={humidity}")
                        
            except RuntimeError as e:
                # DHT22 commonly has timing issues
                logger.debug(f"DHT22 read attempt {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    time.sleep(0.5)
            except Exception as e:
                logger.error(f"DHT22 read attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(0.5)
                    
        raise DHT22Error("Failed to read DHT22 after multiple attempts")
        
    def _validate_reading(self, temp: float, humidity: float) -> bool:
        """Validate DHT22 readings"""
        return (
            -40 <= temp <= 80 and           # DHT22 temperature range
            0 <= humidity <= 100            # DHT22 humidity range
        )
    
    def cleanup(self) -> None:
        """Cleanup DHT22 sensor resources"""
        if self.sensor:
            try:
                self.sensor.exit()
                logger.debug("DHT22 sensor cleanup completed")
            except Exception as e:
                logger.warning(f"DHT22 cleanup error: {e}")
            finally:
                self.sensor = None