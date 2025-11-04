#!/usr/bin/env python3
"""
SCD41 Diagnostic and Readout Script for Raspberry Pi Zero 2 W

Stage 1: talk directly over I2C with smbus2
    - send serial number command 0x3682
    - read 9 bytes response

Stage 2: if Stage 1 succeeds, use adafruit_scd4x driver
    - start periodic measurement
    - print CO2 ppm, temperature in degC, humidity in percent RH
"""

import time
import sys

# Stage 1: direct I2C probe using smbus2
print("=" * 70)
print("Stage 1: direct I2C probe using smbus2")
print("=" * 70)

try:
    from smbus2 import SMBus, i2c_msg
except ImportError as e:
    print("FATAL: smbus2 is not installed in this venv.")
    print("Run: pip install smbus2")
    sys.exit(1)

I2C_BUS_NUM = 1          # Pi Zero 2 W: SDA pin 3 and SCL pin 5 are /dev/i2c-1
SCD41_ADDR  = 0x62       # Default I2C address for SCD41

probe_ok = False
serial_bytes = None

print(f"Opening I2C bus {I2C_BUS_NUM} and probing address 0x{SCD41_ADDR:02X} ...")

try:
    bus = SMBus(I2C_BUS_NUM)

    # Command: read serial number
    # Datasheet: send 0x36 0x82, then read 9 bytes
    write = i2c_msg.write(SCD41_ADDR, [0x36, 0x82])
    read = i2c_msg.read(SCD41_ADDR, 9)

    bus.i2c_rdwr(write, read)
    data = list(read)
    serial_bytes = data

    # data format: 2 data bytes + CRC, repeated 3 times, total 9 bytes
    # We will just print raw
    print("Raw serial number response:", data)

    # very basic health heuristic: if we got 9 bytes without throwing,
    # we consider this a pass
    if len(data) == 9:
        probe_ok = True
        print("Result: probe success. Sensor is talking.")
    else:
        print("Result: unexpected length. Sensor behaviour uncertain.")

except Exception as e:
    print("Direct I2C transaction failed.")
    print("Error was:", e)
    print()
    print("Interpretation:")
    print(" - If you still see 0x62 in i2cdetect but this failed,")
    print("   that means the Pi can see an ACK at that address,")
    print("   but the sensor is not answering full commands.")
    print("   This usually means: bad SDA or SCL contact, brown power,")
    print("   or wrong sensor on that address.")
    probe_ok = False

# Close the bus cleanly
try:
    bus.close()
except Exception:
    pass

print()
print("=" * 70)
print("Stage 2: High level read loop via adafruit_scd4x")
print("=" * 70)

if not probe_ok:
    print("Skipping Stage 2 because Stage 1 could not reliably talk to the sensor.")
    print("Fix wiring or power to the SCD41, then run this script again.")
    sys.exit(0)

# If we reach here: hardware is responsive to real commands.
# Now we try the nice driver.

try:
    import board
    import busio
    import adafruit_scd4x
except ImportError as e:
    print("Import error when loading board/busio/adafruit_scd4x:")
    print(e)
    print("You may be missing adafruit-blinka or adafruit-circuitpython-scd4x in this venv.")
    sys.exit(1)

print("Initialising I2C bus through Blinka ...")
try:
    i2c = busio.I2C(board.SCL, board.SDA)
except Exception as e:
    print("Could not open I2C via busio.I2C(board.SCL, board.SDA)")
    print("Error:", e)
    print("This usually means Blinka is confused about bus mapping on this board.")
    sys.exit(1)

print("Creating SCD4X object ...")
try:
    scd4x = adafruit_scd4x.SCD4X(i2c)
    # build the serial number string like your code attempted
    ser = scd4x.serial_number
    serial_str = "0x{:X}{:X}{:X}".format(ser[0], ser[1], ser[2])
    print("SCD4X detected. Serial:", serial_str)
except Exception as e:
    print("adafruit_scd4x.SCD4X(i2c) failed.")
    print("Library is loaded, bus is open, but init blew up.")
    print("Error:", e)
    print("If Stage 1 worked but this failed, then the problem is inside the driver layer,")
    print("not the wiring.")
    sys.exit(1)

print("Starting periodic measurement ...")
scd4x.start_periodic_measurement()
print("Sensor is now sampling. First valid reading takes a few seconds.")

time.sleep(5)

print()
print("Live readings. Press Ctrl+C to stop.")
print()

try:
    while True:
        co2 = scd4x.CO2
        temp_c = scd4x.temperature
        rh = scd4x.relative_humidity

        if co2 is None:
            # driver returns None until fresh data is ready
            print("waiting for fresh sample ...")
        else:
            print(f"CO2: {co2:.0f} ppm    Temp: {temp_c:.2f} °C    RH: {rh:.1f} %")

        time.sleep(2)
except KeyboardInterrupt:
    print("\nStopping. Goodbye.")
