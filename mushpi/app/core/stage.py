"""
MushPi Stage Management System

Manages mushroom cultivation stages with automatic progression and threshold management.
Supports FULL, SEMI, and MANUAL modes for different levels of automation.
"""

import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Optional, Tuple, Any
from enum import Enum
from dataclasses import dataclass

# Logging Setup
logger = logging.getLogger(__name__)


class StageMode(Enum):
    """Stage management modes"""
    FULL = "full"        # Auto targets + auto stage advance
    SEMI = "semi"        # Auto targets; propose stage change, require confirmation  
    MANUAL = "manual"    # No automatic control (UI/overrides only)


@dataclass
class StageInfo:
    """Information about a cultivation stage"""
    species: str
    stage: str
    start_time: datetime
    expected_days: int
    mode: StageMode
    thresholds: Dict[str, Any]


class StageManager:
    """Manages mushroom cultivation stages and progression"""
    
    def __init__(self, config_path: Optional[Path] = None, thresholds_path: Optional[Path] = None):
        self.config_path = config_path or Path("data/stage_config.json")
        self.thresholds_path = thresholds_path or Path("config/thresholds.json")
        self.current_stage: Optional[StageInfo] = None
        self.compliance_history: list = []
        
        # Create directories if they don't exist
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Load current configuration
        self._load_configuration()
        
    def _load_configuration(self) -> None:
        """Load current stage configuration"""
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    
                self.current_stage = StageInfo(
                    species=config.get('species', 'Oyster'),
                    stage=config.get('stage', 'Incubation'),
                    start_time=datetime.fromisoformat(config.get('start_time', datetime.now().isoformat())),
                    expected_days=config.get('expected_days', 14),
                    mode=StageMode(config.get('mode', 'semi')),
                    thresholds=config.get('thresholds', {})
                )
                logger.info(f"Loaded stage config: {self.current_stage.species} - {self.current_stage.stage}")
            else:
                # Create default configuration
                self._create_default_configuration()
                
        except Exception as e:
            logger.error(f"Error loading stage configuration: {e}")
            self._create_default_configuration()
            
    def _create_default_configuration(self) -> None:
        """Create default stage configuration"""
        logger.info("Creating default stage configuration")
        
        # Default to Oyster Pinning stage (most common for light control)
        default_stage = StageInfo(
            species='Oyster',
            stage='Pinning',
            start_time=datetime.now(),
            expected_days=5,
            mode=StageMode.SEMI,
            thresholds={}
        )
        
        self.current_stage = default_stage
        self._save_configuration()
        
    def _save_configuration(self) -> None:
        """Save current stage configuration"""
        if not self.current_stage:
            return
            
        config = {
            'species': self.current_stage.species,
            'stage': self.current_stage.stage,
            'start_time': self.current_stage.start_time.isoformat(),
            'expected_days': self.current_stage.expected_days,
            'mode': self.current_stage.mode.value,
            'thresholds': self.current_stage.thresholds
        }
        
        try:
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=2)
            logger.info(f"Stage configuration saved to {self.config_path}")
        except Exception as e:
            logger.error(f"Error saving stage configuration: {e}")
            
    def get_current_stage(self) -> Optional[StageInfo]:
        """Get current stage information"""
        return self.current_stage
        
    def get_current_thresholds(self) -> Dict[str, Any]:
        """Get thresholds for current stage"""
        if not self.current_stage:
            return {}
            
        try:
            # Load thresholds from main config file
            with open(self.thresholds_path, 'r') as f:
                all_thresholds = json.load(f)
                
            species_thresholds = all_thresholds.get(self.current_stage.species, {})
            stage_thresholds = species_thresholds.get(self.current_stage.stage, {})
            
            return stage_thresholds
            
        except Exception as e:
            logger.error(f"Error loading thresholds: {e}")
            return {}
            
    def get_light_schedule(self) -> Dict[str, Any]:
        """Get light schedule for current stage"""
        thresholds = self.get_current_thresholds()
        return thresholds.get('light', {'mode': 'off'})
        
    def set_stage(self, species: str, stage: str, mode: Optional[StageMode] = None) -> bool:
        """Set current stage manually"""
        try:
            # Load thresholds to validate stage exists
            with open(self.thresholds_path, 'r') as f:
                all_thresholds = json.load(f)
                
            if species not in all_thresholds:
                logger.error(f"Unknown species: {species}")
                return False
                
            if stage not in all_thresholds[species]:
                logger.error(f"Unknown stage: {stage} for species {species}")
                return False
                
            # Get expected days for this stage
            stage_config = all_thresholds[species][stage]
            expected_days = stage_config.get('expected_days', 0)
            
            # Update current stage
            old_stage = f"{self.current_stage.species}-{self.current_stage.stage}" if self.current_stage else "None"
            
            self.current_stage = StageInfo(
                species=species,
                stage=stage,
                start_time=datetime.now(),
                expected_days=expected_days,
                mode=mode or (self.current_stage.mode if self.current_stage else StageMode.SEMI),
                thresholds=stage_config
            )
            
            self._save_configuration()
            logger.info(f"Stage changed: {old_stage} -> {species}-{stage}")
            return True
            
        except Exception as e:
            logger.error(f"Error setting stage: {e}")
            return False
            
    def get_stage_age_days(self) -> float:
        """Get age of current stage in days"""
        if not self.current_stage:
            return 0.0
            
        age = datetime.now() - self.current_stage.start_time
        return age.total_seconds() / (24 * 3600)
        
    def should_advance_stage(self) -> Tuple[bool, str]:
        """Check if stage should advance (for FULL mode)"""
        if not self.current_stage or self.current_stage.mode != StageMode.FULL:
            return False, "Not in FULL mode"
            
        age_days = self.get_stage_age_days()
        
        # Check if minimum time has passed
        if age_days < self.current_stage.expected_days:
            return False, f"Too early ({age_days:.1f}/{self.current_stage.expected_days} days)"
            
        # For automatic advancement, would need to check compliance history
        # This is a simplified version
        if age_days > self.current_stage.expected_days * 1.2:  # 20% over expected
            return True, f"Overdue ({age_days:.1f}/{self.current_stage.expected_days} days)"
            
        return False, "Conditions not met for advancement"
        
    def get_status(self) -> Dict[str, Any]:
        """Get current stage status"""
        if not self.current_stage:
            return {
                'configured': False,
                'error': 'No stage configuration'
            }
            
        age_days = self.get_stage_age_days()
        light_schedule = self.get_light_schedule()
        
        return {
            'configured': True,
            'species': self.current_stage.species,
            'stage': self.current_stage.stage,
            'mode': self.current_stage.mode.value,
            'age_days': round(age_days, 1),
            'expected_days': self.current_stage.expected_days,
            'start_time': self.current_stage.start_time.isoformat(),
            'light_schedule': light_schedule,
            'progress_percent': min(100, (age_days / self.current_stage.expected_days) * 100) if self.current_stage.expected_days > 0 else 0
        }


# Create global instance
stage_manager = StageManager()

# Export for external use
__all__ = ['StageManager', 'StageMode', 'StageInfo', 'stage_manager']