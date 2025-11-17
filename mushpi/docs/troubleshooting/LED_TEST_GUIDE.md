# LED Power Test for Raspberry Pi

This is a simple hardware test to verify power and connections on your Raspberry Pi.

## Purpose
Test that your Pi is powered and that your wiring/breadboard connections work correctly.

## What You Need
- 1x LED (any color)
- 1x 330Ω resistor (or 220Ω - 1kΩ range)
- 2x jumper wires

## Test 1: Direct 3.3V Power Test

### Connections:
```
Raspberry Pi Pin 1 (3.3V) → Resistor (330Ω) → LED Anode (+, longer leg) → LED Cathode (-, shorter leg) → Pi GND (Pin 6, 9, 14, 20, 25, 30, 34, or 39)
```

### Simplified:
```
3.3V ---[330Ω]---->|---- GND
                   LED
```

### Expected Result:
- LED should light up immediately when Pi is powered (even at boot/EDT)
- No code needed
- If LED doesn't light: check connections, LED polarity, or try different pins

## Test 2: 5V Power Test (BRIGHTER)

### Connections:
```
Raspberry Pi Pin 2 or 4 (5V) → Resistor (330Ω) → LED Anode (+) → LED Cathode (-) → Pi GND
```

### Expected Result:
- LED will be BRIGHTER than with 3.3V
- Still no code needed

## Troubleshooting Your DHT22

If the LED lights up but your DHT22 doesn't work:

1. **LED lights = Power is good, wiring path works**
2. **DHT22 still fails = Problem is likely:**
   - Missing pull-up resistor (10kΩ between Data and VCC)
   - Wrong Data pin connection
   - Faulty DHT22 sensor
   - Incorrect pin numbering (GPIO vs Physical pin)

## Pin Reference (40-pin Raspberry Pi)

```
Physical Pin | BCM GPIO | Function
-------------|----------|------------------
Pin 1        | -        | 3.3V Power
Pin 2        | -        | 5V Power
Pin 6        | -        | Ground
Pin 9        | -        | Ground
Pin 15       | GPIO 22  | Your DHT22 Data
Pin 14       | -        | Ground
Pin 17       | -        | 3.3V Power
```

## Quick Continuity Test

If you want to test your breadboard connections:
1. Put LED + resistor in your breadboard where DHT22 data line goes
2. Connect to 3.3V and GND
3. If LED lights, your breadboard connections are good
4. Replace LED with DHT22 and test again

## Why This Helps

- Proves Pi is powered
- Proves your jumper wires work
- Proves your breadboard connections work
- Isolates whether problem is power/wiring vs sensor/code
