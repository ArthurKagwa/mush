"""
BLE GATT Service Management

Main service coordinator for BLE GATT telemetry system.
Manages service creation, characteristics, and coordination.
"""

import logging
import threading
import time
import os
from typing import Optional, Dict, Any, Callable, Set, Tuple
from queue import Queue, Empty, PriorityQueue

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
from .backends import select_backend
from .characteristics.environmental import EnvironmentalMeasurementsCharacteristic
from .characteristics.control_targets import ControlTargetsCharacteristic
from .characteristics.stage_state import StageStateCharacteristic
from .characteristics.stage_thresholds import StageThresholdsCharacteristic
from .characteristics.override_bits import OverrideBitsCharacteristic
from .characteristics.status_flags import StatusFlagsCharacteristic
from .characteristics.uart import UARTRXCharacteristic, UARTTXCharacteristic
from .uuids import UART_SERVICE_UUID
from .characteristics.config_version import ConfigVersionCharacteristic
from .characteristics.config_out import ConfigOutCharacteristic
from .characteristics.config_ctrl import ConfigControlCharacteristic
from .characteristics.config_in import ConfigInCharacteristic

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

        # GLib mainloop (required for BlueZero/D-Bus)
        self._mainloop = None
        self._mainloop_thread = None

        # Non-blocking notification infrastructure (priority-based)
        self._notify_queue: Optional[PriorityQueue] = None
        self._publisher_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._queue_metrics = {
            'dropped': 0,
            'coalesced': 0,
            'published': 0,
            'slow_publishes': 0,
            'critical_published': 0,
            'high_published': 0,
            'medium_published': 0,
            'low_published': 0,
            'critical_dropped': 0,
            'low_dropped': 0
        }
        
        # Priority levels (lower number = higher priority)
        self.PRIORITY_CRITICAL = 0  # env_measurements, actuator_status (never drop)
        self.PRIORITY_HIGH = 1      # status_flags
        self.PRIORITY_MEDIUM = 2    # control_targets, stage_state
        self.PRIORITY_LOW = 3       # stage_thresholds, config updates

        # Load BLE queue related configuration from environment (no hard-coded values)
        self._ble_cfg = self._load_ble_env_config()

        # Backend selection (Milestone 1: null backend placeholder)
        self._backend_name, self._backend = select_backend()

        # In simulation mode we still need characteristic containers for callbacks
        if self.simulation_mode:
            # Build characteristic containers without binding to a real service
            self._build_characteristics(main_service=None, uart_service=None)
        
    def initialize(self) -> bool:
        """Initialize BLE adapter and services.

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
            # Start GLib mainloop in background thread (required for BlueZero/D-Bus)
            if DBUS_AVAILABLE and not self._mainloop_thread:
                self._start_mainloop()

            # Initialize BLE adapter
            self.adapter = adapter.Adapter()
            if not self.adapter.powered:
                self.adapter.powered = True

            # Create peripheral
            self.peripheral = peripheral.Peripheral(self.adapter.address, local_name=self.config.bluetooth.name_prefix)

            # Create GATT services
            self._create_services()

            # Initialize selected backend (no-op for milestone 1)
            try:
                self._backend.initialize()
            except Exception as be:
                logger.debug(f"Backend initialize error (ignored milestone 1): {be}")

            logger.info("BLE GATT services initialized successfully")
            return True

        except KeyboardInterrupt:
            logger.warning("⚠️  BLE initialization interrupted by user")
            return False
        except Exception as e:
            logger.error(f"Failed to initialize BLE GATT service: {e}")
            return False
    
    def _start_mainloop(self):
        """Start GLib mainloop in background thread
        
        BlueZero requires the GLib mainloop to process D-Bus messages.
        Without this, peripheral.publish() and other D-Bus calls will block indefinitely.
        """
        if not DBUS_AVAILABLE:
            return
            
        try:
            # Initialize D-Bus mainloop
            dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
            
            # Create GLib mainloop
            self._mainloop = GLib.MainLoop()
            
            # Start mainloop in background thread
            def run_mainloop():
                try:
                    logger.info("🔄 GLib mainloop started in background")
                    self._mainloop.run()
                    logger.info("🔄 GLib mainloop stopped")
                except Exception as e:
                    logger.error(f"GLib mainloop error: {e}")
            
            self._mainloop_thread = threading.Thread(target=run_mainloop, daemon=True, name="GLibMainLoop")
            self._mainloop_thread.start()
            
            # Give mainloop a moment to start
            time.sleep(0.5)
            
            logger.info("✓ GLib mainloop initialized")
        except Exception as e:
            logger.warning(f"Could not start GLib mainloop: {e}")
    
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

            # Initialize characteristics with default values to prevent empty initial notifications
            self._initialize_characteristic_values()

            # Count successfully created characteristics
            char_count = len(self.characteristics)
            logger.info(f"BLE GATT services ready with {char_count} characteristics")
            
            # CRITICAL: Publish the GATT server to BlueZ so services become discoverable
            # NOTE: This call can block for several minutes if BlueZ's advertisement registration hangs
            # We run it in a background thread with a configurable timeout to avoid blocking startup
            gatt_publish_timeout_sec = max(1, int(self._ble_cfg.get('gatt_publish_timeout_sec', 10)))
            logger.info(f"Publishing GATT server to BlueZ (timeout: {gatt_publish_timeout_sec}s)...")
            
            publish_success = False
            publish_thread = None
            
            def publish_in_thread():
                nonlocal publish_success
                try:
                    self.peripheral.publish()
                    publish_success = True
                except Exception as e:
                    logger.debug(f"Publish thread error: {e}")
            
            try:
                # Run publish in background thread with timeout
                publish_thread = threading.Thread(target=publish_in_thread, daemon=True)
                publish_thread.start()
                publish_thread.join(timeout=gatt_publish_timeout_sec)  # Wait up to configured seconds
                
                if publish_thread.is_alive():
                    # Thread still running after timeout - publish is hanging
                    logger.warning(f"⚠️  GATT server publish timed out after {gatt_publish_timeout_sec}s")
                    logger.info("ℹ️  This is likely due to BlueZ advertisement registration blocking")
                    logger.info("ℹ️  Services may still be discoverable via adapter configuration")
                    # Thread will continue in background but we don't wait for it
                elif publish_success:
                    logger.info("✓ GATT server published - services now discoverable")
                else:
                    logger.warning("⚠️  GATT server publish failed")
                    logger.info("ℹ️  Continuing anyway - adapter is configured and discoverable")
                
                # NOTE: BlueZ may print "Failed to register advertisement" to stderr during publish()
                # This is a known BlueZ behavior and can be safely ignored - it refers to BlueZ's
                # internal LE advertisement mechanism, not the GATT server itself. The GATT server
                # is successfully registered and fully functional. Clients can discover services
                # via standard GATT service discovery regardless of this message.
                
            except KeyboardInterrupt:
                # User pressed Ctrl+C during publish - re-raise to allow clean shutdown
                logger.warning("⚠️  Service initialization interrupted by user")
                raise
            except Exception as e:
                # Publish failed but we can continue - adapter is configured and services are created
                logger.warning(f"⚠️  Error during GATT server publish: {e}")
                logger.info("ℹ️  Continuing anyway - adapter is configured and discoverable")
            
            # Initialize notification worker AFTER publish attempt (so peripheral exists)
            try:
                self._init_notification_worker()
            except Exception as e:
                logger.warning(f"Could not start BLE notification worker (continuing): {e}")

        except KeyboardInterrupt:
            # Re-raise KeyboardInterrupt to allow main program to handle shutdown
            raise
        except Exception as e:
            logger.error(f"Failed to create BLE GATT services: {e}")
            raise BLEServiceError(f"Failed to create services: {e}")
    
    def _build_characteristics(self, main_service, uart_service):
        """Instantiate all BLE characteristics against the provided services"""
        try:
            # Base set of characteristics (backward-compatible set)
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
                'stage_thresholds': StageThresholdsCharacteristic(
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
                ),
                # Config service extension (shares primary service)
                'config_version': ConfigVersionCharacteristic(
                    main_service, self.simulation_mode
                ),
                'config_out': ConfigOutCharacteristic(
                    main_service, self.simulation_mode
                )
            }

            # Control + In depend on out + version
            try:
                self.characteristics['config_ctrl'] = ConfigControlCharacteristic(
                    main_service, self.simulation_mode,
                    out_char=self.characteristics['config_out'],
                    version_char=self.characteristics['config_version']
                )
                self.characteristics['config_in'] = ConfigInCharacteristic(
                    main_service, self.simulation_mode,
                    ctrl_char=self.characteristics['config_ctrl'],
                    out_char=self.characteristics['config_out']
                )
            except Exception as e:
                logger.warning(f"Failed to initialize config characteristics: {e}")

            # Optional: actuator status characteristic (feature-gated)
            try:
                if bool(self._ble_cfg.get('actuator_status_enable', False)):
                    # Import only when enabled to avoid unintended side effects
                    from .characteristics.actuator_status import ActuatorStatusCharacteristic
                    self.characteristics['actuator_status'] = ActuatorStatusCharacteristic(
                        main_service, self.simulation_mode
                    )
                    logger.info("Actuator status characteristic enabled via env flag")
                else:
                    logger.debug("Actuator status characteristic disabled (back-compat)")
            except Exception as e:
                logger.warning(f"Could not initialize actuator status characteristic: {e}")

            logger.debug(
                "BLE characteristics created (simulation=%s, main_service_bound=%s, uart_service_bound=%s)",
                self.simulation_mode,
                main_service is not None,
                uart_service is not None
            )

        except Exception as e:
            logger.error(f"Failed to create characteristics: {e}")
            raise BLEServiceError(f"Failed to create characteristics: {e}")
    
    def _initialize_characteristic_values(self):
        """Initialize characteristics with default zero values
        
        This ensures that when clients first subscribe to notifications,
        they receive valid data packets instead of empty arrays.
        """
        try:
            # Initialize environmental measurements with zeros
            env_char = self.characteristics.get('env_measurements')
            if env_char:
                env_char.update_data(
                    temp=0.0,
                    rh=0.0,
                    co2=0,
                    light=0,
                    start_time=time.time()
                )
                logger.debug("✓ Environmental characteristic initialized with zero values")
            
            # Status flags already initialize with proper values in __init__
            status_char = self.characteristics.get('status_flags')
            if status_char:
                logger.debug(f"✓ Status flags initialized: 0x{int(status_char.status_flags):04X}")
            
        except Exception as e:
            logger.warning(f"Could not initialize characteristic values: {e}")
    
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
            # If this fails, the service will still be discoverable via standard GATT service discovery
            if DBUS_AVAILABLE:
                try:
                    # Optional stabilization delay after powering adapter/discoverable
                    stab_delay_ms = int(self._ble_cfg.get('adv_stabilization_delay_ms', 0))
                    if stab_delay_ms > 0:
                        logger.debug(f"Waiting {stab_delay_ms}ms for adapter stabilization before advertisement registration")
                        time.sleep(stab_delay_ms / 1000.0)

                    # Retry registration with backoff as configured
                    retries = max(0, int(self._ble_cfg.get('adv_register_retries', 0)))
                    backoff_base = max(0, int(self._ble_cfg.get('adv_backoff_base_ms', 0)))
                    backoff_max = max(backoff_base, int(self._ble_cfg.get('adv_backoff_max_ms', backoff_base)))

                    attempt = 0
                    while True:
                        success = self._register_dbus_advertisement(advertising_name)
                        if success:
                            break
                        if attempt >= retries:
                            logger.info("ℹ️  D-Bus advertisement not registered after retries (service still discoverable)")
                            break
                        # backoff with simple exponential growth capped at max
                        delay_ms = min(backoff_max, backoff_base * (2 ** attempt) if backoff_base > 0 else 0)
                        attempt += 1
                        if delay_ms > 0:
                            logger.debug(f"Retrying advertisement registration in {delay_ms}ms (attempt {attempt}/{retries})")
                            time.sleep(delay_ms / 1000.0)
                except dbus.exceptions.DBusException as e:
                    # Advertisement registration can fail if already registered or BlueZ busy
                    # This is OK - GATT server is published, service discovery will work fine
                    logger.info("ℹ️  D-Bus advertisement not registered (not critical)")
                    logger.info("ℹ️  BLE service is still fully functional - clients can discover via GATT")
                    logger.debug(f"D-Bus advertisement error: {e}")
                except Exception as e:
                    logger.info("ℹ️  D-Bus advertisement failed (continuing anyway)")
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
        # Signal worker stop early
        self._stop_event.set()
        
        if self.simulation_mode:
            logger.info("BLE GATT service stopped (simulation mode)")
            return
            
        try:
            # Stop publisher thread
            if self._publisher_thread and self._publisher_thread.is_alive():
                timeout_sec = self._ble_cfg['shutdown_timeout_ms'] / 1000.0
                logger.info("Stopping BLE notification worker...")
                self._publisher_thread.join(timeout=timeout_sec)
                if self._publisher_thread.is_alive():
                    logger.warning("BLE notification worker did not stop within timeout")
                else:
                    logger.info("BLE notification worker stopped")
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
            
            # Stop GLib mainloop
            if self._mainloop and self._mainloop.is_running():
                logger.info("Stopping GLib mainloop...")
                self._mainloop.quit()
                if self._mainloop_thread and self._mainloop_thread.is_alive():
                    self._mainloop_thread.join(timeout=2)
                    
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
            
            # Control targets callbacks - use get_control_targets for thresholds
            control_char = self.characteristics.get('control_targets')
            if control_char:
                # Prefer get_control_targets if available, fallback to get_control_data
                get_callback = callbacks.get('get_control_targets') or callbacks.get('get_control_data')
                set_callback = callbacks.get('set_control_targets')
                if get_callback and set_callback:
                    control_char.set_control_callbacks(get_callback, set_callback)

            # Actuator status uses the control data getter to compute bits
            actuator_char = self.characteristics.get('actuator_status')
            if actuator_char and 'get_control_data' in callbacks:
                actuator_char.set_control_callback(callbacks['get_control_data'])
            
            # Stage state callbacks
            stage_char = self.characteristics.get('stage_state')
            if stage_char and 'get_stage_data' in callbacks and 'set_stage_state' in callbacks:
                stage_char.set_stage_callbacks(
                    callbacks['get_stage_data'],
                    callbacks['set_stage_state']
                )
            
            # Stage thresholds callbacks
            stage_thresh_char = self.characteristics.get('stage_thresholds')
            if stage_thresh_char and 'get_stage_thresholds' in callbacks and 'set_stage_thresholds' in callbacks:
                stage_thresh_char.set_stage_thresholds_callbacks(
                    callbacks['get_stage_thresholds'],
                    callbacks['set_stage_thresholds']
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
                    # Enqueue notification task (characteristic name + snapshot of devices)
                    self._enqueue_notification('env_measurements', connected_devices)
        except Exception as e:
            logger.error(f"Error queuing environmental data notification: {e}")
    
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
                    self._enqueue_notification('status_flags', connected_devices)
        except Exception as e:
            logger.error(f"Error queuing status flags notification: {e}")

    def notify_actuator_status(self, connected_devices: Set[str]):
        """Notify clients with current actuator status bits"""
        try:
            actuator_char = self.characteristics.get('actuator_status')
            if actuator_char:
                if connected_devices:
                    self._enqueue_notification('actuator_status', connected_devices)
        except Exception as e:
            logger.error(f"Error queuing actuator status notification: {e}")
    
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

        # Log queue metrics if worker active
        if self._notify_queue is not None:
            logger.info(f"📊 Queue: {self._notify_queue.qsize()}/{self._ble_cfg['queue_max_size']} | "
                       f"Published: {self._queue_metrics['published']} "
                       f"(C:{self._queue_metrics['critical_published']} "
                       f"H:{self._queue_metrics['high_published']} "
                       f"M:{self._queue_metrics['medium_published']} "
                       f"L:{self._queue_metrics['low_published']}) | "
                       f"Dropped: {self._queue_metrics['dropped']} "
                       f"(C:{self._queue_metrics['critical_dropped']} "
                       f"L:{self._queue_metrics['low_dropped']}) | "
                       f"Slow: {self._queue_metrics['slow_publishes']}")


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
                    # Keep advertisement payload minimal to avoid BlueZ size errors (0xea):
                    # - Advertise ONLY the primary 128-bit service UUID
                    # - Rely on adapter alias for device name (omit LocalName here)
                    # - Do not include optional fields like tx-power
                    return {
                        'org.bluez.LEAdvertisement1': {
                            'Type': dbus.String(self.ad_type),
                            'ServiceUUIDs': dbus.Array([
                                dbus.String(str(self.config.bluetooth.service_uuid))
                            ], signature='s')
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

            # Register new advertisement with short timeout to avoid blocking startup
            logger.debug(f"Registering advertisement at {ad_path}")
            # BlueZ RegisterAdvertisement signature: "oa{sv}" (object_path, dict<string,variant>)
            # Must explicitly create a D-Bus dictionary with proper signature to avoid
            # "Unable to guess signature from an empty dict" error
            # Must also use dbus.ObjectPath() to ensure correct signature
            # Use 5-second timeout instead of 60 to avoid blocking startup
            options = dbus.Dictionary({}, signature='sv')
            ad_manager.RegisterAdvertisement(dbus.ObjectPath(advertisement.path), options, timeout=5)

            # Save references for unregister
            self._advertisement_obj = advertisement
            self._advertisement_path = advertisement.path
            self._advertisement_registered = True

            logger.info(f"✓ D-Bus advertisement registered successfully")
            logger.info(f"  Path: {ad_path}")
            logger.info(f"  Name: '{advertising_name}'")
            logger.info(f"  UUID: {self.config.bluetooth.service_uuid}")
            return True
            
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
            return False
        except Exception as e:
            logger.error(f"Unexpected error registering advertisement: {e}")
            return False

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

    # ----------------------- Non-blocking notification worker -----------------------
    def _load_ble_env_config(self) -> Dict[str, int | str | bool]:
        """Load BLE notification related configuration from environment variables.

        Returns:
            Dict of configuration values (all validated/fallback to defaults)
        """
        def _get_int(name: str, default: int) -> int:
            val = os.environ.get(name, str(default))
            try:
                return int(val)
            except ValueError:
                logger.warning(f"Invalid int for {name}={val}; using default {default}")
                return default

        def _get_str(name: str, default: str, allowed: Optional[Set[str]] = None) -> str:
            val = os.environ.get(name, default)
            if allowed and val not in allowed:
                logger.warning(f"Invalid value for {name}={val}; allowed={allowed}; using {default}")
                return default
            return val

        def _get_bool(name: str, default: bool) -> bool:
            val = os.environ.get(name, str(default))
            return str(val).lower() in ('true', '1', 'yes', 'on')

        return {
            'queue_max_size': _get_int('MUSHPI_BLE_QUEUE_MAX_SIZE', 16),
            'queue_put_timeout_ms': _get_int('MUSHPI_BLE_QUEUE_PUT_TIMEOUT_MS', 10),
            'backpressure_policy': _get_str('MUSHPI_BLE_BACKPRESSURE_POLICY', 'priority', {'drop_oldest', 'drop_newest', 'coalesce', 'priority'}),
            'publish_timeout_ms': _get_int('MUSHPI_BLE_PUBLISH_TIMEOUT_MS', 2000),
            'publish_max_retries': _get_int('MUSHPI_BLE_PUBLISH_MAX_RETRIES', 2),
            'publish_backoff_base_ms': _get_int('MUSHPI_BLE_PUBLISH_BACKOFF_BASE_MS', 100),
            'publish_backoff_max_ms': _get_int('MUSHPI_BLE_PUBLISH_BACKOFF_MAX_MS', 1000),
            'log_slow_publish_ms': _get_int('MUSHPI_BLE_LOG_SLOW_PUBLISH_MS', 250),
            'shutdown_timeout_ms': _get_int('MUSHPI_BLE_SHUTDOWN_TIMEOUT_MS', 1500),
            'worker_restart': _get_bool('MUSHPI_BLE_WORKER_RESTART', False),
            # New: GATT publish and advertisement controls
            'gatt_publish_timeout_sec': _get_int('MUSHPI_BLE_GATT_PUBLISH_TIMEOUT_SEC', 10),
            'adv_stabilization_delay_ms': _get_int('MUSHPI_BLE_ADV_STABILIZATION_DELAY_MS', 0),
            'adv_register_retries': _get_int('MUSHPI_BLE_ADV_REGISTER_RETRIES', 0),
            'adv_backoff_base_ms': _get_int('MUSHPI_BLE_ADV_REGISTER_BACKOFF_MS', 0),
            'adv_backoff_max_ms': _get_int('MUSHPI_BLE_ADV_REGISTER_BACKOFF_MAX_MS', 0),
            # Feature gates
            'actuator_status_enable': _get_bool('MUSHPI_BLE_ACTUATOR_STATUS_ENABLE', True),  # Enabled by default for real-time relay states
        }

    def _init_notification_worker(self):
        """Initialize priority queue and start publisher worker thread"""
        if self.simulation_mode:
            logger.debug("Skipping notification worker init (simulation mode)")
            return
        if self._notify_queue is None:
            self._notify_queue = PriorityQueue(maxsize=self._ble_cfg['queue_max_size'])
        if self._publisher_thread and self._publisher_thread.is_alive():
            return

        def _worker():
            logger.info("BLE notification worker started with priority queue")
            while not self._stop_event.is_set():
                try:
                    item = self._notify_queue.get(timeout=0.25)
                except Empty:
                    continue
                try:
                    priority, timestamp, char_name, devices_snapshot = item
                    start_ts = time.time()
                    self._process_notification(char_name, devices_snapshot)
                    duration_ms = int((time.time() - start_ts) * 1000)
                    
                    # Update priority-specific metrics
                    if priority == self.PRIORITY_CRITICAL:
                        self._queue_metrics['critical_published'] += 1
                    elif priority == self.PRIORITY_HIGH:
                        self._queue_metrics['high_published'] += 1
                    elif priority == self.PRIORITY_MEDIUM:
                        self._queue_metrics['medium_published'] += 1
                    else:
                        self._queue_metrics['low_published'] += 1
                    
                    if duration_ms > self._ble_cfg['log_slow_publish_ms']:
                        self._queue_metrics['slow_publishes'] += 1
                        logger.warning(f"Slow BLE publish: {duration_ms}ms for {char_name} (P{priority})")
                    
                    self._queue_metrics['published'] += 1
                    
                    # Log queue status on every notification
                    self._log_queue_status(char_name, priority, duration_ms)
                    
                except Exception as e:
                    logger.error(f"Worker error processing notification: {e}")
                finally:
                    self._notify_queue.task_done()
            logger.info("BLE notification worker exiting")

        self._publisher_thread = threading.Thread(target=_worker, name="BLEPublisher", daemon=True)
        self._publisher_thread.start()

    def _get_priority(self, char_name: str) -> int:
        """Get priority level for a characteristic
        
        Args:
            char_name: Name of the characteristic
            
        Returns:
            Priority level (0=critical, 3=low)
        """
        if char_name in ('env_measurements', 'actuator_status'):
            return self.PRIORITY_CRITICAL
        elif char_name == 'status_flags':
            return self.PRIORITY_HIGH
        elif char_name in ('control_targets', 'stage_state'):
            return self.PRIORITY_MEDIUM
        else:
            return self.PRIORITY_LOW
    
    def _enqueue_notification(self, char_name: str, devices: Set[str]):
        """Enqueue a notification task with priority-based backpressure handling.

        Args:
            char_name: characteristic key in self.characteristics
            devices: set of connected device addresses
        """
        if self.simulation_mode:
            return
        if not self._notify_queue:
            return
        
        priority = self._get_priority(char_name)
        timestamp = time.time()
        task: Tuple[int, float, str, Set[str]] = (priority, timestamp, char_name, set(devices))
        
        try:
            self._notify_queue.put(task, timeout=self._ble_cfg['queue_put_timeout_ms']/1000.0)
        except Exception:
            # Queue full or put timeout: apply backpressure policy
            policy = self._ble_cfg['backpressure_policy']
            
            if policy == 'priority':
                # Priority-based dropping: remove lowest priority item if current is higher priority
                try:
                    # Peek at queue to find lowest priority item
                    # For PriorityQueue, we need to rebuild without lowest priority items
                    temp_items = []
                    lowest_priority_found = False
                    
                    # Extract all items
                    while not self._notify_queue.empty():
                        try:
                            item = self._notify_queue.get_nowait()
                            temp_items.append(item)
                            self._notify_queue.task_done()
                        except Empty:
                            break
                    
                    # Find and drop lowest priority item (highest number) if current is higher priority
                    if temp_items:
                        temp_items.sort(key=lambda x: x[0])  # Sort by priority
                        lowest_item = temp_items[-1]  # Highest priority number = lowest priority
                        
                        if priority < lowest_item[0]:  # Current is higher priority
                            # Drop lowest priority item
                            temp_items = temp_items[:-1]
                            lowest_priority_found = True
                            self._queue_metrics['dropped'] += 1
                            if lowest_item[0] == self.PRIORITY_LOW:
                                self._queue_metrics['low_dropped'] += 1
                            logger.info(f"🗑️  Dropped {lowest_item[2]} (P{lowest_item[0]}) for {char_name} (P{priority})")
                        else:
                            # Current item is low priority, drop it instead
                            self._queue_metrics['dropped'] += 1
                            if priority == self.PRIORITY_CRITICAL:
                                self._queue_metrics['critical_dropped'] += 1
                                logger.warning(f"⚠️  CRITICAL item dropped: {char_name}")
                            elif priority == self.PRIORITY_LOW:
                                self._queue_metrics['low_dropped'] += 1
                            logger.debug(f"Dropped incoming {char_name} (P{priority}) - queue full with higher priority items")
                            # Put items back and return
                            for item in temp_items:
                                try:
                                    self._notify_queue.put_nowait(item)
                                except:
                                    pass
                            return
                    
                    # Put items back
                    for item in temp_items:
                        try:
                            self._notify_queue.put_nowait(item)
                        except:
                            pass
                    
                    # Try to enqueue current item
                    if lowest_priority_found:
                        try:
                            self._notify_queue.put(task, timeout=0.01)
                            logger.debug(f"✅ Enqueued {char_name} (P{priority}) after dropping low priority item")
                        except:
                            self._queue_metrics['dropped'] += 1
                            logger.debug(f"Failed to enqueue {char_name} after priority drop")
                            
                except Exception as e:
                    self._queue_metrics['dropped'] += 1
                    logger.debug(f"Priority backpressure error: {e}")
                    
            elif policy == 'drop_newest':
                self._queue_metrics['dropped'] += 1
                logger.debug(f"Drop newest notification ({char_name}) queue full")
                return
            elif policy == 'drop_oldest':
                try:
                    oldest = self._notify_queue.get_nowait()
                    self._notify_queue.task_done()
                    self._queue_metrics['dropped'] += 1
                    logger.debug("Dropped oldest notification to make room")
                except Empty:
                    logger.debug("Queue empty unexpectedly during drop_oldest policy")
                try:
                    self._notify_queue.put(task, timeout=0.01)
                except Exception:
                    self._queue_metrics['dropped'] += 1
                    logger.debug("Still could not enqueue after dropping oldest")
            elif policy == 'coalesce':
                # Simple coalesce: if same char already queued, skip adding new
                # (Note: Queue lacks direct iteration removal; implement by counting skip)
                self._queue_metrics['coalesced'] += 1
                logger.debug(f"Coalesced notification for {char_name} (queue full)")
            else:
                self._queue_metrics['dropped'] += 1
                logger.debug(f"Unknown backpressure policy {policy}; dropped newest")

    def _log_queue_status(self, char_name: str, priority: int, duration_ms: int):
        """Log queue status on every notification
        
        Args:
            char_name: Name of the characteristic that was published
            priority: Priority level of the published item
            duration_ms: Time taken to publish in milliseconds
        """
        try:
            queue_size = self._notify_queue.qsize()
            queue_max = self._ble_cfg['queue_max_size']
            queue_pct = int((queue_size / queue_max) * 100) if queue_max > 0 else 0
            
            # Priority names for logging
            priority_names = {
                self.PRIORITY_CRITICAL: 'CRITICAL',
                self.PRIORITY_HIGH: 'HIGH',
                self.PRIORITY_MEDIUM: 'MEDIUM',
                self.PRIORITY_LOW: 'LOW'
            }
            priority_name = priority_names.get(priority, f'P{priority}')
            
            # Build status message
            status = (
                f"📡 BLE: {char_name} ({priority_name}) sent in {duration_ms}ms | "
                f"Queue: {queue_size}/{queue_max} ({queue_pct}%) | "
                f"Total: {self._queue_metrics['published']} "
                f"[C:{self._queue_metrics['critical_published']} "
                f"H:{self._queue_metrics['high_published']} "
                f"M:{self._queue_metrics['medium_published']} "
                f"L:{self._queue_metrics['low_published']}] | "
                f"Dropped: {self._queue_metrics['dropped']} "
                f"[C:{self._queue_metrics['critical_dropped']} "
                f"L:{self._queue_metrics['low_dropped']}]"
            )
            
            # Log at appropriate level based on queue fullness
            if queue_pct > 80:
                logger.warning(status + " ⚠️ QUEUE NEARLY FULL")
            elif queue_pct > 50:
                logger.info(status + " ⚠️")
            else:
                logger.info(status)
                
        except Exception as e:
            logger.debug(f"Error logging queue status: {e}")
    
    def _process_notification(self, char_name: str, devices: Set[str]):
        """Process a single queued notification task"""
        char = self.characteristics.get(char_name)
        if not char or not devices:
            return
        try:
            # For BlueZero peripheral API, updating characteristic value triggers notify
            # Here we call characteristic-specific notify_update if it exists for consistency
            if hasattr(char, 'notify_update'):
                char.notify_update(devices)
            else:
                logger.debug(f"Characteristic {char_name} lacks notify_update method")
        except Exception as e:
            logger.error(f"Error notifying {char_name}: {e}")



# Export main class
__all__ = ['BLEGATTServiceManager', 'BLEServiceError']