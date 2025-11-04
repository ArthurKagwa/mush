"""
MushPi Light Sensor

ADS1115 + Photoresistor Light Level Sensor (I2C) implementation.
"""

import time
import math
import logging
from datetime import datetime
from typing import Optional

from .base import BaseSensor, LightSensorError
from ..core.config import config

try:
    import board
    import busio
    import adafruit_ads1x15.ads1115 as ADS
    from adafruit_ads1x15.analog_in import AnalogIn
    GPIO_AVAILABLE = True
except ImportError:
    logging.warning("GPIO libraries not available - running in simulation mode")
    GPIO_AVAILABLE = False

# Logging Setup
logger = logging.getLogger(__name__)


class LightSensor(BaseSensor):
    """ADS1115 + Photoresistor Light Level Sensor (I2C)"""
    
    def __init__(self, i2c_address: Optional[int] = None, channel: Optional[int] = None):
        super().__init__("ADS1115_Light")
        self.i2c_address = i2c_address or config.i2c.ads1115_address
        self.channel = channel or config.i2c.light_sensor_channel
        self.ads = None
        self.analog_in = None
        self.reading_interval = config.timing.light_interval
        self._initialize_sensor()
        
    def _initialize_sensor(self) -> bool:
        """Initialize ADS1115 ADC"""
        if not GPIO_AVAILABLE:
            logger.warning("LightSensor: GPIO not available, using simulation mode")
            return False
            
        try:
            i2c = busio.I2C(board.SCL, board.SDA)
            self.ads = ADS.ADS1115(i2c, address=self.i2c_address)
            # Use channel number directly (0-3 for A0-A3), not ADS.P0 attribute
            self.analog_in = AnalogIn(self.ads, self.channel)
            logger.info(f"ADS1115 light sensor initialized on channel {self.channel}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize ADS1115 light sensor: {e}")
            raise LightSensorError(f"ADS1115 initialization failed: {e}")
            
    def read_sensor(self) -> Optional[float]:
        """Read light level from photoresistor
        
        Returns:
            Light level (0-1000 arbitrary units) or None if failed
        """
        if not self.ads:
            # Simulation mode - simulate day/night cycle
            import random
            hour = datetime.now().hour
            if 6 <= hour <= 18:  # Daytime
                return random.uniform(300, 800)
            else:  # Nighttime
                return random.uniform(0, 50)
                
        # Check timing interval
        current_time = time.time()
        if current_time - self.last_reading_time < self.reading_interval:
            return None
            
        try:
            voltage = self.analog_in.voltage
            # Convert voltage to light level (0-1000 scale)
            # Assumes 10k photoresistor with 10k pullup
            light_level = self._voltage_to_light_level(voltage)
            
            self.last_reading_time = current_time
            logger.debug(f"Light sensor: {voltage:.2f}V -> {light_level:.1f} units")
            return light_level
            
        except Exception as e:
            logger.error(f"Failed to read light sensor: {e}")
            raise LightSensorError(f"Light sensor read failed: {e}")
            
    def _voltage_to_light_level(self, voltage: float) -> float:
        """Convert photoresistor voltage to light level scale
        
        Photoresistor in voltage divider: Vout = Vcc * R_photo / (R_fixed + R_photo)
        Higher light = lower resistance = higher voltage
        """
        vcc = config.calibration.light_vcc
        r_fixed = config.calibration.light_fixed_resistor
        
        if voltage <= 0.01:  # Avoid division by zero
            return 0.0
            
        # Calculate photoresistor resistance
        r_photo = r_fixed * voltage / (vcc - voltage)
        
        # Convert to light level (inverse relationship)
        # Higher resistance = darker = lower light level
        max_resistance = config.calibration.light_max_resistance
        min_resistance = config.calibration.light_min_resistance
        
        if r_photo > max_resistance:  # Very dark
            light_level = 0
        elif r_photo < min_resistance:  # Very bright
            light_level = 1000
        else:
            # Logarithmic scale mapping
            light_level = 1000 * (1 - math.log10(r_photo / min_resistance) / math.log10(max_resistance / min_resistance))
            
        return max(0, min(1000, light_level))
        
    def _validate_reading(self, light_level: float) -> bool:
        """Validate light level reading"""
        return 0 <= light_level <= 1000