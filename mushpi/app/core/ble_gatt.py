"""
MushPi BLE GATT Telemetry Service

Clean modular BLE GATT system with backward compatibility.
This file provides the original API using the new modular architecture.

Service UUID: 12345678-1234-5678-1234-56789abcdef0 (ENV-CONTROL)

Characteristics:
- env_measurements (notify/read): CO₂, temp, humidity, light, uptime
- control_targets (read/write): threshold configuration  
- stage_state (read/write): current growth stage info
- override_bits (write): manual relay control
- status_flags (notify/read): system status

Integration with existing modules:
- sensors.py: Real-time sensor data
- control.py: Threshold management and relay control
- stage.py: Growth stage management
- config.py: Bluetooth configuration

Modular Architecture:
- ../ble/service.py: Main service management
- ../ble/characteristics/: Individual characteristic handlers
- ../ble/serialization.py: Data packing/unpacking
- ../models/ble_dataclasses.py: Data models and enums
"""

import time
import logging
from typing import Optional, Dict, Any, Callable

# Import all modular components
from ..models.ble_dataclasses import (
    OverrideBits, StatusFlags, EnvironmentalData, ControlTargets, StageStateData,
    ENV_MEASUREMENTS_UUID, CONTROL_TARGETS_UUID, STAGE_STATE_UUID,
    OVERRIDE_BITS_UUID, STATUS_FLAGS_UUID, ACTUATOR_STATUS_UUID
)
from ..ble.service import BLEGATTServiceManager, BLEServiceError
from ..ble.connection_manager import ConnectionManager
from .config import config
from ..ble.characteristics.config_version import ConfigVersionCharacteristic
from ..ble.characteristics.config_ctrl import ConfigControlCharacteristic
from ..ble.characteristics.config_in import ConfigInCharacteristic
from ..ble.characteristics.config_out import ConfigOutCharacteristic

logger = logging.getLogger(__name__)

# Backward compatibility: Export original classes and constants
__all__ = [
    # Original classes (now imported from modular components)
    'OverrideBits', 'StatusFlags', 'EnvironmentalData', 'ControlTargets', 'StageStateData',
    'BLEGATTService',  # Backward compatible wrapper
    # Original UUIDs
    'ENV_MEASUREMENTS_UUID', 'CONTROL_TARGETS_UUID', 'STAGE_STATE_UUID',
    'OVERRIDE_BITS_UUID', 'STATUS_FLAGS_UUID', 'ACTUATOR_STATUS_UUID',
    # Original API functions
    'initialize_ble_service', 'start_ble_service', 'stop_ble_service',
    'notify_env_packet', 'notify_actuator_status', 'update_status_flags', 'set_callbacks',
    'is_service_running', 'get_connection_count'
]


class BLEGATTService:
    """Backward-compatible wrapper for the modular BLE GATT service
    
    This class maintains the original API while delegating to the new modular components.
    """
    
    def __init__(self):
        """Initialize BLE GATT service wrapper"""
        self.config = config
        self.service_manager = BLEGATTServiceManager()
        self.connection_manager = ConnectionManager(self.config.development.simulation_mode)
        
        # Set up connection event callbacks
        self.connection_manager.set_connection_callbacks(
            on_connect=self._on_device_connected,
            on_disconnect=self._on_device_disconnected
        )
        
        # Backward compatibility properties
        self.adapter = None
        self.service = None
        self.characteristics = {}
        self.connected_devices = set()
        self.start_time = time.time()
        
        # Current data state (for backward compatibility)
        self.env_data = EnvironmentalData.create_empty()
        self.control_targets = ControlTargets.create_default()
        self.stage_data = StageStateData.create_empty()
        self.override_bits = 0
        self.status_flags = StatusFlags.SIMULATION if self.config.development.simulation_mode else 0
        # Config BLE extended state (no heavy caching here). Use simple assignments (Python 3.10 safe).
        self._config_version_char = None  # type: Optional[ConfigVersionCharacteristic]
        self._config_ctrl_char = None     # type: Optional[ConfigControlCharacteristic]
        self._config_in_char = None       # type: Optional[ConfigInCharacteristic]
        self._config_out_char = None      # type: Optional[ConfigOutCharacteristic]
        
        # Callbacks for data updates (set by main application)
        self.get_sensor_data = None        # type: Optional[Callable]
        self.get_control_data = None       # type: Optional[Callable]  # Relay states
        self.get_control_targets = None    # type: Optional[Callable]  # Thresholds
        self.get_stage_data = None         # type: Optional[Callable]
        self.set_control_targets = None    # type: Optional[Callable]
        self.set_stage_state = None        # type: Optional[Callable]
        self.apply_overrides = None        # type: Optional[Callable]
        self.get_stage_thresholds = None   # type: Optional[Callable]
        self.set_stage_thresholds = None   # type: Optional[Callable]
        
        self._running = False

    # ------------------------------------------------------------------
    # Helper methods for new configuration characteristics
    # ------------------------------------------------------------------
    def get_config_version(self) -> Optional[Dict[str, Any]]:
        """Return current config version metadata if characteristic active.

        Returns:
            Dict with version metadata or None if unavailable.
        """
        try:
            if self._config_version_char and hasattr(self._config_version_char, 'current_version'):
                ver = self._config_version_char.current_version
                if ver:
                    return {
                        'hash': ver.hash_hex,
                        'size': ver.size,
                        'modified': ver.last_modified,
                        'bytes': ver.version_bytes.hex() if ver.version_bytes else None
                    }
        except Exception as e:
            logger.debug(f"get_config_version failed: {e}")
        return None

    def request_config_get(self) -> bool:
        """Initiate a config GET sequence via control characteristic.

        Sends HELLO then GET if control/out characteristics are present.
        Returns:
            True if request sent, False otherwise.
        """
        try:
            if self._config_ctrl_char and self._config_out_char:
                # Emulate BLE writes to control characteristic
                self._config_ctrl_char._handle_write(b'{"op":"HELLO"}', {})
                self._config_ctrl_char._handle_write(b'{"op":"GET"}', {})
                return True
        except Exception as e:
            logger.debug(f"request_config_get failed: {e}")
        return False
        
    def initialize(self) -> bool:
        """Initialize BLE adapter and service
        
        Returns:
            True if initialization successful, False otherwise
        """
        try:
            # Initialize service manager first to obtain adapter
            success = self.service_manager.initialize()
            
            if success:
                # Now that adapter is available, initialize connection manager
                if not self.connection_manager.initialize(self.service_manager.adapter):
                    logger.warning("Connection manager initialization failed")
                
                # Set up callbacks in service manager
                self._setup_service_callbacks()
                
                # Update backward compatibility properties
                self.adapter = getattr(self.service_manager, 'adapter', None)
                self.service = getattr(self.service_manager, 'service', None)
                self._update_characteristics_dict()
                
            return success
            
        except Exception as e:
            logger.error(f"Failed to initialize BLE GATT service: {e}")
            return False
    
    def start(self) -> bool:
        """Start BLE GATT service and advertising
        
        Returns:
            True if started successfully, False otherwise
        """
        try:
            success = self.service_manager.start()
            if success:
                self._running = True
                self.start_time = time.time()
                
            return success
            
        except Exception as e:
            logger.error(f"Failed to start BLE GATT service: {e}")
            return False
    
    def stop(self):
        """Stop BLE GATT service and advertising"""
        try:
            self.service_manager.stop()
            self.connection_manager.disconnect_all()
            self._running = False
            self.connected_devices.clear()
            
        except Exception as e:
            logger.error(f"Error stopping BLE GATT service: {e}")
    
    def notify_env_packet(self, temp: Optional[float], rh: Optional[float], 
                         co2: Optional[int], light: Optional[int]):
        """Update environmental measurements and notify connected clients
        
        Args:
            temp: Temperature in °C
            rh: Relative humidity in %
            co2: CO₂ in ppm
            light: Light sensor raw value
        """
        if not self._running:
            return
            
        try:
            # Update local data for backward compatibility
            self.env_data.co2_ppm = co2 if co2 is not None else 0
            self.env_data.temp_x10 = int(temp * 10) if temp is not None else 0
            self.env_data.rh_x10 = int(rh * 10) if rh is not None else 0
            self.env_data.light_raw = light if light is not None else 0
            self.env_data.update_uptime(self.start_time)
            
            # Delegate to service manager
            connected_devices = self.connection_manager.get_connected_devices()
            self.service_manager.notify_environmental_data(
                temp, rh, co2, light, connected_devices
            )
            
        except Exception as e:
            logger.error(f"Error notifying environmental data: {e}")
    
    def update_status_flags(self, flags: StatusFlags):
        """Update system status flags
        
        Args:
            flags: Status flags to set
        """
        try:
            # Update local data for backward compatibility
            self.status_flags = flags
            if self.config.development.simulation_mode:
                self.status_flags |= StatusFlags.SIMULATION
                
            # Delegate to service manager
            connected_devices = self.connection_manager.get_connected_devices()
            self.service_manager.update_status_flags(flags, connected_devices)
            
        except Exception as e:
            logger.error(f"Error updating status flags: {e}")

    def notify_actuator_status(self):
        """Notify clients with current actuator ON/OFF state bits"""
        try:
            connected_devices = self.connection_manager.get_connected_devices()
            self.service_manager.notify_actuator_status(connected_devices)
        except Exception as e:
            logger.error(f"Error notifying actuator status: {e}")
    
    def update_advertising_name(self):
        """Update BLE advertising name based on current stage"""
        try:
            self.service_manager.update_advertising_name()
        except Exception as e:
            logger.error(f"Error updating advertising name: {e}")
    
    def is_running(self) -> bool:
        """Check if BLE GATT service is running
        
        Returns:
            True if service is running, False otherwise
        """
        return self._running and self.service_manager.is_running()
    
    def get_connection_count(self) -> int:
        """Get number of connected BLE clients
        
        Returns:
            Number of connected clients
        """
        return self.connection_manager.get_connection_count()
    
    def _setup_service_callbacks(self):
        """Set up callbacks in the service manager"""
        callbacks = {}
        
        if self.get_sensor_data:
            callbacks['get_sensor_data'] = self.get_sensor_data
        if self.get_control_data:
            callbacks['get_control_data'] = self.get_control_data
        if self.get_control_targets:
            callbacks['get_control_targets'] = self.get_control_targets
        if self.get_stage_data:
            callbacks['get_stage_data'] = self.get_stage_data
        if self.set_control_targets:
            callbacks['set_control_targets'] = self.set_control_targets
        if self.set_stage_state:
            callbacks['set_stage_state'] = self.set_stage_state
        if self.apply_overrides:
            callbacks['apply_overrides'] = self.apply_overrides
        if self.get_stage_thresholds:
            callbacks['get_stage_thresholds'] = self.get_stage_thresholds
        if self.set_stage_thresholds:
            callbacks['set_stage_thresholds'] = self.set_stage_thresholds
            
        if callbacks:
            self.service_manager.set_callbacks(callbacks)
    
    def _update_characteristics_dict(self):
        """Update characteristics dict for backward compatibility"""
        # Map new characteristic objects to old dictionary format
        service_chars = self.service_manager.characteristics
        self.characteristics = {
            name: char for name, char in service_chars.items()
        }
        # Capture config characteristic references for quick access
        self._config_version_char = service_chars.get('config_version')
        self._config_ctrl_char = service_chars.get('config_ctrl')
        self._config_in_char = service_chars.get('config_in')
        self._config_out_char = service_chars.get('config_out')
    
    def _on_device_connected(self, device_address: str, connected_set: set):
        """Handle device connection event
        
        Args:
            device_address: Address of connected device
            connected_set: Set of all connected devices
        """
        self.connected_devices = connected_set.copy()
        logger.info(f"Device connected: {device_address} (total: {len(connected_set)})")
    
    def _on_device_disconnected(self, device_address: str, connected_set: set):
        """Handle device disconnection event
        
        Args:
            device_address: Address of disconnected device
            connected_set: Set of all connected devices
        """
        self.connected_devices = connected_set.copy()
        logger.info(f"Device disconnected: {device_address} (total: {len(connected_set)})")


# Global service instance (for backward compatibility)
_ble_service: Optional[BLEGATTService] = None


def initialize_ble_service() -> bool:
    """Initialize global BLE GATT service
    
    Returns:
        True if initialization successful, False otherwise
    """
    global _ble_service
    
    try:
        if _ble_service is None:
            _ble_service = BLEGATTService()
            
        return _ble_service.initialize()
        
    except Exception as e:
        logger.error(f"Failed to initialize BLE service: {e}")
        return False


def start_ble_service() -> bool:
    """Start global BLE GATT service
    
    Returns:
        True if started successfully, False otherwise
    """
    global _ble_service
    
    try:
        # Always initialize if service exists but hasn't been initialized yet
        if _ble_service is None:
            if not initialize_ble_service():
                return False
        elif not _ble_service._running and _ble_service.service_manager.adapter is None:
            # Service instance exists but wasn't initialized (e.g., created by set_callbacks)
            if not _ble_service.initialize():
                return False
                
        return _ble_service.start()
        
    except Exception as e:
        logger.error(f"Failed to start BLE service: {e}")
        return False


def stop_ble_service():
    """Stop global BLE GATT service"""
    global _ble_service
    
    try:
        if _ble_service:
            _ble_service.stop()
            
    except Exception as e:
        logger.error(f"Error stopping BLE service: {e}")


def notify_env_packet(temp: Optional[float], rh: Optional[float], 
                     co2: Optional[int], light: Optional[int]):
    """Update environmental measurements (public API for main.py)
    
    Args:
        temp: Temperature in °C
        rh: Relative humidity in %
        co2: CO₂ in ppm
        light: Light sensor raw value
    """
    global _ble_service
    
    try:
        if _ble_service and _ble_service.is_running():
            _ble_service.notify_env_packet(temp, rh, co2, light)
            
    except Exception as e:
        logger.error(f"Error in notify_env_packet: {e}")


def update_status_flags(flags: StatusFlags):
    """Update system status flags (public API)
    
    Args:
        flags: Status flags to set
    """
    global _ble_service
    
    try:
        if _ble_service and _ble_service.is_running():
            _ble_service.update_status_flags(flags)
            
    except Exception as e:
        logger.error(f"Error in update_status_flags: {e}")


def notify_actuator_status():
    """Notify clients with current actuator ON/OFF state bits (public API)"""
    global _ble_service

    try:
        if _ble_service and _ble_service.is_running():
            _ble_service.notify_actuator_status()
    except Exception as e:
        logger.error(f"Error in notify_actuator_status: {e}")


def set_callbacks(get_sensor_data: Optional[Callable] = None,
                 get_control_data: Optional[Callable] = None,
                 get_control_targets: Optional[Callable] = None,
                 get_stage_data: Optional[Callable] = None,
                 set_control_targets: Optional[Callable] = None,
                 set_stage_state: Optional[Callable] = None,
                 apply_overrides: Optional[Callable] = None,
                 get_stage_thresholds: Optional[Callable] = None,
                 set_stage_thresholds: Optional[Callable] = None):
    """Set callback functions for data access (public API)
    
    Args:
        get_sensor_data: Function to get current sensor data
        get_control_data: Function to get current control data (relay states)
        get_control_targets: Function to get current control thresholds
        get_stage_data: Function to get current stage data
        set_control_targets: Function to set new control targets
        set_stage_state: Function to set new stage state
        apply_overrides: Function to apply override settings
        get_stage_thresholds: Function to get thresholds for any species/stage
        set_stage_thresholds: Function to set thresholds for any species/stage
    """
    global _ble_service
    
    try:
        if _ble_service is None:
            _ble_service = BLEGATTService()
            
        # Set callbacks on the service instance
        if get_sensor_data:
            _ble_service.get_sensor_data = get_sensor_data
        if get_control_data:
            _ble_service.get_control_data = get_control_data
        if get_control_targets:
            _ble_service.get_control_targets = get_control_targets
        if get_stage_data:
            _ble_service.get_stage_data = get_stage_data
        if set_control_targets:
            _ble_service.set_control_targets = set_control_targets
        if set_stage_state:
            _ble_service.set_stage_state = set_stage_state
        if apply_overrides:
            _ble_service.apply_overrides = apply_overrides
        if get_stage_thresholds:
            _ble_service.get_stage_thresholds = get_stage_thresholds
        if set_stage_thresholds:
            _ble_service.set_stage_thresholds = set_stage_thresholds
            
        # Update service manager callbacks if already initialized
        if hasattr(_ble_service, 'service_manager'):
            _ble_service._setup_service_callbacks()
            
        logger.debug("BLE service callbacks configured")
        
    except Exception as e:
        logger.error(f"Error setting BLE callbacks: {e}")


def is_service_running() -> bool:
    """Check if BLE GATT service is running (public API)
    
    Returns:
        True if service is running, False otherwise
    """
    global _ble_service
    
    try:
        return _ble_service.is_running() if _ble_service else False
    except Exception as e:
        logger.error(f"Error checking BLE service status: {e}")
        return False


def get_connection_count() -> int:
    """Get number of connected BLE clients (public API)
    
    Returns:
        Number of connected clients
    """
    global _ble_service
    
    try:
        return _ble_service.get_connection_count() if _ble_service else 0
    except Exception as e:
        logger.error(f"Error getting connection count: {e}")
        return 0


def update_advertising_name():
    """Update BLE advertising name based on current stage (public API)"""
    global _ble_service
    
    try:
        if _ble_service:
            _ble_service.update_advertising_name()
    except Exception as e:
        logger.error(f"Error updating advertising name: {e}")


def get_service_instance() -> Optional[BLEGATTService]:
    """Get the global BLE service instance (for advanced usage)
    
    Returns:
        BLE service instance or None
    """
    return _ble_service