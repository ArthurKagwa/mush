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
    from bluezero import adapter, peripheral
    from bluezero import localGATT
    BLE_AVAILABLE = True
except ImportError:
    BLE_AVAILABLE = False

# Always try to import dbus (even if BlueZero is available, we use it for advertising)
try:
    import dbus
    import dbus.exceptions
    import dbus.mainloop.glib
    import dbus.service
    from gi.repository import GLib
    DBUS_AVAILABLE = True
except Exception:
    DBUS_AVAILABLE = False

from ..core.config import config
from ..models.ble_dataclasses import StatusFlags
from .characteristics.environmental import EnvironmentalMeasurementsCharacteristic
from .characteristics.control_targets import ControlTargetsCharacteristic
from .characteristics.stage_state import StageStateCharacteristic
from .characteristics.override_bits import OverrideBitsCharacteristic
from .characteristics.status_flags import StatusFlagsCharacteristic
from .characteristics.uart import UARTRXCharacteristic, UARTTXCharacteristic
from .uuids import UART_SERVICE_UUID

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
        self.peripheral = None
        self.service = None
        self.uart_service = None
        self.characteristics = {}
        self.simulation_mode = self.config.development.simulation_mode
        
        # Thread safety
        self._lock = threading.Lock()
        self._running = False
        
        # Service state
        self.start_time = 0
        
        # Advertisement state
        self._advertisement_registered = False
        self._advertisement_path = None
        self._advertisement_obj = None
        
        # In simulation mode we still need characteristic containers for callbacks
        if self.simulation_mode:
            self._build_characteristics(service=None)
        
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

            # Create peripheral
            self.peripheral = peripheral.Peripheral(self.adapter.address, local_name=self.config.bluetooth.name_prefix)
                
            # Create GATT services
            self._create_services()
            
            logger.info("BLE GATT services initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize BLE GATT service: {e}")
            return False
    
    def _create_services(self):
        """Create BLE GATT services and register characteristics"""
        if self.simulation_mode:
            logger.info("BLE GATT service creation skipped (simulation mode)")
            return
            
        try:
            logger.info("Creating BLE GATT services...")
            
            # Create main GATT service using peripheral API
            logger.info(f"  Service UUID: {self.config.bluetooth.service_uuid}")
            srv_id_main = 1
            self.peripheral.add_service(
                srv_id=srv_id_main,
                uuid=self.config.bluetooth.service_uuid,
                primary=True
            )
            
            # Create a service object wrapper with required attributes
            class ServiceWrapper:
                def __init__(self, peripheral, srv_id):
                    self.peripheral = peripheral
                    self.srv_id = srv_id
            
            self.service = ServiceWrapper(self.peripheral, srv_id_main)
            
            # Create UART service
            logger.info(f"  UART Service UUID: {UART_SERVICE_UUID}")
            srv_id_uart = 2
            self.peripheral.add_service(
                srv_id=srv_id_uart,
                uuid=UART_SERVICE_UUID,
                primary=True
            )
            self.uart_service = ServiceWrapper(self.peripheral, srv_id_uart)
            
            # Bind characteristics to the newly created services so BlueZero can register them
            self._build_characteristics(main_service=self.service, uart_service=self.uart_service)

            # Count successfully created characteristics
            char_count = len(self.characteristics)
            logger.info(f"BLE GATT services ready with {char_count} characteristics")
            
            # CRITICAL: Publish the GATT server to BlueZ so services become discoverable
            logger.info("Publishing GATT server to BlueZ...")
            self.peripheral.publish()
            logger.info("✓ GATT server published - services now discoverable")
            
        except Exception as e:
            logger.error(f"Failed to create BLE GATT services: {e}")
            raise BLEServiceError(f"Failed to create services: {e}")
    
    def _build_characteristics(self, main_service, uart_service):
        """Instantiate all BLE characteristics against the provided services"""
        try:
            self.characteristics = {
                'env_measurements': EnvironmentalMeasurementsCharacteristic(
                    main_service, self.simulation_mode
                ),
                'control_targets': ControlTargetsCharacteristic(
                    main_service, self.simulation_mode
                ),
                'stage_state': StageStateCharacteristic(
                    main_service, self.simulation_mode
                ),
                'override_bits': OverrideBitsCharacteristic(
                    main_service, self.simulation_mode
                ),
                'status_flags': StatusFlagsCharacteristic(
                    main_service, self.simulation_mode
                ),
                'uart_rx': UARTRXCharacteristic(
                    uart_service, self.simulation_mode
                ),
                'uart_tx': UARTTXCharacteristic(
                    uart_service, self.simulation_mode
                )
            }

            logger.debug(
                "BLE characteristics created (simulation=%s, main_service_bound=%s, uart_service_bound=%s)",
                self.simulation_mode,
                main_service is not None,
                uart_service is not None
            )

        except Exception as e:
            logger.error(f"Failed to create characteristics: {e}")
            raise BLEServiceError(f"Failed to create characteristics: {e}")
    
    def start(self) -> bool:
        """Start BLE GATT service and advertising
        
        Returns:
            True if started successfully, False otherwise
        """
        global DBUS_AVAILABLE  # Ensure we can access the module-level variable
        
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
            
            # Disable pairing/bonding via D-Bus to prevent connection drops
            if DBUS_AVAILABLE:
                try:
                    self._disable_pairing()
                    logger.info("✓ BLE pairing/bonding disabled")
                except Exception as e:
                    logger.warning(f"Could not disable pairing (continuing anyway): {e}")
            
            # Optional: register a LE Advertisement via D-Bus to include service UUID in scan data
            # This is NOT required for service discovery to work (GATT server is already published)
            # It only adds the service UUID to the advertisement packet for faster filtering
            if DBUS_AVAILABLE:
                try:
                    self._register_dbus_advertisement(advertising_name)
                except dbus.exceptions.DBusException as e:
                    # Advertisement registration can fail if already registered or BlueZ busy
                    # This is OK - GATT server is published, service discovery will work fine
                    logger.info("ℹ️  D-Bus advertisement not registered (not critical)")
                    logger.debug(f"D-Bus advertisement error: {e}")
                except Exception as e:
                    logger.debug(f"D-Bus advertisement error: {e}")
            else:
                logger.debug("DBus not available; skipping advertisement registration")
            
            self._running = True
            self.start_time = time.time()
            logger.info(f"BLE GATT service started - advertising as '{advertising_name}'")
            
            # Log detailed status
            self.log_advertisement_status()
            
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
                try:
                    self.app.stop()
                except Exception:
                    pass

            # Unregister D-Bus advertisement if registered
            if hasattr(self, '_advertisement_registered') and self._advertisement_registered:
                try:
                    self._unregister_dbus_advertisement()
                except Exception as e:
                    logger.debug(f"Error unregistering advertisement: {e}")
                
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
        global DBUS_AVAILABLE  # Ensure we can access the module-level variable
        
        if not self._running or self.simulation_mode:
            return
            
        try:
            new_name = self._get_advertising_name()
            if self.adapter and self.adapter.alias != new_name:
                self.adapter.alias = new_name
                logger.info(f"BLE advertising name updated to: {new_name}")
                # Also update D-Bus advertisement name if registered
                if hasattr(self, '_advertisement_path') and self._advertisement_path:
                    try:
                        # Re-register advertisement with new name
                        if DBUS_AVAILABLE:
                            self._unregister_dbus_advertisement()
                            self._register_dbus_advertisement(new_name)
                    except Exception as e:
                        logger.debug(f"Failed to update D-Bus advertisement name: {e}")
                
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
    
    def get_advertisement_status(self) -> Dict[str, Any]:
        """Get current BLE advertisement status
        
        Returns:
            Dictionary containing advertisement status information
        """
        status = {
            'service_running': self._running,
            'simulation_mode': self.simulation_mode,
            'advertising_name': self._get_advertising_name() if self._running else 'N/A',
            'service_uuid': self.config.bluetooth.service_uuid,
            'adapter_powered': False,
            'adapter_discoverable': False,
            'dbus_advertisement_registered': False,
            'uptime_seconds': int(time.time() - self.start_time) if self.start_time > 0 else 0
        }
        
        if not self.simulation_mode and self.adapter:
            try:
                status['adapter_powered'] = self.adapter.powered
                status['adapter_discoverable'] = self.adapter.discoverable
            except Exception as e:
                logger.debug(f"Could not read adapter status: {e}")
        
        if hasattr(self, '_advertisement_registered'):
            status['dbus_advertisement_registered'] = self._advertisement_registered
        
        return status
    
    def log_advertisement_status(self):
        """Log detailed advertisement status"""
        status = self.get_advertisement_status()
        
        logger.info("=" * 60)
        logger.info("BLE Advertisement Status")
        logger.info("=" * 60)
        logger.info(f"Service Running:        {status['service_running']}")
        logger.info(f"Simulation Mode:        {status['simulation_mode']}")
        logger.info(f"Advertising Name:       {status['advertising_name']}")
        logger.info(f"Service UUID:           {status['service_uuid']}")
        logger.info(f"Adapter Powered:        {status['adapter_powered']}")
        logger.info(f"Adapter Discoverable:   {status['adapter_discoverable']}")
        logger.info(f"D-Bus Advertisement:    {'Registered' if status['dbus_advertisement_registered'] else 'Not Registered'}")
        logger.info(f"Uptime:                 {status['uptime_seconds']}s")
        logger.info("=" * 60)


    # ----------------------- D-Bus advertisement helpers -----------------------
    def _disable_pairing(self):
        """Disable Bluetooth pairing/bonding to allow connections without authentication.
        
        This prevents the "bonding" process that causes the Flutter app to disconnect.
        Sets the adapter to "NoInputNoOutput" capability which disables pairing.
        """
        global DBUS_AVAILABLE
        
        if not DBUS_AVAILABLE:
            return
            
        try:
            bus = dbus.SystemBus(private=False)
            adapter_path = '/org/bluez/hci0'
            
            # Get adapter object
            adapter_obj = bus.get_object('org.bluez', adapter_path)
            adapter_props = dbus.Interface(adapter_obj, 'org.freedesktop.DBus.Properties')
            
            # Set pairable to False to prevent pairing requests
            adapter_props.Set('org.bluez.Adapter1', 'Pairable', dbus.Boolean(False))
            logger.info("  ✓ Set adapter.Pairable = False")
            
            # Set discoverable timeout to 0 (always discoverable while powered)
            adapter_props.Set('org.bluez.Adapter1', 'DiscoverableTimeout', dbus.UInt32(0))
            logger.info("  ✓ Set adapter.DiscoverableTimeout = 0")
            
            # Remove all previously paired devices to ensure clean connections
            try:
                adapter_iface = dbus.Interface(adapter_obj, 'org.bluez.Adapter1')
                devices = adapter_iface.GetManagedObjects() if hasattr(adapter_iface, 'GetManagedObjects') else {}
                
                # Alternative: get devices from object manager
                if not devices:
                    obj_manager = bus.get_object('org.bluez', '/')
                    obj_iface = dbus.Interface(obj_manager, 'org.freedesktop.DBus.ObjectManager')
                    managed_objects = obj_iface.GetManagedObjects()
                    
                    removed_count = 0
                    for path, interfaces in managed_objects.items():
                        if 'org.bluez.Device1' in interfaces:
                            device_props = interfaces['org.bluez.Device1']
                            if device_props.get('Paired', False):
                                try:
                                    adapter_iface.RemoveDevice(dbus.ObjectPath(path))
                                    removed_count += 1
                                    logger.debug(f"  ✓ Removed paired device: {path}")
                                except Exception as e:
                                    logger.debug(f"  Could not remove device {path}: {e}")
                    
                    if removed_count > 0:
                        logger.info(f"  ✓ Removed {removed_count} previously paired device(s)")
                        
            except Exception as e:
                logger.debug(f"  Could not remove paired devices: {e}")
            
            logger.info("BLE adapter configured for connectionless operation (no pairing)")
            
        except dbus.exceptions.DBusException as e:
            logger.warning(f"D-Bus error while disabling pairing: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error disabling pairing: {e}")
            raise
    
    def _register_dbus_advertisement(self, advertising_name: str):
        """Register a simple LE Advertisement via BlueZ D-Bus API.

        This will ensure the custom 128-bit service UUID appears in the
        advertising packet so scanning apps can see the service.
        """
        global DBUS_AVAILABLE  # Ensure we can access the module-level variable
        
        if not DBUS_AVAILABLE:
            raise RuntimeError("DBus not available")

        try:
            # Ensure mainloop is set
            dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
            
            # Use system bus with increased timeout (default is 25 seconds, we use 60)
            bus = dbus.SystemBus(private=False)

            # Adapter path (assume hci0)
            adapter_path = '/org/bluez/hci0'

            # Create advertisement object path with unique timestamp to avoid conflicts
            ad_path = f'/uk/co/mushpi/advertisement{int(time.time())}'

            # Inner Advertisement class
            class LEAdvertisement(dbus.service.Object):
                def __init__(self, bus, path, advertising_type='peripheral'):
                    self.path = path
                    self.bus = bus
                    dbus.service.Object.__init__(self, bus, self.path)
                    self.ad_type = advertising_type
                    self.config = None

                def get_properties(self):
                    return {
                        'org.bluez.LEAdvertisement1': {
                            'Type': dbus.String(self.ad_type),
                            'ServiceUUIDs': dbus.Array([
                                dbus.String(str(self.config.bluetooth.service_uuid)),
                                dbus.String(str(UART_SERVICE_UUID))
                            ], signature='s'),
                            'LocalName': dbus.String(advertising_name),
                            'Includes': dbus.Array([dbus.String('tx-power')], signature='s')
                        }
                    }

                @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='s', out_signature='a{sv}')
                def GetAll(self, interface):
                    props = self.get_properties()
                    return props.get(interface, {})

                @dbus.service.method('org.bluez.LEAdvertisement1', in_signature='', out_signature='')
                def Release(self):
                    logger.info('Advertisement released by BlueZ')

            # Create advertisement instance
            advertisement = LEAdvertisement(bus, ad_path)
            advertisement.config = self.config

            # Get advertising manager with timeout handling
            logger.debug("Getting advertising manager interface...")
            ad_manager_obj = bus.get_object('org.bluez', adapter_path, introspect=False)
            
            # Check if LEAdvertisingManager1 interface is available
            try:
                # Try to introspect to see what's available
                introspect_iface = dbus.Interface(ad_manager_obj, 'org.freedesktop.DBus.Introspectable')
                introspect_data = introspect_iface.Introspect()
                
                if 'LEAdvertisingManager1' not in introspect_data:
                    logger.warning("LEAdvertisingManager1 interface not available on this BlueZ version")
                    logger.info("Skipping D-Bus advertisement - service will still be discoverable via adapter name")
                    # Save that we skipped registration
                    self._advertisement_registered = False
                    return
                    
            except Exception as introspect_error:
                logger.debug(f"Could not introspect advertising manager (this is OK): {introspect_error}")
            
            ad_manager = dbus.Interface(ad_manager_obj, 'org.bluez.LEAdvertisingManager1')
            
            # Unregister any existing advertisements first (cleanup from previous crashes)
            try:
                if hasattr(self, '_advertisement_path') and self._advertisement_path:
                    logger.debug(f"Cleaning up previous advertisement: {self._advertisement_path}")
                    ad_manager.UnregisterAdvertisement(self._advertisement_path, timeout=5)
            except dbus.exceptions.DBusException as e:
                logger.debug(f"No previous advertisement to clean up: {e}")
            except Exception as e:
                logger.debug(f"Error during cleanup: {e}")

            # Register new advertisement with extended timeout
            logger.debug(f"Registering advertisement at {ad_path}")
            # BlueZ RegisterAdvertisement signature: "oa{sv}" (object_path, dict<string,variant>)
            # Must explicitly create a D-Bus dictionary with proper signature to avoid
            # "Unable to guess signature from an empty dict" error
            # Must also use dbus.ObjectPath() to ensure correct signature
            options = dbus.Dictionary({}, signature='sv')
            ad_manager.RegisterAdvertisement(dbus.ObjectPath(advertisement.path), options, timeout=60)

            # Save references for unregister
            self._advertisement_obj = advertisement
            self._advertisement_path = advertisement.path
            self._advertisement_registered = True

            logger.info(f"✓ D-Bus advertisement registered successfully")
            logger.info(f"  Path: {ad_path}")
            logger.info(f"  Name: '{advertising_name}'")
            logger.info(f"  UUID: {self.config.bluetooth.service_uuid}")
            
        except dbus.exceptions.DBusException as e:
            # Log specific D-Bus errors with helpful messages
            error_msg = str(e)
            if 'NoReply' in error_msg:
                logger.debug(f"D-Bus timeout during advertisement registration: {e}")
                logger.info("ℹ️  Advertisement registration timed out (service is still discoverable)")
            elif 'UnknownMethod' in error_msg or 'UnknownInterface' in error_msg:
                logger.debug(f"LEAdvertisingManager1 not supported: {e}")
                logger.info("ℹ️  Advertisement not registered (older BlueZ version - service is still discoverable)")
            elif 'AlreadyExists' in error_msg:
                logger.debug(f"Advertisement already exists: {e}")
                logger.info("ℹ️  Using existing advertisement")
            elif 'NotPermitted' in error_msg or 'AccessDenied' in error_msg:
                logger.warning(f"D-Bus permission denied: {e}")
                logger.info("ℹ️  Ensure user is in 'bluetooth' group: sudo usermod -a -G bluetooth $USER")
            elif 'Failed' in error_msg:
                logger.debug(f"Advertisement registration failed: {e}")
                logger.info("ℹ️  Advertisement not registered (service is still discoverable via GATT)")
            else:
                logger.debug(f"D-Bus advertisement error: {e}")
                logger.info("ℹ️  Advertisement not registered (service is still discoverable)")
        except Exception as e:
            logger.error(f"Unexpected error registering advertisement: {e}")
            raise

    def _unregister_dbus_advertisement(self):
        """Unregister D-Bus advertisement with proper error handling"""
        global DBUS_AVAILABLE  # Ensure we can access the module-level variable
        
        if not DBUS_AVAILABLE:
            return
            
        try:
            bus = dbus.SystemBus(private=False)
            adapter_path = '/org/bluez/hci0'
            ad_manager_obj = bus.get_object('org.bluez', adapter_path, introspect=False)
            ad_manager = dbus.Interface(ad_manager_obj, 'org.bluez.LEAdvertisingManager1')
            
            if hasattr(self, '_advertisement_path') and self._advertisement_path:
                try:
                    ad_manager.UnregisterAdvertisement(self._advertisement_path, timeout=10)
                    logger.info(f"Unregistered advertisement: {self._advertisement_path}")
                except dbus.exceptions.DBusException as e:
                    logger.debug(f"Advertisement may not have been registered or already removed: {e}")
                except Exception as e:
                    logger.debug(f"Error unregistering advertisement: {e}")
                    
            # Clean up D-Bus object
            if hasattr(self, '_advertisement_obj') and self._advertisement_obj:
                try:
                    self._advertisement_obj.remove_from_connection()
                except Exception as e:
                    logger.debug(f"Error removing advertisement object from D-Bus: {e}")
                    
            self._advertisement_registered = False
            
        except Exception as e:
            logger.debug(f"Error during advertisement cleanup: {e}")


# Export main class
__all__ = ['BLEGATTServiceManager', 'BLEServiceError']