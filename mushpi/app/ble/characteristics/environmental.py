"""
Environmental Measurements Characteristic

Handles environmental sensor data (CO₂, temperature, humidity, light, uptime).
Supports read and notify operations.
"""

import logging
from typing import Optional, Callable

from ..base import NotifyCharacteristic
from ...models.ble_dataclasses import ENV_MEASUREMENTS_UUID, EnvironmentalData
from ..serialization import EnvironmentalSerializer

logger = logging.getLogger(__name__)


class EnvironmentalMeasurementsCharacteristic(NotifyCharacteristic):
    """Environmental measurements characteristic (notify/read)"""
    
    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize environmental measurements characteristic
        
        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        # Data and callbacks must be set BEFORE calling super().__init__()
        # because base class will call _handle_read() during initialization
        self.env_data = EnvironmentalData.create_empty()
        self.get_sensor_data: Optional[Callable] = None
        
        super().__init__(ENV_MEASUREMENTS_UUID, service, simulation_mode)
        
    def _handle_read(self, options) -> bytes:
        """Read callback for environmental measurements
        
        Args:
            options: BLE read options
            
        Returns:
            Packed binary data (12 bytes)
        """
        try:
            # Update data from sensor system if callback available
            if self.get_sensor_data:
                sensor_data = self.get_sensor_data()
                if sensor_data:
                    self._update_from_sensor_data(sensor_data)
            
            # Pack and return data
            data = EnvironmentalSerializer.pack(self.env_data)
            
            logger.debug(f"BLE env read: CO2={self.env_data.co2_ppm}, "
                        f"T={self.env_data.temp_x10/10}°C")
            return data
            
        except Exception as e:
            logger.error(f"Error reading environmental measurements: {e}")
            return b'\x00' * EnvironmentalSerializer.SIZE  # Return zeros on error
    
    def update_data(self, temp: Optional[float], rh: Optional[float], 
                   co2: Optional[int], light: Optional[int], start_time: float):
        """Update environmental measurements
        
        Args:
            temp: Temperature in °C
            rh: Relative humidity in %
            co2: CO₂ in ppm
            light: Light sensor raw value
            start_time: System start time for uptime calculation
        """
        # Update environmental data
        # Cast CO2 and light defensively to int to avoid float propagation
        self.env_data.co2_ppm = int(co2) if co2 is not None else 0
        self.env_data.temp_x10 = int(temp * 10) if temp is not None else 0
        self.env_data.rh_x10 = int(rh * 10) if rh is not None else 0
        self.env_data.light_raw = int(light) if light is not None else 0
        self.env_data.update_uptime(start_time)
        
        uptime_sec = self.env_data.uptime_ms // 1000
        logger.info(f"BLE advertising readings: T={temp}°C, RH={rh}%, "
                   f"CO2={co2}ppm, Light={light} (uptime: {uptime_sec}s)")

        # Immediately update underlying characteristic value so any subscribed
        # clients (or late subscriptions) see the latest payload. This triggers
        # BlueZero's notify mechanism via BaseCharacteristic.notify() implementation.
        try:
            packed = EnvironmentalSerializer.pack(self.env_data)
            self.notify(packed)
        except Exception as e:
            logger.debug(f"Env value update notify failed: {e}")
    
    def _update_from_sensor_data(self, sensor_data):
        """Update from sensor data callback result
        
        Args:
            sensor_data: Data from sensor system
        """
        try:
            if hasattr(sensor_data, 'temperature'):
                self.env_data.temp_x10 = int(sensor_data.temperature * 10)
            if hasattr(sensor_data, 'humidity'):
                self.env_data.rh_x10 = int(sensor_data.humidity * 10)
            if hasattr(sensor_data, 'co2'):
                self.env_data.co2_ppm = sensor_data.co2
            if hasattr(sensor_data, 'light'):
                self.env_data.light_raw = sensor_data.light
                
        except Exception as e:
            logger.error(f"Error updating from sensor data: {e}")
    
    def notify_update(self, connected_devices: set):
        """Send notification to connected devices
        
        Args:
            connected_devices: Set of connected device addresses
        """
        if not connected_devices or self.simulation_mode:
            return
            
        try:
            data = EnvironmentalSerializer.pack(self.env_data)
            
            # Log notification details
            temp_c = self.env_data.temp_x10 / 10.0
            rh_pct = self.env_data.rh_x10 / 10.0
            logger.info(f"BLE notifying {len(connected_devices)} device(s): "
                       f"T={temp_c:.1f}°C, RH={rh_pct:.1f}%, "
                       f"CO2={self.env_data.co2_ppm}ppm, Light={self.env_data.light_raw}")
            
            # Send notification to all connected devices
            for device in connected_devices:
                try:
                    self.notify(data, device)
                    logger.debug(f"  ✓ Notified device: {device}")
                except Exception as e:
                    logger.warning(f"  ✗ Failed to notify device {device}: {e}")
                    
        except Exception as e:
            logger.error(f"Error notifying environmental data: {e}")
    
    def set_sensor_callback(self, callback: Callable):
        """Set callback function to get sensor data
        
        Args:
            callback: Function that returns current sensor data
        """
        self.get_sensor_data = callback