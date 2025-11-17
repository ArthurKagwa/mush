#!/usr/bin/env python3
"""
Test script for ADS1115 + Photoresistor (Light Sensor)

Reads the analog voltage from the photoresistor voltage divider
connected to ADS1115 channel A0 and displays raw value and voltage.

Wiring:
- ADS1115 VDD -> 3.3V
- ADS1115 GND -> GND
- ADS1115 SDA -> GPIO2 (Pin 3)
- ADS1115 SCL -> GPIO3 (Pin 5)
- ADS1115 ADDR -> GND (for address 0x48)
- Photoresistor divider output -> ADS1115 A0

Voltage Divider:
- 3.3V -> LDR -> A0 -> 10kΩ pot -> GND
  (or swap LDR/pot if you want inverse behavior)
"""

import time
import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

def main():
    print("ADS1115 + Photoresistor Test")
    print("=" * 50)
    
    try:
        # Initialize I2C bus
        i2c = busio.I2C(board.SCL, board.SDA)
        print("✓ I2C bus initialized")
        
        # Initialize ADS1115 at address 0x48
        ads = ADS.ADS1115(i2c, address=0x48)
        print("✓ ADS1115 initialized at address 0x48")
        
        # Create analog input on channel A0
        # Use ads.P0 (instance attribute) not ADS.P0 (class attribute)
        channel = AnalogIn(ads, 0)  # Channel 0 = A0
        print("✓ Channel A0 configured")
        print()
        
        print("Reading light sensor (Ctrl+C to stop)...")
        print("-" * 50)
        print(f"{'Time':<10} {'Raw Value':<12} {'Voltage (V)':<15} {'Description'}")
        print("-" * 50)
        
        while True:
            raw_value = channel.value
            voltage = channel.voltage
            
            # Classify light level based on voltage
            # (Adjust thresholds based on your circuit)
            if voltage < 0.5:
                description = "Very Dark"
            elif voltage < 1.0:
                description = "Dark"
            elif voltage < 2.0:
                description = "Medium"
            elif voltage < 2.8:
                description = "Bright"
            else:
                description = "Very Bright"
            
            timestamp = time.strftime("%H:%M:%S")
            print(f"{timestamp:<10} {raw_value:<12} {voltage:<15.3f} {description}")
            
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        print("\n\nTest stopped by user")
    except Exception as e:
        print(f"\n✗ Error: {e}")
        print("\nTroubleshooting:")
        print("1. Check I2C is enabled: sudo raspi-config -> Interface Options -> I2C")
        print("2. Verify ADS1115 is detected: i2cdetect -y 1")
        print("3. Check wiring connections")
        print("4. Ensure ADS1115 is powered from 3.3V (not 5V)")
        print("5. Verify photoresistor divider is connected to A0")

if __name__ == "__main__":
    main()
