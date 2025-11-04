"""
BLE GATT Service Management

Main service coordinator for BLE GATT telemetry system.
Manages service creation, characteristics, and coordination.
"""

import logging
import threading
import time
from typing import Optional, Dict, Any, Callable, Set

try:
    from bluezero import adapter
    from bluezero import localGATT
    BLE_AVAILABLE = True
except ImportError:
    BLE_AVAILABLE = False

from ..core.config import config
from ..models.ble_dataclasses import StatusFlags
from .characteristics.environmental import EnvironmentalMeasurementsCharacteristic
from .characteristics.control_targets import ControlTargetsCharacteristic
from .characteristics.stage_state import StageStateCharacteristic
from .characteristics.override_bits import OverrideBitsCharacteristic
from .characteristics.status_flags import StatusFlagsCharacteristic

logger = logging.getLogger(__name__)


class BLEServiceError(Exception):
    """Exception for BLE service-related errors"""
    pass


class BLEGATTServiceManager:
    """BLE GATT service manager for MushPi telemetry"""
    
    def __init__(self):
        """Initialize BLE GATT service manager"""
        self.config = config
        self.adapter = None
        self.service = None
        self.characteristics = {}
        self.simulation_mode = self.config.development.simulation_mode
        
        # Thread safety
        self._lock = threading.Lock()
        self._running = False
        
        # Service state
        self.start_time = 0
        
        # Initialize characteristics
        self._create_characteristics()
        
    def initialize(self) -> bool:
        """Initialize BLE adapter and service
        
        Returns:
            True if initialization successful, False otherwise
        """
        if self.simulation_mode:
            logger.info("BLE GATT service running in simulation mode")
            self._running = True
            return True
            
        if not BLE_AVAILABLE:
            logger.warning("BlueZero not available - BLE GATT service disabled")
            return False
            
        try:
            # Initialize BLE adapter
            self.adapter = adapter.Adapter()
            if not self.adapter.powered:
                self.adapter.powered = True
                
            # Create GATT service
            self._create_service()
            
            logger.info("BLE GATT service initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize BLE GATT service: {e}")
            return False
    
    def _create_service(self):
        """Create BLE GATT service and register characteristics"""
        if self.simulation_mode:
            logger.info("BLE GATT service creation skipped (simulation mode)")
            return
            
        try:
            # Create main GATT service using localGATT
            self.service = localGATT.Service(
                1,  # Service ID
                self.config.bluetooth.service_uuid,
                True  # Primary service
            )
            
            # Register characteristics with the service
            for name, char in self.characteristics.items():
                if hasattr(char, 'characteristic') and char.characteristic:
                    logger.debug(f"Registered characteristic: {name}")
            
            logger.info("BLE GATT characteristics created successfully")
            
        except Exception as e:
            logger.error(f"Failed to create BLE GATT service: {e}")
            raise BLEServiceError(f"Failed to create service: {e}")
    
    def _create_characteristics(self):
        """Create all BLE characteristics"""
        try:
            # Create characteristics (they'll handle simulation mode internally)
            self.characteristics = {
                'env_measurements': EnvironmentalMeasurementsCharacteristic(
                    self.service, self.simulation_mode
                ),
                'control_targets': ControlTargetsCharacteristic(
                    self.service, self.simulation_mode
                ),
                'stage_state': StageStateCharacteristic(
                    self.service, self.simulation_mode
                ),
                'override_bits': OverrideBitsCharacteristic(
                    self.service, self.simulation_mode
                ),
                'status_flags': StatusFlagsCharacteristic(
                    self.service, self.simulation_mode
                )
            }
            
            logger.debug("BLE characteristics created")
            
        except Exception as e:
            logger.error(f"Failed to create characteristics: {e}")
            raise BLEServiceError(f"Failed to create characteristics: {e}")
    
    def start(self) -> bool:
        """Start BLE GATT service and advertising
        
        Returns:
            True if started successfully, False otherwise
        """
        if self.simulation_mode:
            logger.info("BLE GATT service started (simulation mode)")
            self._running = True
            self.start_time = time.time()
            return True
            
        if not self.adapter:
            logger.error("BLE adapter not initialized")
            return False
            
        try:
            # Start advertising with dynamic name
            advertising_name = self._get_advertising_name()
            
            # Configure adapter for advertising
            self.adapter.powered = True
            self.adapter.discoverable = True
            self.adapter.alias = advertising_name
            
            # Register service if available
            if self.service:
                # BlueZero automatically handles service registration
                # Just need to ensure service is published
                pass
            
            self._running = True
            self.start_time = time.time()
            logger.info(f"BLE GATT service started - advertising as '{advertising_name}'")
            return True
            
        except Exception as e:
            logger.error(f"Failed to start BLE GATT service: {e}")
            return False
    
    def stop(self):
        """Stop BLE GATT service and advertising"""
        self._running = False
        
        if self.simulation_mode:
            logger.info("BLE GATT service stopped (simulation mode)")
            return
            
        try:
            # Stop GATT application
            if hasattr(self, 'app') and self.app:
                self.app.stop()
                
            if self.adapter:
                # Stop advertising
                self.adapter.discoverable = False
                    
            logger.info("BLE GATT service stopped")
            
        except Exception as e:
            logger.error(f"Error stopping BLE GATT service: {e}")
    
    def _get_advertising_name(self) -> str:
        """Generate dynamic advertising name: MushPi-<species><stage>
        
        Returns:
            Advertising name string
        """
        try:
            stage_char = self.characteristics.get('stage_state')
            if stage_char and hasattr(stage_char, 'get_stage_data') and stage_char.get_stage_data:
                stage_info = stage_char.get_stage_data()
                if stage_info:
                    species = stage_info.get('species', 'Unknown')
                    stage = stage_info.get('stage', 'Init')
                    return f"{self.config.bluetooth.name_prefix}-{species}{stage}"
            
            return f"{self.config.bluetooth.name_prefix}-Init"
            
        except Exception:
            return f"{self.config.bluetooth.name_prefix}-Error"
    
    def update_advertising_name(self):
        """Update BLE advertising name based on current stage"""
        if not self._running or self.simulation_mode:
            return
            
        try:
            new_name = self._get_advertising_name()
            if self.adapter and self.adapter.alias != new_name:
                self.adapter.alias = new_name
                logger.info(f"BLE advertising name updated to: {new_name}")
                
        except Exception as e:
            logger.error(f"Error updating advertising name: {e}")
    
    def set_callbacks(self, callbacks: Dict[str, Callable]):
        """Set callback functions for data access
        
        Args:
            callbacks: Dictionary of callback functions
        """
        try:
            # Environmental measurements callbacks
            env_char = self.characteristics.get('env_measurements')
            if env_char and 'get_sensor_data' in callbacks:
                env_char.set_sensor_callback(callbacks['get_sensor_data'])
            
            # Control targets callbacks
            control_char = self.characteristics.get('control_targets')
            if control_char and 'get_control_data' in callbacks and 'set_control_targets' in callbacks:
                control_char.set_control_callbacks(
                    callbacks['get_control_data'],
                    callbacks['set_control_targets']
                )
            
            # Stage state callbacks
            stage_char = self.characteristics.get('stage_state')
            if stage_char and 'get_stage_data' in callbacks and 'set_stage_state' in callbacks:
                stage_char.set_stage_callbacks(
                    callbacks['get_stage_data'],
                    callbacks['set_stage_state']
                )
            
            # Override bits callback
            override_char = self.characteristics.get('override_bits')
            if override_char and 'apply_overrides' in callbacks:
                override_char.set_override_callback(callbacks['apply_overrides'])
            
            logger.debug("BLE service callbacks configured")
            
        except Exception as e:
            logger.error(f"Error setting callbacks: {e}")
    
    def notify_environmental_data(self, temp: Optional[float], rh: Optional[float], 
                                 co2: Optional[int], light: Optional[int], 
                                 connected_devices: Set[str]):
        """Update environmental measurements and notify connected clients
        
        Args:
            temp: Temperature in °C
            rh: Relative humidity in %
            co2: CO₂ in ppm
            light: Light sensor raw value
            connected_devices: Set of connected device addresses
        """
        if not self._running:
            return
            
        try:
            env_char = self.characteristics.get('env_measurements')
            if env_char:
                env_char.update_data(temp, rh, co2, light, self.start_time)
                if connected_devices:
                    env_char.notify_update(connected_devices)
                    
        except Exception as e:
            logger.error(f"Error notifying environmental data: {e}")
    
    def update_status_flags(self, flags: StatusFlags, connected_devices: Set[str]):
        """Update system status flags and notify clients
        
        Args:
            flags: Status flags to set
            connected_devices: Set of connected device addresses
        """
        try:
            status_char = self.characteristics.get('status_flags')
            if status_char:
                status_char.update_flags(flags, connected_devices)
                if connected_devices:
                    status_char.notify_update(connected_devices)
                    
        except Exception as e:
            logger.error(f"Error updating status flags: {e}")
    
    def is_running(self) -> bool:
        """Check if BLE GATT service is running
        
        Returns:
            True if service is running, False otherwise
        """
        return self._running
    
    def get_characteristic(self, name: str):
        """Get a specific characteristic by name
        
        Args:
            name: Characteristic name
            
        Returns:
            Characteristic object or None
        """
        return self.characteristics.get(name)


# Export main class
__all__ = ['BLEGATTServiceManager', 'BLEServiceError']