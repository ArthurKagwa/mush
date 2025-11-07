#!/usr/bin/env python3
"""
Test BLE Advertisement Registration
Quick test to verify D-Bus advertisement works with new timeout settings
"""

import sys
import time
import logging

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

try:
    import dbus
    import dbus.mainloop.glib
    from gi.repository import GLib
    DBUS_AVAILABLE = True
except ImportError as e:
    logger.error(f"Required libraries not available: {e}")
    logger.error("Install with: sudo apt-get install python3-dbus python3-gi")
    sys.exit(1)


def test_advertisement_registration():
    """Test D-Bus advertisement registration with timeout handling"""
    
    logger.info("Starting BLE advertisement registration test...")
    
    try:
        # Initialize D-Bus mainloop
        logger.debug("Initializing D-Bus mainloop...")
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        
        # Connect to system bus
        logger.debug("Connecting to system bus...")
        bus = dbus.SystemBus(private=False)
        
        # Get adapter
        adapter_path = '/org/bluez/hci0'
        logger.debug(f"Getting adapter at {adapter_path}...")
        
        # Test advertisement path
        test_path = f'/uk/co/mushpi/test_advertisement_{int(time.time())}'
        logger.debug(f"Using test advertisement path: {test_path}")
        
        # Create minimal advertisement class
        class TestAdvertisement(dbus.service.Object):
            def __init__(self, bus, path):
                self.path = path
                dbus.service.Object.__init__(self, bus, self.path)
                
            def get_properties(self):
                return {
                    'org.bluez.LEAdvertisement1': {
                        'Type': dbus.String('peripheral'),
                        'ServiceUUIDs': dbus.Array(
                            [dbus.String('12345678-1234-5678-1234-56789abcdef0')],
                            signature='s'
                        ),
                        'LocalName': dbus.String('MushPi-Test'),
                        'Includes': dbus.Array([dbus.String('tx-power')], signature='s')
                    }
                }
            
            @dbus.service.method('org.freedesktop.DBus.Properties', 
                               in_signature='s', out_signature='a{sv}')
            def GetAll(self, interface):
                props = self.get_properties()
                return props.get(interface, {})
            
            @dbus.service.method('org.bluez.LEAdvertisement1', 
                               in_signature='', out_signature='')
            def Release(self):
                logger.info('Test advertisement released by BlueZ')
        
        # Create advertisement
        logger.debug("Creating test advertisement object...")
        advertisement = TestAdvertisement(bus, test_path)
        
        # Get advertising manager
        logger.debug("Getting advertising manager interface...")
        ad_manager_obj = bus.get_object('org.bluez', adapter_path, introspect=False)
        ad_manager = dbus.Interface(ad_manager_obj, 'org.bluez.LEAdvertisingManager1')
        
        # Register advertisement with timeout
        logger.info("Registering advertisement with 60-second timeout...")
        start_time = time.time()
        
        try:
            ad_manager.RegisterAdvertisement(
                advertisement.path,
                dbus.Dictionary({}, signature='sv'),  # Empty options with proper signature
                timeout=60  # 60 second timeout
            )
            elapsed = time.time() - start_time
            logger.info(f"✓ Advertisement registered successfully in {elapsed:.2f} seconds!")
            
            # Wait a moment
            logger.info("Waiting 3 seconds before cleanup...")
            time.sleep(3)
            
            # Unregister
            logger.info("Unregistering advertisement...")
            ad_manager.UnregisterAdvertisement(advertisement.path, timeout=10)
            logger.info("✓ Advertisement unregistered successfully!")
            
            # Clean up
            advertisement.remove_from_connection()
            
            logger.info("=" * 60)
            logger.info("SUCCESS: D-Bus advertisement registration works correctly!")
            logger.info("=" * 60)
            return True
            
        except dbus.exceptions.DBusException as e:
            elapsed = time.time() - start_time
            error_msg = str(e)
            
            logger.error(f"✗ D-Bus exception after {elapsed:.2f} seconds: {e}")
            
            if 'NoReply' in error_msg:
                logger.error("")
                logger.error("This is the TIMEOUT error that the fix addresses.")
                logger.error("Possible causes:")
                logger.error("  1. BlueZ daemon is slow/overloaded")
                logger.error("  2. Bluetooth adapter not ready")
                logger.error("  3. D-Bus permissions issue")
                logger.error("")
                logger.error("Try:")
                logger.error("  sudo systemctl restart bluetooth")
                logger.error("  sudo hciconfig hci0 up")
                logger.error("  sudo usermod -a -G bluetooth $USER")
            elif 'NotPermitted' in error_msg or 'AccessDenied' in error_msg:
                logger.error("")
                logger.error("Permission denied. Add user to bluetooth group:")
                logger.error("  sudo usermod -a -G bluetooth $USER")
                logger.error("Then log out and back in.")
            elif 'AlreadyExists' in error_msg:
                logger.warning("")
                logger.warning("Advertisement path already exists. This is usually okay.")
                logger.warning("The code now uses unique paths to avoid this.")
            
            return False
            
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return False


if __name__ == '__main__':
    logger.info("MushPi BLE Advertisement Test")
    logger.info("=" * 60)
    
    # Check if we're on a system with Bluetooth
    try:
        import subprocess
        result = subprocess.run(['hciconfig', 'hci0'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode != 0:
            logger.warning("hci0 adapter may not be available")
            logger.warning("Ensure Bluetooth is enabled: sudo hciconfig hci0 up")
    except Exception as e:
        logger.warning(f"Could not check hci0 status: {e}")
    
    # Run test
    success = test_advertisement_registration()
    
    sys.exit(0 if success else 1)
