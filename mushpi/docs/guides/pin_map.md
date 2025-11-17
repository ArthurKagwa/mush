### Actuator Pin Mapping

| Actuator         | Pi Pin (Physical) | Pi Pin (BCM) | Function        | Notes                                               |
|------------------|------------------|--------------|-----------------|-----------------------------------------------------|
| FAN (Relay 1)    | Pin 11           | GPIO 17      | Digital Output  | Control pin for the fan relay.                      |
| MIST (Relay 2)   | Pin 13           | GPIO 27      | Digital Output  | Control pin for the humidifier/mister relay.        |
| LIGHT (Relay 3)  | Pin 15           | GPIO 22      | Digital Output  | Control pin for the light relay.                    |
| HEATER (Relay 4) | Pin 16           | GPIO 23      | Digital Output  | Control pin for the optional heater relay.          |
| Relay VCC        | 5V               | -            | Power           | Most relays require 5V power (JD-VCC/VCC).          |
| Relay GND        | GND              | -            | Ground          | Connect to the relay board's GND.                   |
| Relay Logic      | 3.3V             | -            | Logic Power     | If relay board uses separate logic power, connect the low-voltage VCC pin to the Pi's 3.3V pin. |

---

### DHT22 Pin Mapping

| Pin    | Pi Pin (Physical) | Pi Pin (BCM) | Function   | Notes                                                        |
|--------|-------------------|--------------|------------|--------------------------------------------------------------|
| VCC    | 3.3V              | -            | Power      |                                                              |
| Data   | Pin 7             | GPIO 4       | Data Line  | Requires a 10 kΩ pull-up resistor between this pin and VCC.  |
| GND    | GND               | -            | Ground     | Connect to a common ground pin.                              |

---

### Sensor (I²C) Pin Mapping

| Pin      | Pi Pin (Physical) | Pi Pin (BCM) | Function      | Notes                                                                 |
|----------|-------------------|--------------|---------------|-----------------------------------------------------------------------|
| SDA      | Pin 3             | GPIO 2       | I²C Data Line | Connect to SDA on both sensors/boards.                                |
| SCL      | Pin 5             | GPIO 3       | I²C Clock Line| Connect to SCL on both sensors/boards.                                |
| VCC/VDD  | 3.3V              | -            | Power         | Check sensor's required voltage (most modern I²C boards are 3.3V-compatible or include a regulator). |
| GND      | GND               | -            | Ground        | Connect to a common ground pin.                                       |