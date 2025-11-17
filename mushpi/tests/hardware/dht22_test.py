import time
import adafruit_dht
import board

# DHT22 data line connected to GPIO4 (physical pin 7)
dht = adafruit_dht.DHT22(board.D4)

print("=" * 70)
print("Quick DHT22 Temperature and Humidity Test")
print("=" * 70)
print("Press Ctrl+C to stop.\n")

while True:
    try:
        temp_c = dht.temperature
        hum = dht.humidity
        if temp_c is not None and hum is not None:
            print(f"Temp: {temp_c:.1f} °C   Humidity: {hum:.1f} %")
        else:
            print("Waiting for valid reading...")
    except RuntimeError as e:
        # Common with DHT sensors; they occasionally timeout
        print("Read error:", e.args[0])
    time.sleep(2)
