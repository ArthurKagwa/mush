#!/usr/bin/env python3
"""
Test script for relay-controlled fan

Tests the exhaust fan relay control on GPIO 17.
Cycles the fan ON and OFF to verify relay operation.

Wiring:
- Relay IN (signal) -> GPIO 17 (Pin 11)
- Relay VCC -> 5V
- Relay GND -> GND
- Fan connected to relay's NO (Normally Open) terminal

Most relay modules are ACTIVE LOW:
- GPIO LOW = Relay ON (fan runs)
- GPIO HIGH = Relay OFF (fan stops)
"""

import time
import RPi.GPIO as GPIO

# Configuration
FAN_PIN = 17  # GPIO 17 (Physical Pin 11)
ACTIVE_LOW = True  # Most relay modules are active LOW

def setup_gpio():
    """Initialize GPIO"""
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    GPIO.setup(FAN_PIN, GPIO.OUT)
    
    # Set initial state to OFF
    if ACTIVE_LOW:
        GPIO.output(FAN_PIN, GPIO.HIGH)  # HIGH = OFF for active low
    else:
        GPIO.output(FAN_PIN, GPIO.LOW)   # LOW = OFF for active high
    
    print(f"✓ GPIO initialized (Pin {FAN_PIN})")
    print(f"  Relay mode: {'ACTIVE LOW' if ACTIVE_LOW else 'ACTIVE HIGH'}")

def turn_fan_on():
    """Turn fan ON"""
    if ACTIVE_LOW:
        GPIO.output(FAN_PIN, GPIO.LOW)   # LOW = ON for active low
        print("🌀 Fan ON (GPIO LOW)")
    else:
        GPIO.output(FAN_PIN, GPIO.HIGH)  # HIGH = ON for active high
        print("🌀 Fan ON (GPIO HIGH)")

def turn_fan_off():
    """Turn fan OFF"""
    if ACTIVE_LOW:
        GPIO.output(FAN_PIN, GPIO.HIGH)  # HIGH = OFF for active low
        print("⭕ Fan OFF (GPIO HIGH)")
    else:
        GPIO.output(FAN_PIN, GPIO.LOW)   # LOW = OFF for active high
        print("⭕ Fan OFF (GPIO LOW)")

def cleanup():
    """Clean up GPIO"""
    turn_fan_off()
    GPIO.cleanup()
    print("\n✓ GPIO cleaned up")

def main():
    print("Fan Relay Test")
    print("=" * 50)
    print()
    
    try:
        setup_gpio()
        print()
        print("Starting fan cycle test (Ctrl+C to stop)...")
        print("-" * 50)
        
        cycle = 1
        while True:
            print(f"\nCycle {cycle}:")
            
            # Turn fan ON
            turn_fan_on()
            print("  Waiting 5 seconds...")
            time.sleep(5)
            
            # Turn fan OFF
            turn_fan_off()
            print("  Waiting 3 seconds...")
            time.sleep(3)
            
            cycle += 1
            
    except KeyboardInterrupt:
        print("\n\nTest stopped by user")
    except Exception as e:
        print(f"\n✗ Error: {e}")
    finally:
        cleanup()

if __name__ == "__main__":
    print()
    print("IMPORTANT: Check your relay module type!")
    print("- If relay clicks but fan behavior is REVERSED,")
    print("  edit this script and set ACTIVE_LOW = False")
    print()
    input("Press ENTER to start test...")
    print()
    main()
