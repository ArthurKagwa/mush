"""
BLE Data Validators

Validation utilities for BLE GATT data to ensure data integrity.
"""

import time
import logging
from typing import Union

from ..models.ble_dataclasses import ControlTargets, StageStateData, OverrideBits

logger = logging.getLogger(__name__)


class ValidationError(Exception):
    """Exception for data validation errors"""
    pass


class ControlTargetsValidator:
    """Validator for control target values"""
    
    # Temperature range in tenths of degrees (-10°C to 50°C)
    TEMP_MIN = -100
    TEMP_MAX = 500
    
    # Humidity range in tenths of percent (0% to 100%)
    RH_MIN = 0
    RH_MAX = 1000
    
    # CO₂ range in ppm (400 to 10000 ppm)
    CO2_MIN = 400
    CO2_MAX = 10000
    
    # Time range in minutes (0 to 24 hours)
    TIME_MIN = 0
    TIME_MAX = 1440
    
    @classmethod
    def validate(cls, targets: ControlTargets) -> bool:
        """Validate control target values
        
        Args:
            targets: Control targets to validate
            
        Returns:
            True if valid, False otherwise
        """
        try:
            # Temperature range checks (in tenths of degrees)
            if targets.temp_min_x10 < cls.TEMP_MIN or targets.temp_min_x10 > cls.TEMP_MAX:
                logger.warning(f"Invalid temp_min_x10: {targets.temp_min_x10}")
                return False
            if targets.temp_max_x10 < cls.TEMP_MIN or targets.temp_max_x10 > cls.TEMP_MAX:
                logger.warning(f"Invalid temp_max_x10: {targets.temp_max_x10}")
                return False
            if targets.temp_min_x10 >= targets.temp_max_x10:
                logger.warning(f"temp_min >= temp_max: {targets.temp_min_x10} >= {targets.temp_max_x10}")
                return False
                
            # Humidity range checks (in tenths of percent)
            if targets.rh_min_x10 < cls.RH_MIN or targets.rh_min_x10 > cls.RH_MAX:
                logger.warning(f"Invalid rh_min_x10: {targets.rh_min_x10}")
                return False
                
            # CO₂ range checks
            if targets.co2_max < cls.CO2_MIN or targets.co2_max > cls.CO2_MAX:
                logger.warning(f"Invalid co2_max: {targets.co2_max}")
                return False
                
            # Light mode checks
            if targets.light_mode not in [0, 1, 2]:  # OFF, ON, CYCLE
                logger.warning(f"Invalid light_mode: {targets.light_mode}")
                return False
                
            # Time range checks (minutes)
            if targets.on_minutes < cls.TIME_MIN or targets.on_minutes > cls.TIME_MAX:
                logger.warning(f"Invalid on_minutes: {targets.on_minutes}")
                return False
            if targets.off_minutes < cls.TIME_MIN or targets.off_minutes > cls.TIME_MAX:
                logger.warning(f"Invalid off_minutes: {targets.off_minutes}")
                return False
                
            return True
            
        except Exception as e:
            logger.error(f"Error validating control targets: {e}")
            return False


class StageStateValidator:
    """Validator for stage state values"""
    
    # Valid mode values
    VALID_MODES = [0, 1, 2]  # FULL, SEMI, MANUAL
    
    # ID range validation
    ID_MIN = 0
    ID_MAX = 255
    
    # Days range validation
    DAYS_MIN = 0
    DAYS_MAX = 365
    
    @classmethod
    def validate(cls, stage: StageStateData) -> bool:
        """Validate stage state values
        
        Args:
            stage: Stage state to validate
            
        Returns:
            True if valid, False otherwise
        """
        try:
            # Mode validation
            if stage.mode not in cls.VALID_MODES:
                logger.warning(f"Invalid mode: {stage.mode}")
                return False
                
            # Species ID validation (0-255)
            if stage.species_id < cls.ID_MIN or stage.species_id > cls.ID_MAX:
                logger.warning(f"Invalid species_id: {stage.species_id}")
                return False
                
            # Stage ID validation (0-255)
            if stage.stage_id < cls.ID_MIN or stage.stage_id > cls.ID_MAX:
                logger.warning(f"Invalid stage_id: {stage.stage_id}")
                return False
                
            # Timestamp validation (must be reasonable)
            current_time = int(time.time())
            if stage.stage_start_ts > current_time:  # Can't be in future
                logger.warning(f"stage_start_ts in future: {stage.stage_start_ts} > {current_time}")
                return False
            if stage.stage_start_ts < (current_time - 365 * 24 * 3600):  # Can't be > 1 year old
                logger.warning(f"stage_start_ts too old: {stage.stage_start_ts}")
                return False
                
            # Expected days validation (0-365 days)
            if stage.expected_days < cls.DAYS_MIN or stage.expected_days > cls.DAYS_MAX:
                logger.warning(f"Invalid expected_days: {stage.expected_days}")
                return False
                
            return True
            
        except Exception as e:
            logger.error(f"Error validating stage state: {e}")
            return False


class OverrideBitsValidator:
    """Validator for override bits values"""
    
    # Define valid override bits mask
    VALID_BITS_MASK = (OverrideBits.LIGHT | OverrideBits.FAN | 
                      OverrideBits.MIST | OverrideBits.HEATER | 
                      OverrideBits.DISABLE_AUTO)
    
    @classmethod
    def validate(cls, bits: Union[int, OverrideBits]) -> bool:
        """Validate override bits value
        
        Args:
            bits: Override bits value to validate
            
        Returns:
            True if valid, False otherwise
        """
        try:
            # Convert to int if needed
            if isinstance(bits, OverrideBits):
                bits = int(bits)
                
            # Check if any invalid bits are set
            if bits & ~cls.VALID_BITS_MASK:
                logger.warning(f"Invalid override bits: 0x{bits:04X} "
                              f"(valid mask: 0x{cls.VALID_BITS_MASK:04X})")
                return False
                
            return True
            
        except Exception as e:
            logger.error(f"Error validating override bits: {e}")
            return False


class StatusFlagsValidator:
    """Validator for status flags values"""
    
    # We don't need strict validation for status flags since they're read-only
    # and set internally by the system
    
    @classmethod
    def validate(cls, flags: int) -> bool:
        """Validate status flags value (minimal validation)
        
        Args:
            flags: Status flags value to validate
            
        Returns:
            True (status flags are always valid)
        """
        return True


# Export all validators
__all__ = [
    'ValidationError',
    'ControlTargetsValidator', 'StageStateValidator', 
    'OverrideBitsValidator', 'StatusFlagsValidator'
]