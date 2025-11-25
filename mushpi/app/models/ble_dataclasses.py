"""
MushPi BLE Data Models

Data classes and enums for BLE GATT telemetry service.
Extracted from core/ble_gatt.py for better modularity.
"""

import time
from typing import Dict, Any
from dataclasses import dataclass
from enum import IntFlag

# Characteristic UUIDs for the ENV-CONTROL service
ENV_MEASUREMENTS_UUID = "12345678-1234-5678-1234-56789abcdef1"
CONTROL_TARGETS_UUID = "12345678-1234-5678-1234-56789abcdef2"  
STAGE_STATE_UUID = "12345678-1234-5678-1234-56789abcdef3"
OVERRIDE_BITS_UUID = "12345678-1234-5678-1234-56789abcdef4"
STATUS_FLAGS_UUID = "12345678-1234-5678-1234-56789abcdef5"
# New: Actuator status (bitfield of current relay states)
ACTUATOR_STATUS_UUID = "12345678-1234-5678-1234-56789abcdef6"


class OverrideBits(IntFlag):
    """Manual relay override bits"""
    LIGHT = 1 << 0        # bit0: Force light on/off
    FAN = 1 << 1          # bit1: Force fan on/off  
    MIST = 1 << 2         # bit2: Force mist on/off
    HEATER = 1 << 3       # bit3: Force heater on/off
    DISABLE_AUTO = 1 << 7 # bit7: Disable automation
    EMERGENCY_STOP = 1 << 15  # bit15: Emergency stop (safety mode)


class StatusFlags(IntFlag):
    """System status flags"""
    SENSOR_ERROR = 1 << 0     # Sensor read failure
    CONTROL_ERROR = 1 << 1    # Control system error
    STAGE_READY = 1 << 2      # Ready for stage advance
    THRESHOLD_ALARM = 1 << 3  # Threshold violation
    CONNECTIVITY = 1 << 4     # BLE connected
    SIMULATION = 1 << 7       # Simulation mode active


class ActuatorBits(IntFlag):
    """Current actuator ON/OFF states (bitfield)
    These reflect the live relay states on the Pi, not overrides.
    """
    LIGHT = 1 << 0   # grow_light relay
    FAN = 1 << 1     # exhaust_fan relay
    MIST = 1 << 2    # humidifier relay
    HEATER = 1 << 3  # heater relay


@dataclass
class EnvironmentalData:
    """Environmental sensor measurements"""
    co2_ppm: int          # CO₂ in ppm (u16)
    temp_x10: int         # Temperature × 10 in °C (s16)
    rh_x10: int          # Relative humidity × 10 in % (u16)
    light_raw: int        # Light sensor raw value (u16)
    uptime_ms: int        # System uptime in milliseconds (u32)

    @classmethod
    def create_empty(cls) -> 'EnvironmentalData':
        """Create empty environmental data with zeros"""
        return cls(0, 0, 0, 0, 0)

    def update_uptime(self, start_time: float):
        """Update uptime based on start time"""
        self.uptime_ms = int((time.time() - start_time) * 1000)


@dataclass  
class ControlTargets:
    """Control system target thresholds"""
    temp_min_x10: int     # Minimum temperature × 10 (s16)
    temp_max_x10: int     # Maximum temperature × 10 (s16)
    rh_min_x10: int       # Minimum humidity × 10 (u16)
    co2_max: int          # Maximum CO₂ in ppm (u16)
    light_mode: int       # Light mode: 0=OFF, 1=ON, 2=CYCLE (u8)
    on_minutes: int       # Light on duration in minutes (u16)
    off_minutes: int      # Light off duration in minutes (u16)

    @classmethod
    def create_default(cls) -> 'ControlTargets':
        """Create default control targets"""
        return cls(200, 280, 700, 5000, 0, 0, 0)


@dataclass
class StageStateData:
    """Growth stage state information"""
    mode: int             # 0=FULL, 1=SEMI, 2=MANUAL (u8)
    species_id: int       # Species identifier (u8)
    stage_id: int         # Stage identifier (u8)
    stage_start_ts: int   # Stage start timestamp (u32)
    expected_days: int    # Expected stage duration in days (u16)

    @classmethod
    def create_empty(cls) -> 'StageStateData':
        """Create empty stage state data"""
        return cls(0, 0, 0, 0, 0)


# Species and stage mapping dictionaries
SPECIES_MAP = {
    'Oyster': 1, 
    'Shiitake': 2, 
    'Lion\'s Mane': 3
}

SPECIES_REVERSE_MAP = {
    1: 'Oyster', 
    2: 'Shiitake', 
    3: 'Lion\'s Mane'
}

STAGE_MAP = {
    'Incubation': 1, 
    'Pinning': 2, 
    'Fruiting': 3
}

STAGE_REVERSE_MAP = {
    1: 'Incubation', 
    2: 'Pinning', 
    3: 'Fruiting'
}

MODE_NAMES = ['FULL', 'SEMI', 'MANUAL']
LIGHT_MODES = ['off', 'on', 'cycle']


# Export all classes and constants
__all__ = [
    # UUIDs
    'ENV_MEASUREMENTS_UUID', 'CONTROL_TARGETS_UUID', 'STAGE_STATE_UUID',
    'OVERRIDE_BITS_UUID', 'STATUS_FLAGS_UUID', 'ACTUATOR_STATUS_UUID',
    # Enums
    'OverrideBits', 'StatusFlags', 'ActuatorBits',
    # Data classes
    'EnvironmentalData', 'ControlTargets', 'StageStateData',
    # Mapping dictionaries
    'SPECIES_MAP', 'SPECIES_REVERSE_MAP', 'STAGE_MAP', 'STAGE_REVERSE_MAP',
    'MODE_NAMES', 'LIGHT_MODES'
]