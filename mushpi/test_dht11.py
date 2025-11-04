#!/usr/bin/env python3
"""
Simple DHT22 Test Script
Tests DHT22 temperature and humidity sensor
"""

import time
import sys

print("=" * 70)
print("DHT22 Sensor Test")
print("=" * 70)
print()

# Display Pin Mappings
print("PIN MAPPINGS:")
print("-" * 70)
print("DHT22 (Temperature & Humidity):")
print("  VCC  -> 3.3V or 5V")
print("  Data -> Pin 15 (GPIO 22 / BCM 22)")
print("  GND  -> GND")
print("  NOTE: Requires 10kΩ pull-up resistor between Data and VCC")
print("=" * 70)
print()

# Import libraries
try:
    import board
    import adafruit_dht
    print("✅ Libraries imported successfully")
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("\nPlease install required libraries:")
    print("  sudo pip3 install adafruit-circuitpython-dht")
    print("  sudo apt-get install libgpiod2")
    sys.exit(1)

print()

# Initialize DHT22
print("Initializing DHT22 on GPIO 22...")
try:
    dht_device = adafruit_dht.DHT11(board.D4, use_pulseio=False)
    print("✅ DHT22 initialized successfully")
    print()
except Exception as e:
    print(f"❌ DHT22 initialization failed: {e}")
    sys.exit(1)

print("=" * 70)
print("READING SENSOR (Ctrl+C to stop)")
print("=" * 70)
print()

# Statistics
success_count = 0
fail_count = 0

try:
    while True:
        print(f"--- Reading at {time.strftime('%H:%M:%S')} ---")
        
        temperature = dht_device.temperature
        humidity = dht_device.humidity
        
        
        print(f"Temperature: {temperature:5.1f}°C")
        print(f"Humidity:    {humidity:5.1f}%")
        success_count += 1
        
        
        # Display stats
        total = success_count + fail_count
        if total > 0:
            success_rate = (success_count / total) * 100
            print(f"Stats: {success_count} successful, {fail_count} failed ({success_rate:.1f}% success rate)")
        
        print()
        
        # Wait before next reading (DHT22 needs 2+ seconds between reads)
        time.sleep(3)
        
except KeyboardInterrupt:
    print("\n")
    print("=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Successful reads: {success_count}")
    print(f"Failed reads:     {fail_count}")
    if success_count + fail_count > 0:
        success_rate = (success_count / (success_count + fail_count)) * 100
        print(f"Success rate:     {success_rate:.1f}%")
    
    # Cleanup
    try:
        dht_device.exit()
        print("\n✅ DHT22 cleanup complete")
    except:
        pass
    
    print("\nTest completed.")
    sys.exit(0)
