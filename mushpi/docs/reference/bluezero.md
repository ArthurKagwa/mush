# BlueZero BLE GATT Service Troubleshooting

## Date: 2025-11-09

### Issue Summary
The BLE GATT service was failing to initialize with characteristic creation errors. After fixing two critical issues, the service now starts successfully.

---

## Error 1: Service Missing Required Attributes

### Error Message
```
2025-11-09 20:35:15 - app.ble.service - ERROR - Failed to create characteristics: Service must have .peripheral and .srv_id attributes
2025-11-09 20:35:15 - app.ble.service - ERROR - Failed to create BLE GATT services: Failed to create characteristics: Service must have .peripheral and .srv_id attributes
2025-11-09 20:35:15 - app.ble.service - ERROR - Failed to initialize BLE GATT service: Failed to create services: Failed to create characteristics: Service must have .peripheral and .srv_id attributes
```

### Root Cause
The code was mixing two different BlueZero APIs:
- Service creation was using the old `localGATT.Service()` API
- Characteristics expected the newer `peripheral` API with `.peripheral` and `.srv_id` attributes
- `localGATT.Service` objects don't have these required attributes

### Location
File: `app/ble/service.py`, method `_create_services()`

### Solution
Changed service creation to use the modern `peripheral.add_service()` API and created a `ServiceWrapper` class:

```python
# Before (BROKEN):
self.service = localGATT.Service(
    1,  # Service ID
    self.config.bluetooth.service_uuid,
    True  # Primary service
)

# After (WORKING):
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
```

### Key Insight
The `BaseCharacteristic` class in `app/ble/base.py` checks for these attributes:
```python
if not hasattr(self.service, "peripheral") or not hasattr(self.service, "srv_id"):
    raise CharacteristicError("Service must have .peripheral and .srv_id attributes")
```

The `ServiceWrapper` provides exactly what characteristics need to call `peripheral.add_characteristic()`.

---

## Error 2: Incorrect Characteristic Constructor Arguments

### Error Message
```
2025-11-09 20:41:36 - app.ble.service - ERROR - Failed to create characteristics: WriteOnlyCharacteristic.__init__() takes from 2 to 4 positional arguments but 5 were given
2025-11-09 20:41:36 - app.ble.service - ERROR - Failed to create BLE GATT services: Failed to create characteristics: WriteOnlyCharacteristic.__init__() takes from 2 to 4 positional arguments but 5 were given
```

### Root Cause
The UART characteristics were trying to pass custom properties lists to specialized characteristic classes that don't accept them:
- `WriteOnlyCharacteristic` hardcodes `["write"]` properties
- `NotifyCharacteristic` hardcodes `["read", "notify"]` properties
- UART RX needs `["write", "write-without-response"]`
- UART TX needs `["read", "notify"]`

### Location
File: `app/ble/characteristics/uart.py`

### Solution
Changed UART characteristics to inherit directly from `BaseCharacteristic` instead of the specialized classes:

```python
# Before (BROKEN):
class UARTRXCharacteristic(WriteOnlyCharacteristic):
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_RX_CHAR_UUID, ["write", "write-without-response"], service, simulation_mode)
        # This passes 5 args but WriteOnlyCharacteristic only takes 4!

# After (WORKING):
class UARTRXCharacteristic(BaseCharacteristic):
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_RX_CHAR_UUID, ["write", "write-without-response"], service, simulation_mode)
        self.write_callback = None
    
    def _handle_read(self, options: dict) -> bytes:
        # Must implement _handle_read() when inheriting BaseCharacteristic
        logger.debug("UART RX read attempted (write-only characteristic)")
        return b''
```

Similar change for `UARTTXCharacteristic`:
```python
# Before (BROKEN):
class UARTTXCharacteristic(NotifyCharacteristic):
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_TX_CHAR_UUID, ["notify"], service, simulation_mode)

# After (WORKING):
class UARTTXCharacteristic(BaseCharacteristic):
    def __init__(self, service, simulation_mode=False):
        super().__init__(UART_TX_CHAR_UUID, ["read", "notify"], service, simulation_mode)
```

### Key Insight
When characteristics need custom properties beyond what the specialized classes provide, inherit directly from `BaseCharacteristic` and pass the custom properties list. Must also implement the abstract `_handle_read()` method.

---

## Successful Initialization Log

After both fixes, the service initialized successfully:

```
2025-11-09 21:04:33 - app.ble.service - INFO - BLE GATT services initialized successfully
2025-11-09 21:04:33 - app.ble.service - INFO -   ✓ Set adapter.Pairable = False
2025-11-09 21:04:33 - app.ble.service - INFO -   ✓ Set adapter.DiscoverableTimeout = 0
2025-11-09 21:04:33 - app.ble.service - INFO - BLE adapter configured for connectionless operation (no pairing)
2025-11-09 21:04:33 - app.ble.service - INFO - ✓ BLE pairing/bonding disabled
2025-11-09 21:05:23 - app.ble.service - INFO - ✓ D-Bus advertisement registered successfully
2025-11-09 21:05:23 - app.ble.service - INFO -   Path: /uk/co/mushpi/advertisement1762711473
2025-11-09 21:05:23 - app.ble.service - INFO -   Name: 'MushPi-Init'
2025-11-09 21:05:23 - app.ble.service - INFO -   UUID: 12345678-1234-5678-1234-56789abcdef0
2025-11-09 21:05:23 - app.ble.service - INFO - BLE GATT service started - advertising as 'MushPi-Init'
2025-11-09 21:05:23 - app.ble.service - INFO - ============================================================
2025-11-09 21:05:23 - app.ble.service - INFO - BLE Advertisement Status
2025-11-09 21:05:23 - app.ble.service - INFO - ============================================================
2025-11-09 21:05:23 - app.ble.service - INFO - Service Running:        True
2025-11-09 21:05:23 - app.ble.service - INFO - Simulation Mode:        False
2025-11-09 21:05:23 - app.ble.service - INFO - Advertising Name:       MushPi-Init
2025-11-09 21:05:23 - app.ble.service - INFO - Service UUID:           12345678-1234-5678-1234-56789abcdef0
2025-11-09 21:05:23 - app.ble.service - INFO - Adapter Powered:        1
2025-11-09 21:05:23 - app.ble.service - INFO - Adapter Discoverable:   1
2025-11-09 21:05:23 - app.ble.service - INFO - D-Bus Advertisement:    Registered
2025-11-09 21:05:23 - app.ble.service - INFO - Uptime:                 0s
2025-11-09 21:05:23 - app.ble.service - INFO - ============================================================
```

---

## Files Modified

1. **app/ble/service.py**
   - Changed `_create_services()` method to use `peripheral.add_service()` API
   - Added `ServiceWrapper` class to provide required attributes to characteristics

2. **app/ble/characteristics/uart.py**
   - Changed `UARTRXCharacteristic` to inherit from `BaseCharacteristic`
   - Changed `UARTTXCharacteristic` to inherit from `BaseCharacteristic`
   - Added `_handle_read()` implementation to `UARTRXCharacteristic`

---

## Architecture Notes

### BlueZero Modern API (v0.8.0+)
The modern BlueZero peripheral API flow:
1. Create `peripheral.Peripheral` instance
2. Use `peripheral.add_service(srv_id, uuid, primary)` to add services
3. Use `peripheral.add_characteristic(srv_id, chr_id, uuid, flags, ...)` to add characteristics
4. The peripheral manages the D-Bus registration automatically

### Characteristic Properties (Flags)
Common BLE characteristic properties:
- `"read"` - Allow reading the characteristic value
- `"write"` - Allow writing with response/acknowledgment
- `"write-without-response"` - Allow writing without acknowledgment (faster)
- `"notify"` - Allow server to push updates to client
- `"indicate"` - Like notify but with acknowledgment

### Service Wrapper Pattern
When characteristics need to call `peripheral.add_characteristic()`, they need access to:
- `service.peripheral` - The peripheral instance
- `service.srv_id` - The service ID number

The `ServiceWrapper` class provides this interface without requiring changes to the characteristic classes.

---

## Testing Checklist

- [x] Service initializes without errors
- [x] Adapter is powered and discoverable
- [x] D-Bus advertisement is registered
- [x] Service UUID appears in advertisement
- [x] Pairing/bonding is disabled (prevents connection drops)
- [ ] Characteristics are readable/writable from BLE client
- [ ] Environmental data notifications work
- [ ] UART RX/TX communication works
- [ ] Control targets can be written
- [ ] Stage state can be read/written

---

## Related Documentation

- BlueZero Documentation: https://bluezero.readthedocs.io/
- BlueZero Examples: https://bluezero.readthedocs.io/en/stable/examples.html#peripheral-nordic-uart-service
- BlueZ D-Bus API: https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc
