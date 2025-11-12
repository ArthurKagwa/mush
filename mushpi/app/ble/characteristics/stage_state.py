"""
Stage State Characteristic

Handles growth stage state information.
Supports read and write operations.
"""

import logging
from typing import Optional, Callable

from ..base import ReadWriteCharacteristic
from ...models.ble_dataclasses import STAGE_STATE_UUID, StageStateData
from ..serialization import StageStateSerializer, DataConverter
from ..validators import StageStateValidator

logger = logging.getLogger(__name__)


class StageStateCharacteristic(ReadWriteCharacteristic):
    """Stage state characteristic (read/write)"""
    
    def __init__(self, service=None, simulation_mode: bool = False):
        """Initialize stage state characteristic
        
        Args:
            service: BLE service object
            simulation_mode: Whether running in simulation mode
        """
        # Data and callbacks must be set BEFORE calling super().__init__()
        # because base class will call _handle_read() during initialization
        self.stage_data = StageStateData.create_empty()
        self.get_stage_data: Optional[Callable] = None
        self.set_stage_state: Optional[Callable] = None
        
        super().__init__(STAGE_STATE_UUID, service, simulation_mode)
        
    def _handle_read(self, options) -> bytes:
        """Read callback for stage state
        
        Args:
            options: BLE read options
            
        Returns:
            Packed binary data (10 bytes)
        """
        try:
            # Update current stage state from stage system
            if self.get_stage_data:
                stage_data = self.get_stage_data()
                if stage_data:
                    self.stage_data = DataConverter.stage_state_from_dict(stage_data)
            
            # Pack and return data
            data = StageStateSerializer.pack(self.stage_data)
            
            logger.debug(f"BLE stage read: mode={self.stage_data.mode}, "
                        f"species={self.stage_data.species_id}")
            return data
            
        except Exception as e:
            logger.error(f"Error reading stage state: {e}")
            return b'\x00' * StageStateSerializer.SIZE  # Return zeros on error
    
    def _handle_write(self, value: bytes, options):
        """Write callback for stage state
        
        Args:
            value: Binary data to write (10 bytes)
            options: BLE write options
        """
        try:
            if len(value) != StageStateSerializer.SIZE:
                logger.warning(f"Invalid stage state data length: {len(value)} "
                              f"(expected {StageStateSerializer.SIZE})")
                return
                
            # Unpack data
            new_stage = StageStateSerializer.unpack(value)
            
            # Validate values
            if not StageStateValidator.validate(new_stage):
                logger.warning("Invalid stage state values received")
                return
                
            # Update local copy
            self.stage_data = new_stage
                
            # Apply to stage system
            if self.set_stage_state:
                stage_dict = DataConverter.stage_state_to_dict(new_stage)
                self.set_stage_state(stage_dict)
                
            logger.info(f"BLE stage state updated: mode={new_stage.mode}, "
                       f"species={new_stage.species_id}")
            
        except Exception as e:
            logger.error(f"Error writing stage state: {e}")
    
    def set_stage_callbacks(self, get_callback: Callable, set_callback: Callable):
        """Set callback functions for stage data access
        
        Args:
            get_callback: Function to get current stage data
            set_callback: Function to set new stage state
        """
        self.get_stage_data = get_callback
        self.set_stage_state = set_callback
    
    def update_stage(self, stage: StageStateData):
        """Update stage state from external source
        
        Args:
            stage: New stage state
        """
        if StageStateValidator.validate(stage):
            self.stage_data = stage
            logger.debug("Stage state updated from external source")
        else:
            logger.warning("Invalid stage state provided for update")