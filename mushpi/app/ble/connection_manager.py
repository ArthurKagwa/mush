"""
BLE Connection Management

Handles BLE device connections, disconnections, and related events.
"""

import logging
import threading
from typing import Set, Optional, Callable

try:
    from bluezero import adapter
    BLE_AVAILABLE = True
except ImportError:
    BLE_AVAILABLE = False

from ..models.ble_dataclasses import StatusFlags

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages BLE device connections and events"""
    
    def __init__(self, simulation_mode: bool = False):
        """Initialize connection manager
        
        Args:
            simulation_mode: Whether running in simulation mode
        """
        self.simulation_mode = simulation_mode
        self.connected_devices: Set[str] = set()
        self._lock = threading.Lock()
        
        # Callbacks
        self.on_connect_callback: Optional[Callable] = None
        self.on_disconnect_callback: Optional[Callable] = None
        
    def initialize(self, adapter_obj=None) -> bool:
        """Initialize connection management
        
        Args:
            adapter_obj: BLE adapter object
            
        Returns:
            True if initialization successful, False otherwise
        """
        if self.simulation_mode or not BLE_AVAILABLE:
            logger.info("Connection manager initialized (simulation mode)")
            return True
            
        try:
            if adapter_obj:
                self._setup_connection_callbacks(adapter_obj)
            
            logger.info("Connection manager initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize connection manager: {e}")
            return False
    
    def _setup_connection_callbacks(self, adapter_obj):
        """Set up BLE connection event callbacks
        
        Args:
            adapter_obj: BLE adapter object
        """
        if self.simulation_mode or not BLE_AVAILABLE:
            return
            
        try:
            # Set up device connection/disconnection callbacks
            adapter_obj.on_device_connect = self._on_device_connected
            adapter_obj.on_device_disconnect = self._on_device_disconnected
            
        except Exception as e:
            logger.error(f"Error setting up connection callbacks: {e}")
    
    def _on_device_connected(self, device):
        """Callback when a device connects
        
        Args:
            device: Connected device object
        """
        try:
            device_address = getattr(device, 'address', 'unknown')
            device_name = getattr(device, 'name', 'Unknown Device')
            
            with self._lock:
                self.connected_devices.add(device_address)
                
            logger.info("=" * 60)
            logger.info("🔌 BLE DEVICE CONNECTED")
            logger.info(f"  Address: {device_address}")
            logger.info(f"  Name: {device_name}")
            logger.info(f"  Total connected: {len(self.connected_devices)}")
            logger.info("=" * 60)
            
            # Call external callback if set
            if self.on_connect_callback:
                self.on_connect_callback(device_address, self.connected_devices.copy())
            
        except Exception as e:
            logger.error(f"Error handling device connection: {e}", exc_info=True)
    
    def _on_device_disconnected(self, device):
        """Callback when a device disconnects
        
        Args:
            device: Disconnected device object
        """
        try:
            device_address = getattr(device, 'address', 'unknown')
            device_name = getattr(device, 'name', 'Unknown Device')
            
            with self._lock:
                self.connected_devices.discard(device_address)
                
            logger.info("=" * 60)
            logger.warning("🔌 BLE DEVICE DISCONNECTED")
            logger.info(f"  Address: {device_address}")
            logger.info(f"  Name: {device_name}")
            logger.info(f"  Total connected: {len(self.connected_devices)}")
            logger.info("=" * 60)
            
            # Call external callback if set
            if self.on_disconnect_callback:
                self.on_disconnect_callback(device_address, self.connected_devices.copy())
            
        except Exception as e:
            logger.error(f"Error handling device disconnection: {e}", exc_info=True)
    
    def get_connected_devices(self) -> Set[str]:
        """Get set of connected device addresses
        
        Returns:
            Set of connected device addresses
        """
        with self._lock:
            return self.connected_devices.copy()
    
    def get_connection_count(self) -> int:
        """Get number of connected devices
        
        Returns:
            Number of connected devices
        """
        with self._lock:
            return len(self.connected_devices)
    
    def is_connected(self) -> bool:
        """Check if any devices are connected
        
        Returns:
            True if at least one device is connected, False otherwise
        """
        with self._lock:
            return len(self.connected_devices) > 0
    
    def disconnect_all(self):
        """Disconnect all connected devices"""
        if self.simulation_mode:
            logger.info("Disconnecting all devices (simulation mode)")
            with self._lock:
                self.connected_devices.clear()
            return
            
        try:
            # In a real implementation, we would iterate through
            # connected devices and disconnect them
            logger.info("Disconnecting all BLE devices")
            with self._lock:
                self.connected_devices.clear()
                
        except Exception as e:
            logger.error(f"Error disconnecting devices: {e}")
    
    def set_connection_callbacks(self, on_connect: Optional[Callable] = None, 
                               on_disconnect: Optional[Callable] = None):
        """Set callbacks for connection events
        
        Args:
            on_connect: Callback for device connection (device_address, connected_set)
            on_disconnect: Callback for device disconnection (device_address, connected_set)
        """
        self.on_connect_callback = on_connect
        self.on_disconnect_callback = on_disconnect
        
        logger.debug("Connection callbacks configured")
    
    def simulate_connection(self, device_address: str = "SIM:00:00:00:00:00"):
        """Simulate a device connection (for testing)
        
        Args:
            device_address: Simulated device address
        """
        if not self.simulation_mode:
            logger.warning("simulate_connection called in non-simulation mode")
            return
            
        with self._lock:
            self.connected_devices.add(device_address)
            
        logger.info(f"Simulated device connection: {device_address}")
        
        if self.on_connect_callback:
            self.on_connect_callback(device_address, self.connected_devices.copy())
    
    def simulate_disconnection(self, device_address: str = "SIM:00:00:00:00:00"):
        """Simulate a device disconnection (for testing)
        
        Args:
            device_address: Simulated device address
        """
        if not self.simulation_mode:
            logger.warning("simulate_disconnection called in non-simulation mode")
            return
            
        with self._lock:
            self.connected_devices.discard(device_address)
            
        logger.info(f"Simulated device disconnection: {device_address}")
        
        if self.on_disconnect_callback:
            self.on_disconnect_callback(device_address, self.connected_devices.copy())


# Export main class
__all__ = ['ConnectionManager']