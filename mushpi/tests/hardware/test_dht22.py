#!/usr/bin/env python3
"""
Simple DHT22 test script to diagnose sensor issues
"""
import time
import board
import adafruit_dht

print("Testing DHT22 sensor on GPIO 4 (D4)...")
print("Note: DHT22 requires a 10kΩ pull-up resistor between DATA and VCC")
print()

# Initialize DHT22 on GPIO4 (board.D4)
dht_device = adafruit_dht.DHT22(board.D4, use_pulseio=False)

print("Starting readings (Ctrl+C to stop)...")
print()

successful_reads = 0
failed_reads = 0

while True:
    try:
        temperature_c = dht_device.temperature
        humidity = dht_device.humidity
        
        if temperature_c is not None and humidity is not None:
            print(f"✅ Temp: {temperature_c:.1f}°C, Humidity: {humidity:.1f}%")
            successful_reads += 1
        else:
            print("❌ Read returned None")
            failed_reads += 1
            
    except RuntimeError as error:
        print(f"❌ RuntimeError: {error.args[0]}")
        failed_reads += 1
    except Exception as error:
        print(f"❌ Exception: {error}")
        failed_reads += 1
        
    print(f"   Stats: {successful_reads} successful, {failed_reads} failed")
    print()
    
    # DHT22 can only be read every 2 seconds
    time.sleep(3)
