#!/usr/bin/env python3
"""
Simple LED Toggle Test
Blinks an LED on and off to test GPIO control
"""

import time
import sys

print("=" * 70)
print("LED Toggle Test")
print("=" * 70)
print()

# LED Configuration
LED_PIN = 17  # GPIO 17 (Physical Pin 11)

print("PIN MAPPINGS:")
print("-" * 70)
print("LED Connection:")
print(f"  GPIO {LED_PIN} (Pin 11) -> LED Anode (+, long leg)")
print("  LED Cathode (-, short leg) t   -> 330Ω Resistor -> GND")
print()
print("OR (without resistor, less bright):")
print(f"  GPIO {LED_PIN} (Pin 11) -> LED Anode (+)")
print("  LED Cathode (-) -> GND (use GPIO current limiting)")
print("=" * 70)
print()

# Import libraries
try:
    import RPi.GPIO as GPIO
    print("✅ GPIO library imported successfully")
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("\nPlease install required library:")
    print("  sudo apt-get install python3-rpi.gpio")
    sys.exit(1)

print()

# Initialize GPIO
print(f"Initializing GPIO {LED_PIN} for LED output...")
try:
    GPIO.setmode(GPIO.BCM)  # Use BCM GPIO numbering
    GPIO.setwarnings(False)
    GPIO.setup(LED_PIN, GPIO.OUT)
    GPIO.output(LED_PIN, GPIO.LOW)  # Start with LED off
    print(f"✅ GPIO {LED_PIN} initialized successfully")
except Exception as e:
    print(f"❌ GPIO initialization failed: {e}")
    sys.exit(1)

print()
print("=" * 70)
print("BLINKING LED (Ctrl+C to stop)")
print("=" * 70)
print()

# Blink counter
blink_count = 0

try:
    while True:
        # Turn LED ON
        GPIO.output(LED_PIN, GPIO.HIGH)
        print(f"🔆 LED ON  (blink #{blink_count + 1})")
        time.sleep(0.5)
        
        # Turn LED OFF
        GPIO.output(LED_PIN, GPIO.LOW)
        print(f"🔅 LED OFF (blink #{blink_count + 1})")
        time.sleep(0.5)
        
        blink_count += 1
        
except KeyboardInterrupt:
    print("\n")
    print("=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Total blinks: {blink_count}")
    
    # Cleanup
    GPIO.output(LED_PIN, GPIO.LOW)  # Turn off LED
    GPIO.cleanup()
    print("\n✅ GPIO cleanup complete")
    print("Test completed.")
    sys.exit(0)
