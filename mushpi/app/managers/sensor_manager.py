"""
MushPi Sensor Manager

Main sensor management class - coordinates all sensors with fallback logic.
"""

import time
import logging
import threading
from dataclasses import asdict
from datetime import datetime
from typing import Optional, Dict, List, Any

from ..models.dataclasses import SensorReading, ThresholdEvent
from ..database.manager import DatabaseManager
from ..managers.threshold_manager import ThresholdManager
from ..sensors.scd41 import SCD41Sensor
from ..sensors.dht22 import DHT22Sensor
from ..sensors.light_sensor import LightSensor
from ..sensors.base import SCD41Error, DHT22Error, LightSensorError

# Logging Setup
logger = logging.getLogger(__name__)


class SensorManager:
    """Main sensor management class - coordinates all sensors with fallback logic"""
    
    def __init__(self, db_manager: DatabaseManager = None, threshold_manager: ThresholdManager = None):
        self.db_manager = db_manager or DatabaseManager()
        self.threshold_manager = threshold_manager or ThresholdManager(db_manager=self.db_manager)
        
        # Initialize sensors
        self.scd41 = None
        self.dht22 = None
        self.light_sensor = None
        
        # Monitoring state
        self.monitoring = False
        self.monitor_thread = None
        self.monitor_interval = 30.0  # 30 seconds between readings
        
        # Last readings cache
        self.last_reading = None
        self.last_successful_sources = {
            'co2': None,
            'temperature': None, 
            'humidity': None,
            'light': None
        }
        
        self._initialize_sensors()
        
    def _initialize_sensors(self) -> None:
        """Initialize all available sensors"""
        logger.info("Initializing sensor systems...")
        
        # Initialize SCD41 (primary)
        try:
            self.scd41 = SCD41Sensor()
            logger.info("✅ SCD41 sensor ready")
        except SCD41Error as e:
            logger.error(f"❌ SCD41 initialization failed: {e}")
            
        # Initialize DHT22 (backup)
        try:
            self.dht22 = DHT22Sensor()
            logger.info("✅ DHT22 sensor ready")  
        except DHT22Error as e:
            logger.error(f"❌ DHT22 initialization failed: {e}")
            
        # Initialize Light sensor
        try:
            self.light_sensor = LightSensor()
            logger.info("✅ Light sensor ready")
        except LightSensorError as e:
            logger.error(f"❌ Light sensor initialization failed: {e}")
            
    def get_current_reading(self) -> Optional[SensorReading]:
        """Get current sensor readings with fallback logic"""
        current_time = datetime.now()
        reading = SensorReading(timestamp=current_time)
        sources = []
        
        # Get CO2, Temperature, Humidity from SCD41 (primary)
        if self.scd41:
            try:
                scd41_data = self.scd41.read_sensor()
                if scd41_data:
                    reading.co2_ppm, reading.temperature_c, reading.humidity_percent = scd41_data
                    sources.append("SCD41")
                    self.last_successful_sources['co2'] = 'SCD41'
                    self.last_successful_sources['temperature'] = 'SCD41'
                    self.last_successful_sources['humidity'] = 'SCD41'
            except SCD41Error as e:
                logger.warning(f"SCD41 read failed: {e}")
                
        # Fallback to DHT22 for Temperature/Humidity if SCD41 failed
        if (reading.temperature_c is None or reading.humidity_percent is None) and self.dht22:
            try:
                dht22_data = self.dht22.read_sensor()
                if dht22_data:
                    dht_temp, dht_humidity = dht22_data
                    
                    if reading.temperature_c is None:
                        reading.temperature_c = dht_temp
                        self.last_successful_sources['temperature'] = 'DHT22'
                        
                    if reading.humidity_percent is None:
                        reading.humidity_percent = dht_humidity
                        self.last_successful_sources['humidity'] = 'DHT22'
                        
                    sources.append("DHT22")
            except DHT22Error as e:
                logger.warning(f"DHT22 fallback failed: {e}")
                
        # Get Light Level
        if self.light_sensor:
            try:
                light_data = self.light_sensor.read_sensor()
                if light_data is not None:
                    reading.light_level = light_data
                    sources.append("ADS1115")
                    self.last_successful_sources['light'] = 'ADS1115'
            except LightSensorError as e:
                logger.warning(f"Light sensor read failed: {e}")
                
        # Set sensor source info
        reading.sensor_source = "+".join(sources) if sources else "SIMULATION"
        
        self.last_reading = reading
        return reading
        
    def start_monitoring(self) -> None:
        """Start background sensor monitoring"""
        if self.monitoring:
            logger.warning("Sensor monitoring already running")
            return
            
        self.monitoring = True
        self.monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.monitor_thread.start()
        logger.info(f"Sensor monitoring started (interval: {self.monitor_interval}s)")
        
    def stop_monitoring(self) -> None:
        """Stop background sensor monitoring"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5.0)
        logger.info("Sensor monitoring stopped")
        
    def _monitor_loop(self) -> None:
        """Background monitoring loop"""
        while self.monitoring:
            try:
                # Get current reading
                reading = self.get_current_reading()
                if not reading:
                    logger.warning("No sensor reading obtained")
                    time.sleep(self.monitor_interval)
                    continue
                    
                # Save to database
                self.db_manager.save_reading(reading)
                
                # Check thresholds
                threshold_events = self.threshold_manager.check_thresholds(reading)
                
                # Log and save threshold events
                for event in threshold_events:
                    logger.warning(f"Threshold violation: {event.parameter} = {event.current_value} "
                                 f"({event.threshold_type} threshold: {event.threshold_value})")
                    self.db_manager.save_threshold_event(event)
                    
                # Log current status
                self._log_reading_status(reading, threshold_events)
                
            except Exception as e:
                logger.error(f"Error in sensor monitoring loop: {e}")
                
            # Wait for next reading
            time.sleep(self.monitor_interval)
            
    def _log_reading_status(self, reading: SensorReading, events: List[ThresholdEvent]) -> None:
        """Log current sensor status"""
        status_parts = []
        
        if reading.temperature_c is not None:
            status_parts.append(f"T:{reading.temperature_c:.1f}°C")
        if reading.humidity_percent is not None:
            status_parts.append(f"RH:{reading.humidity_percent:.1f}%")
        if reading.co2_ppm is not None:
            status_parts.append(f"CO2:{reading.co2_ppm}ppm")
        if reading.light_level is not None:
            status_parts.append(f"Light:{reading.light_level:.0f}")
            
        status = " | ".join(status_parts)
        
        if events:
            logger.info(f"📊 {status} | ⚠️ {len(events)} threshold violations | {reading.sensor_source}")
        else:
            logger.info(f"📊 {status} | ✅ All thresholds OK | {reading.sensor_source}")
            
    def get_sensor_status(self) -> Dict[str, Any]:
        """Get detailed sensor status information"""
        return {
            'sensors': {
                'scd41': {
                    'available': self.scd41 is not None,
                    'last_successful': self.last_successful_sources.get('co2')
                },
                'dht22': {
                    'available': self.dht22 is not None,
                    'last_successful': any(src == 'DHT22' for src in self.last_successful_sources.values())
                },
                'light': {
                    'available': self.light_sensor is not None,
                    'last_successful': self.last_successful_sources.get('light')
                }
            },
            'monitoring': {
                'active': self.monitoring,
                'interval': self.monitor_interval
            },
            'last_reading': asdict(self.last_reading) if self.last_reading else None
        }
        
    def shutdown(self) -> None:
        """Shutdown sensor manager and cleanup resources"""
        logger.info("Shutting down sensor manager...")
        
        # Stop monitoring
        self.stop_monitoring()
        
        # Cleanup sensors
        if self.scd41:
            self.scd41.stop_measurement()
            
        logger.info("Sensor manager shutdown complete")