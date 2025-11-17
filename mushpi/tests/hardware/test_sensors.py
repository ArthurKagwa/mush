#!/usr/bin/env python3
"""
Test script for CO2 Sensor (SCD41) and DHT11
Tests both sensors with pin mapping information
"""

import time
import sys

print("=" * 70)
print("MushPi Sensor Test: SCD41 (CO2) and DHT11")
print("=" * 70)
print()

# Display Pin Mappings
print("PIN MAPPINGS:")
print("-" * 70)
print("DHT11 (Temperature & Humidity):")
print("  VCC  -> 3.3V or 5V")
print("  Data -> Pin 7 (GPIO 4 / BCM 4)")
print("  GND  -> GND")
print("  NOTE: Requires 10kΩ pull-up resistor between Data and VCC")
print()
print("SCD41 (CO2, Temperature & Humidity - I²C):")
print("  VCC  -> 3.3V")
print("  SDA  -> Pin 3 (GPIO 2 / BCM 2)")
print("  SCL  -> Pin 5 (GPIO 3 / BCM 3)")
print("  GND  -> GND")
print("=" * 70)
print()

# Import libraries
try:
    import board
    import busio
    import adafruit_dht
    import adafruit_scd4x
    GPIO_AVAILABLE = True
    print("✅ All required libraries imported successfully")
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("\nPlease install required libraries:")
    print("  sudo pip3 install adafruit-circuitpython-dht")
    print("  sudo pip3 install adafruit-circuitpython-scd4x")
    print("  sudo apt-get install libgpiod2")
    sys.exit(1)

print()

print("Initializing DHT11 on GPIO 4...")
try:
    dht_device = adafruit_dht.DHT22(board.D4, use_pulseio=False)
    print("✅ DHT11 initialized successfully")
    dht_working = True
except Exception as e:
    print(f"❌ DHT11 initialization failed: {e}")
    dht_working = False

print()

# Initialize SCD41
print("Initializing SCD41 on I2C (SDA=GPIO2, SCL=GPIO3)...")
try:
    i2c = busio.I2C(board.SCL, board.SDA)
    scd41 = adafruit_scd4x.SCD4X(i2c)
    print(f"✅ SCD41 detected, Serial: 0x{scd41.serial_number[0]:X}{scd41.serial_number[1]:X}{scd41.serial_number[2]:X}")
    
    # Start periodic measurements
    scd41.start_periodic_measurement()
    print("✅ SCD41 periodic measurements started")
    scd41_working = True
except Exception as e:
    print(f"❌ SCD41 initialization failed: {e}")
    scd41_working = False

print()
print("=" * 70)
print("READING SENSORS (Ctrl+C to stop)")
print("=" * 70)
print()

 # Stats
dht11_success = 0
dht11_fail = 0
scd41_success = 0
scd41_fail = 0

try:
    while True:
        print(f"--- Reading at {time.strftime('%H:%M:%S')} ---")
        
        # Read DHT11
        if dht_working:
            try:
                temp_dht = dht_device.temperature
                humid_dht = dht_device.humidity
                
                if temp_dht is not None and humid_dht is not None:
                    print(f"DHT11:  Temp: {temp_dht:5.1f}°C  |  Humidity: {humid_dht:5.1f}%")
                    dht11_success += 1
                else:
                    print("DHT11:  ❌ Read returned None")
                    dht11_fail += 1
                    
            except RuntimeError as e:
                print(f"DHT11:  ❌ RuntimeError: {e.args[0]}")
                dht11_fail += 1
            except Exception as e:
                print(f"DHT11:  ❌ Exception: {e}")
                dht11_fail += 1
        else:
            print("DHT11:  ⚠️  Sensor not initialized")
        
        # Read SCD41
        if scd41_working:
            try:
                if scd41.data_ready:
                    co2 = scd41.CO2
                    temp_scd = scd41.temperature
                    humid_scd = scd41.relative_humidity
                    
                    print(f"SCD41:  CO2: {co2:4d} ppm  |  Temp: {temp_scd:5.1f}°C  |  Humidity: {humid_scd:5.1f}%")
                    scd41_success += 1
                else:
                    print("SCD41:  ⏳ Data not ready yet (sensor warming up)")
                    
            except Exception as e:
                print(f"SCD41:  ❌ Exception: {e}")
                scd41_fail += 1
        else:
            print("SCD41:  ⚠️  Sensor not initialized")
        
        # Display stats
        print(f"Stats:  DHT11 ({dht11_success}✓/{dht11_fail}✗)  |  SCD41 ({scd41_success}✓/{scd41_fail}✗)")
        print()
        
        # Wait before next reading
        # DHT22 needs 2+ seconds between reads
        # SCD41 updates every ~5 seconds
        time.sleep(5)
        
except KeyboardInterrupt:
    print("\n")
    print("=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"DHT11:  {dht11_success} successful reads, {dht11_fail} failed reads")
    print(f"SCD41:  {scd41_success} successful reads, {scd41_fail} failed reads")
    
    # Cleanup
    if scd41_working:
        try:
            scd41.stop_periodic_measurement()
            print("\n✅ SCD41 measurements stopped")
        except:
            pass
    
    if dht_working:
        try:
            dht_device.exit()
            print("✅ DHT11 cleanup complete")
        except:
            pass
    
    print("\nTest completed.")
    sys.exit(0)
