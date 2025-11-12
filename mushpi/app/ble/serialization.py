"""
BLE Data Serialization Utilities

Binary data packing/unpacking for BLE GATT characteristics.
Handles conversion between data classes and binary formats.
"""

import struct
import time
import logging
from typing import Dict, Any, Optional

from ..models.ble_dataclasses import (
    EnvironmentalData, ControlTargets, StageStateData,
    OverrideBits, StatusFlags,
    SPECIES_MAP, SPECIES_REVERSE_MAP, STAGE_MAP, STAGE_REVERSE_MAP,
    MODE_NAMES, LIGHT_MODES
)

logger = logging.getLogger(__name__)


class SerializationError(Exception):
    """Exception for data serialization/deserialization errors"""
    pass


class EnvironmentalSerializer:
    """Serializer for environmental measurement data"""
    
    FORMAT = '<HhHHI'  # u16, s16, u16, u16, u32 (little-endian)
    SIZE = 12  # bytes
    
    @staticmethod
    def _to_int(value, default=0) -> int:
        """Best-effort conversion to int with a default for None/invalid.
        Avoids raising on float/None inputs.
        """
        try:
            return int(value)
        except Exception:
            return int(default)

    @classmethod
    def _u16(cls, value) -> int:
        """Clamp to unsigned 16-bit range [0..65535] without hard coding limits."""
        lo, hi = 0, (1 << 16) - 1
        x = cls._to_int(value, 0)
        if x < lo:
            return lo
        if x > hi:
            return hi
        return x

    @classmethod
    def _i16(cls, value) -> int:
        """Clamp to signed 16-bit range [-32768..32767] without hard coding limits."""
        lo, hi = -(1 << 15), (1 << 15) - 1
        x = cls._to_int(value, 0)
        if x < lo:
            return lo
        if x > hi:
            return hi
        return x

    @classmethod
    def _u32(cls, value) -> int:
        """Clamp to unsigned 32-bit range [0..4294967295] without hard coding limits."""
        lo, hi = 0, (1 << 32) - 1
        x = cls._to_int(value, 0)
        if x < lo:
            return lo
        if x > hi:
            return hi
        return x
    
    @classmethod
    def pack(cls, data: EnvironmentalData) -> bytes:
        """Pack environmental data to binary format
        
        Data format (12 bytes total):
        - CO₂ ppm (u16, 2 bytes)
        - Temperature × 10 (s16, 2 bytes) 
        - Humidity × 10 (u16, 2 bytes)
        - Light raw (u16, 2 bytes)
        - Uptime ms (u32, 4 bytes)
        
        Args:
            data: Environmental data object
            
        Returns:
            Packed binary data (12 bytes)
        """
        try:
            # Coerce and clamp all fields to their protocol integer ranges
            co2 = cls._u16(getattr(data, 'co2_ppm', 0))
            temp = cls._i16(getattr(data, 'temp_x10', 0))
            rh = cls._u16(getattr(data, 'rh_x10', 0))
            light = cls._u16(getattr(data, 'light_raw', 0))
            uptime = cls._u32(getattr(data, 'uptime_ms', 0))

            return struct.pack(cls.FORMAT, co2, temp, rh, light, uptime)
        except Exception as e:
            logger.error(f"Error packing environmental data: {e}")
            raise SerializationError(f"Failed to pack environmental data: {e}")
    
    @classmethod
    def unpack(cls, data: bytes) -> EnvironmentalData:
        """Unpack binary data to environmental data object
        
        Args:
            data: Binary data (12 bytes)
            
        Returns:
            Environmental data object
        """
        if len(data) != cls.SIZE:
            raise SerializationError(f"Invalid data length: {len(data)} (expected {cls.SIZE})")
            
        try:
            unpacked = struct.unpack(cls.FORMAT, data)
            return EnvironmentalData(
                co2_ppm=unpacked[0],
                temp_x10=unpacked[1],
                rh_x10=unpacked[2],
                light_raw=unpacked[3],
                uptime_ms=unpacked[4]
            )
        except Exception as e:
            logger.error(f"Error unpacking environmental data: {e}")
            raise SerializationError(f"Failed to unpack environmental data: {e}")


class ControlTargetsSerializer:
    """Serializer for control targets data"""
    
    FORMAT = '<hhHHBHHH'  # s16, s16, u16, u16, u8, u16, u16, u16 (little-endian)
    SIZE = 15  # bytes
    
    @classmethod
    def pack(cls, data: ControlTargets) -> bytes:
        """Pack control targets data to binary format
        
        Data format (15 bytes total):
        - Temperature min × 10 (s16, 2 bytes)
        - Temperature max × 10 (s16, 2 bytes)
        - Humidity min × 10 (u16, 2 bytes)
        - CO₂ max (u16, 2 bytes)
        - Light mode (u8, 1 byte): 0=OFF, 1=ON, 2=CYCLE
        - On minutes (u16, 2 bytes)
        - Off minutes (u16, 2 bytes)
        - Reserved (u16, 2 bytes)
        
        Args:
            data: Control targets object
            
        Returns:
            Packed binary data (15 bytes)
        """
        try:
            return struct.pack(cls.FORMAT,
                data.temp_min_x10,
                data.temp_max_x10,
                data.rh_min_x10,
                data.co2_max,
                data.light_mode,
                data.on_minutes,
                data.off_minutes,
                0  # Reserved
            )
        except Exception as e:
            logger.error(f"Error packing control targets: {e}")
            raise SerializationError(f"Failed to pack control targets: {e}")
    
    @classmethod
    def unpack(cls, data: bytes) -> ControlTargets:
        """Unpack binary data to control targets object
        
        Args:
            data: Binary data (15 bytes)
            
        Returns:
            Control targets object
        """
        if len(data) != cls.SIZE:
            raise SerializationError(f"Invalid data length: {len(data)} (expected {cls.SIZE})")
            
        try:
            unpacked = struct.unpack(cls.FORMAT, data)
            return ControlTargets(
                temp_min_x10=unpacked[0],
                temp_max_x10=unpacked[1], 
                rh_min_x10=unpacked[2],
                co2_max=unpacked[3],
                light_mode=unpacked[4],
                on_minutes=unpacked[5],
                off_minutes=unpacked[6]
            )
        except Exception as e:
            logger.error(f"Error unpacking control targets: {e}")
            raise SerializationError(f"Failed to unpack control targets: {e}")


class StageStateSerializer:
    """Serializer for stage state data"""
    
    FORMAT = '<BBBIHB'  # u8, u8, u8, u32, u16, u8 (little-endian)
    SIZE = 10  # bytes
    
    @classmethod
    def pack(cls, data: StageStateData) -> bytes:
        """Pack stage state data to binary format
        
        Data format (10 bytes total):
        - Mode (u8, 1 byte): 0=FULL, 1=SEMI, 2=MANUAL
        - Species ID (u8, 1 byte)
        - Stage ID (u8, 1 byte)
        - Stage start timestamp (u32, 4 bytes)
        - Expected days (u16, 2 bytes)
        
        Args:
            data: Stage state object
            
        Returns:
            Packed binary data (10 bytes)
        """
        try:
            return struct.pack(cls.FORMAT,
                data.mode,
                data.species_id,
                data.stage_id,
                data.stage_start_ts,
                data.expected_days,
                0  # Padding byte
            )
        except Exception as e:
            logger.error(f"Error packing stage state: {e}")
            raise SerializationError(f"Failed to pack stage state: {e}")
    
    @classmethod
    def unpack(cls, data: bytes) -> StageStateData:
        """Unpack binary data to stage state object
        
        Args:
            data: Binary data (10 bytes)
            
        Returns:
            Stage state object
        """
        if len(data) != cls.SIZE:
            raise SerializationError(f"Invalid data length: {len(data)} (expected {cls.SIZE})")
            
        try:
            unpacked = struct.unpack(cls.FORMAT, data)
            return StageStateData(
                mode=unpacked[0],
                species_id=unpacked[1],
                stage_id=unpacked[2], 
                stage_start_ts=unpacked[3],
                expected_days=unpacked[4]
            )
        except Exception as e:
            logger.error(f"Error unpacking stage state: {e}")
            raise SerializationError(f"Failed to unpack stage state: {e}")


class OverrideBitsSerializer:
    """Serializer for override bits data"""
    
    FORMAT = '<H'  # u16 (little-endian)
    SIZE = 2  # bytes
    
    @classmethod
    def pack(cls, bits: int) -> bytes:
        """Pack override bits to binary format
        
        Data format (2 bytes total):
        - Override bits (u16, 2 bytes):
          bit0: LIGHT override
          bit1: FAN override  
          bit2: MIST override
          bit3: HEATER override
          bit7: DISABLE_AUTOMATION
          
        Args:
            bits: Override bits value
            
        Returns:
            Packed binary data (2 bytes)
        """
        try:
            return struct.pack(cls.FORMAT, bits)
        except Exception as e:
            logger.error(f"Error packing override bits: {e}")
            raise SerializationError(f"Failed to pack override bits: {e}")
    
    @classmethod
    def unpack(cls, data: bytes) -> int:
        """Unpack binary data to override bits value
        
        Args:
            data: Binary data (2 bytes)
            
        Returns:
            Override bits value
        """
        if len(data) != cls.SIZE:
            raise SerializationError(f"Invalid data length: {len(data)} (expected {cls.SIZE})")
            
        try:
            return struct.unpack(cls.FORMAT, data)[0]
        except Exception as e:
            logger.error(f"Error unpacking override bits: {e}")
            raise SerializationError(f"Failed to unpack override bits: {e}")


class StatusFlagsSerializer:
    """Serializer for status flags data"""
    
    FORMAT = '<HH'  # u16, u16 (little-endian)
    SIZE = 4  # bytes
    
    @classmethod
    def pack(cls, flags: int) -> bytes:
        """Pack status flags to binary format
        
        Data format (4 bytes total):
        - Status flags (u16, 2 bytes):
          bit0: SENSOR_ERROR
          bit1: CONTROL_ERROR
          bit2: STAGE_READY
          bit3: THRESHOLD_ALARM
          bit4: CONNECTIVITY
          bit7: SIMULATION
        - Reserved (u16, 2 bytes)
          
        Args:
            flags: Status flags value
            
        Returns:
            Packed binary data (4 bytes)
        """
        try:
            return struct.pack(cls.FORMAT, flags, 0)  # flags, reserved
        except Exception as e:
            logger.error(f"Error packing status flags: {e}")
            raise SerializationError(f"Failed to pack status flags: {e}")
    
    @classmethod
    def unpack(cls, data: bytes) -> int:
        """Unpack binary data to status flags value
        
        Args:
            data: Binary data (4 bytes)
            
        Returns:
            Status flags value
        """
        if len(data) != cls.SIZE:
            raise SerializationError(f"Invalid data length: {len(data)} (expected {cls.SIZE})")
            
        try:
            return struct.unpack(cls.FORMAT, data)[0]  # Return only flags, ignore reserved
        except Exception as e:
            logger.error(f"Error unpacking status flags: {e}")
            raise SerializationError(f"Failed to unpack status flags: {e}")


class DataConverter:
    """Utility class for converting between data objects and dictionaries"""
    
    @staticmethod
    def control_targets_from_dict(data: Dict[str, Any]) -> ControlTargets:
        """Convert dictionary data to ControlTargets object
        
        Args:
            data: Dictionary with control data
            
        Returns:
            ControlTargets object
        """
        targets = ControlTargets.create_default()
        
        try:
            # Update from threshold data with safe coercion
            if 'temp_min' in data and data['temp_min'] is not None:
                try:
                    targets.temp_min_x10 = int(float(data['temp_min']) * 10)
                except Exception:
                    logger.warning("Invalid temp_min value; keeping default")
            if 'temp_max' in data and data['temp_max'] is not None:
                try:
                    targets.temp_max_x10 = int(float(data['temp_max']) * 10)
                except Exception:
                    logger.warning("Invalid temp_max value; keeping default")
            if 'rh_min' in data and data['rh_min'] is not None:
                try:
                    targets.rh_min_x10 = int(float(data['rh_min']) * 10)
                except Exception:
                    logger.warning("Invalid rh_min value; keeping default")
            if 'co2_max' in data and data['co2_max'] is not None:
                try:
                    targets.co2_max = int(float(data['co2_max']))
                except Exception:
                    logger.warning("Invalid co2_max value; keeping default")

            # Update from light schedule data with robust type handling
            if 'light' in data:
                light_val = data['light']
                if isinstance(light_val, dict):
                    mode = str(light_val.get('mode', 'off')).lower()
                    if mode == 'off':
                        targets.light_mode = 0
                    elif mode == 'on':
                        targets.light_mode = 1
                    elif mode == 'cycle':
                        targets.light_mode = 2
                        targets.on_minutes = int(light_val.get('on_min', 0) or 0)
                        targets.off_minutes = int(light_val.get('off_min', 0) or 0)
                elif isinstance(light_val, bool):
                    targets.light_mode = 1 if light_val else 0
                elif isinstance(light_val, str):
                    mode = light_val.lower()
                    if mode == 'off':
                        targets.light_mode = 0
                    elif mode == 'on':
                        targets.light_mode = 1
                    elif mode == 'cycle':
                        targets.light_mode = 2
                        targets.on_minutes = 0
                        targets.off_minutes = 0
                else:
                    # Unsupported numeric/object types default to no change (OFF)
                    logger.debug(f"Unsupported light value type: {type(light_val).__name__}; keeping defaults")

        except Exception as e:
            logger.error(f"Error converting control targets from dict: {e}")
            
        return targets
    
    @staticmethod
    def control_targets_to_dict(targets: ControlTargets) -> Dict[str, Any]:
        """Convert ControlTargets object to dictionary format
        
        Args:
            targets: Control targets to convert
            
        Returns:
            Dictionary representation
        """
        mode_name = LIGHT_MODES[targets.light_mode] if targets.light_mode < 3 else 'off'
        
        result = {
            'temp_min': targets.temp_min_x10 / 10.0,
            'temp_max': targets.temp_max_x10 / 10.0,
            'rh_min': targets.rh_min_x10 / 10.0,
            'co2_max': targets.co2_max,
            'light': {
                'mode': mode_name
            }
        }
        
        if targets.light_mode == 2:  # CYCLE mode
            result['light']['on_min'] = targets.on_minutes
            result['light']['off_min'] = targets.off_minutes
            
        return result
    
    @staticmethod
    def stage_state_from_dict(data: Dict[str, Any]) -> StageStateData:
        """Convert dictionary data to StageStateData object
        
        Args:
            data: Dictionary with stage data
            
        Returns:
            StageStateData object
        """
        stage_data = StageStateData.create_empty()
        
        try:
            # Update mode
            if 'mode' in data:
                mode_str = data['mode'].upper()
                if mode_str == 'FULL':
                    stage_data.mode = 0
                elif mode_str == 'SEMI':
                    stage_data.mode = 1
                elif mode_str == 'MANUAL':
                    stage_data.mode = 2
                    
            # Update species (convert string to ID)
            if 'species' in data:
                stage_data.species_id = SPECIES_MAP.get(data['species'], 0)
                
            # Update stage (convert string to ID)
            if 'stage' in data:
                stage_data.stage_id = STAGE_MAP.get(data['stage'], 0)
                
            # Update start timestamp
            if 'stage_start_ts' in data:
                stage_data.stage_start_ts = int(data['stage_start_ts'])
                
            # Update expected days
            if 'expected_days' in data:
                stage_data.expected_days = int(data['expected_days'])
                
        except Exception as e:
            logger.error(f"Error converting stage state from dict: {e}")
            
        return stage_data
    
    @staticmethod
    def stage_state_to_dict(stage: StageStateData) -> Dict[str, Any]:
        """Convert StageStateData object to dictionary format
        
        Args:
            stage: Stage state to convert
            
        Returns:
            Dictionary representation
        """
        return {
            'mode': MODE_NAMES[stage.mode] if stage.mode < 3 else 'MANUAL',
            'species': SPECIES_REVERSE_MAP.get(stage.species_id, 'Unknown'),
            'stage': STAGE_REVERSE_MAP.get(stage.stage_id, 'Unknown'),
            'stage_start_ts': stage.stage_start_ts,
            'expected_days': stage.expected_days
        }
    
    @staticmethod
    def override_bits_to_dict(bits: int) -> Dict[str, Any]:
        """Convert override bits to dictionary format
        
        Args:
            bits: Override bits value
            
        Returns:
            Dictionary with override settings
        """
        return {
            'light_override': bool(bits & OverrideBits.LIGHT),
            'fan_override': bool(bits & OverrideBits.FAN),
            'mist_override': bool(bits & OverrideBits.MIST),
            'heater_override': bool(bits & OverrideBits.HEATER),
            'disable_automation': bool(bits & OverrideBits.DISABLE_AUTO),
            'raw_bits': bits
        }


# Export all classes
__all__ = [
    'SerializationError',
    'EnvironmentalSerializer', 'ControlTargetsSerializer', 'StageStateSerializer',
    'OverrideBitsSerializer', 'StatusFlagsSerializer', 'DataConverter'
]