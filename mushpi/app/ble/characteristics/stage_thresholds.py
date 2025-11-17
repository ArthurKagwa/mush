"""
Stage Thresholds Characteristic

Allows reading and writing threshold configurations for any species/stage combination.
This enables the Flutter app's Stage page to view and edit thresholds.
"""

import json
import logging
from typing import Optional, Callable, Dict, Any

from ..base import ReadWriteCharacteristic

logger = logging.getLogger(__name__)


class StageThresholdsCharacteristic(ReadWriteCharacteristic):
    """
    BLE characteristic for managing stage thresholds
    
    Format (JSON):
    Read Request: {"species": "Oyster", "stage": "Pinning"}
    Read Response: {
        "species": "Oyster",
        "stage": "Pinning",
        "temp_min": 18.0,
        "temp_max": 22.0,
        "rh_min": 90.0,
        "co2_max": 1000,
        "light": {"mode": "cycle", "on_min": 960, "off_min": 480},
        "expected_days": 5
    }
    
    Write: Same format as Read Response (updates that stage's thresholds)
    """
    
    def __init__(
        self,
        service,
        simulation_mode: bool = False
    ):
        """
        Initialize stage thresholds characteristic
        
        Args:
            service: BLE GATT service to attach to
            simulation_mode: Whether running in simulation mode
        """
        super().__init__(
            uuid="12345678-1234-5678-1234-56789abcdef9",  # Custom UUID for stage thresholds
            service=service,
            simulation_mode=simulation_mode
        )
        self.get_callback = None
        self.set_callback = None
        self.last_request = {"species": "Oyster", "stage": "Incubation"}  # Default request
    
    def set_stage_thresholds_callbacks(
        self,
        get_callback: Callable[[str, str], Dict[str, Any]],
        set_callback: Callable[[str, str, Dict[str, Any]], bool]
    ):
        """Set the callbacks for getting and setting stage thresholds
        
        Args:
            get_callback: Function(species, stage) -> thresholds_dict
            set_callback: Function(species, stage, thresholds) -> success
        """
        self.get_callback = get_callback
        self.set_callback = set_callback
        logger.debug("Stage thresholds callbacks configured")
        
    def _handle_read(self, options: dict) -> bytes:
        """Read thresholds for requested species/stage"""
        try:
            # Use hasattr since _handle_read is called during __init__ before callbacks are set
            if not hasattr(self, 'get_callback') or self.get_callback is None:
                error_response = {"error": "Callback not configured"}
                return json.dumps(error_response).encode('utf-8')
            
            # Use last requested species/stage (set via write for query)
            species = self.last_request.get("species", "Oyster")
            stage = self.last_request.get("stage", "Incubation")
            
            logger.info(f"📖 BLE reading stage thresholds: {species} - {stage}")
            
            # Get thresholds from callback
            thresholds = self.get_callback(species, stage)
            
            if thresholds:
                # Add species and stage to response
                response = {
                    "species": species,
                    "stage": stage,
                    **thresholds
                }
                
                json_str = json.dumps(response)
                logger.debug(f"Sending stage thresholds: {json_str}")
                return json_str.encode('utf-8')
            else:
                error_response = {
                    "error": "Stage not found",
                    "species": species,
                    "stage": stage
                }
                return json.dumps(error_response).encode('utf-8')
                
        except Exception as e:
            logger.error(f"Error reading stage thresholds: {e}", exc_info=True)
            error_response = {"error": str(e)}
            return json.dumps(error_response).encode('utf-8')
    
    def _handle_write(self, value: bytes, options: dict) -> None:
        """Write thresholds for a species/stage or set query for next read"""
        try:
            data = json.loads(value.decode('utf-8'))
            logger.info(f"✏️  BLE stage thresholds write: {data}")
            
            species = data.get("species")
            stage = data.get("stage")
            
            if not species or not stage:
                logger.error("Missing species or stage in write data")
                return
            
            # Check if this is a query (just species/stage) or an update (has threshold values)
            threshold_keys = ['temp_min', 'temp_max', 'rh_min', 'rh_max', 'co2_max', 'light_min', 'light_max', 'light', 'expected_days']
            has_thresholds = any(key in data for key in threshold_keys)
            
            if has_thresholds:
                # Use hasattr to safely check if callback exists
                if not hasattr(self, 'set_callback') or self.set_callback is None:
                    logger.error("Set callback not configured")
                    return
                
                # This is an update - extract threshold values
                thresholds = {k: v for k, v in data.items() if k not in ['species', 'stage']}
                
                # Update thresholds via callback
                success = self.set_callback(species, stage, thresholds)
                
                if success:
                    logger.info(f"✅ Updated thresholds for {species} - {stage}")
                else:
                    logger.error(f"Failed to update thresholds for {species} - {stage}")
            else:
                # This is a query - store for next read
                self.last_request = {"species": species, "stage": stage}
                logger.info(f"🔍 Query set for next read: {species} - {stage}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in stage thresholds write: {e}")
        except Exception as e:
            logger.error(f"Error processing stage thresholds write: {e}", exc_info=True)
