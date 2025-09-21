"""
MushPi Data Models

Dataclasses for sensor readings, thresholds, and events used throughout the MushPi system.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class SensorReading:
    """Complete sensor reading with timestamp"""
    timestamp: datetime
    co2_ppm: Optional[int] = None
    temperature_c: Optional[float] = None
    humidity_percent: Optional[float] = None
    light_level: Optional[float] = None
    sensor_source: str = ""


@dataclass 
class Threshold:
    """Environmental threshold configuration"""
    parameter: str  # 'temperature', 'humidity', 'co2', 'light'
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    hysteresis: float = 1.0  # Prevents relay chattering
    active: bool = True
    

@dataclass
class ThresholdEvent:
    """Threshold violation event"""
    timestamp: datetime
    parameter: str
    current_value: float
    threshold_type: str  # 'min' or 'max'
    threshold_value: float
    action_taken: str