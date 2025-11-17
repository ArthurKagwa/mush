"""
MushPi Stage Management System

Manages mushroom cultivation stages with automatic progression and threshold management.
Supports FULL, SEMI, and MANUAL modes for different levels of automation.
Database-backed for persistent threshold storage.
"""

import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Optional, Tuple, Any
from enum import Enum
from dataclasses import dataclass

# Import centralized configuration
from .config import config
from ..database.manager import DatabaseManager

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
    
    def __init__(self, config_path: Optional[Path] = None, thresholds_path: Optional[Path] = None, db_manager: Optional[DatabaseManager] = None):
        """Initialize StageManager with database-backed configuration
        
        Args:
            config_path: Optional override for stage config path (uses config.stage.config_path if not provided)
            thresholds_path: Optional override for thresholds path (for migration only)
            db_manager: Optional DatabaseManager instance
        """
        # Use centralized configuration if paths not provided
        self.config_path = config_path or config.stage.config_path
        self.thresholds_path = thresholds_path or config.thresholds_path
        self.db_manager = db_manager or DatabaseManager()
        self.current_stage: Optional[StageInfo] = None
        self.compliance_history: list = []
        
        # Create directories if they don't exist
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Migrate thresholds from JSON to database (one-time operation)
        self._migrate_thresholds_if_needed()
        
        # Load current configuration
        self._load_configuration()
        
    def _migrate_thresholds_if_needed(self) -> None:
        """Migrate thresholds from JSON to database if not already done"""
        try:
            # Check if database already has thresholds
            existing = self.db_manager.get_all_stage_thresholds()
            if existing:
                logger.debug(f"Database already contains {len(existing)} stage threshold configurations")
                return
            
            # Load from JSON and migrate
            if self.thresholds_path.exists():
                logger.info("Migrating thresholds from JSON to database...")
                with open(self.thresholds_path, 'r') as f:
                    thresholds_data = json.load(f)
                
                self.db_manager.migrate_thresholds_from_json(thresholds_data)
                logger.info("✅ Threshold migration complete")
            else:
                logger.warning(f"Thresholds file not found: {self.thresholds_path}")
                
        except Exception as e:
            logger.error(f"Error during threshold migration: {e}", exc_info=True)
        
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
        """Create default stage configuration using centralized config defaults"""
        logger.info("Creating default stage configuration")
        
        # Use defaults from centralized configuration
        default_stage = StageInfo(
            species=config.stage.default_species,
            stage=config.stage.default_stage,
            start_time=datetime.now(),
            expected_days=config.stage.default_days,
            mode=StageMode(config.stage.default_mode),
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
        """Get thresholds for current stage from database"""
        if not self.current_stage:
            return {}
            
        try:
            # Load thresholds from database
            thresholds = self.db_manager.get_stage_thresholds(
                self.current_stage.species,
                self.current_stage.stage
            )
            
            if thresholds:
                # Convert to format expected by control system
                # Preserve light as nested dict for backward compatibility
                result = dict(thresholds)
                if 'light_mode' in result:
                    result['light'] = {
                        'mode': result.get('light_mode', 'off'),
                        'on_min': result.get('light_on_minutes', 0),
                        'off_min': result.get('light_off_minutes', 0)
                    }
                return result
            else:
                logger.warning(f"No thresholds found in database for {self.current_stage.species} - {self.current_stage.stage}")
                return {}
            
        except Exception as e:
            logger.error(f"Error loading thresholds from database: {e}")
            return {}
            
    def get_light_schedule(self) -> Dict[str, Any]:
        """Get light schedule for current stage"""
        thresholds = self.get_current_thresholds()
        return thresholds.get('light', {'mode': 'off'})
    
    def update_stage_thresholds(self, species: str, stage: str, thresholds: Dict[str, Any]) -> bool:
        """Update thresholds for a specific species and stage in database
        
        Args:
            species: Species name (e.g., 'Oyster')
            stage: Stage name (e.g., 'Pinning')
            thresholds: Dictionary with threshold values (temp_min, temp_max, rh_min, etc.)
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.db_manager.save_stage_thresholds(species, stage, thresholds)
            logger.info(f"✅ Updated thresholds for {species} - {stage}")
            
            # If updating current stage, reload thresholds
            if self.current_stage and self.current_stage.species == species and self.current_stage.stage == stage:
                logger.info(f"♻️  Reloading current stage thresholds")
                return True
            
            return True
            
        except Exception as e:
            logger.error(f"Error updating stage thresholds: {e}")
            return False
    
    def update_current_stage_thresholds(self, thresholds: Dict[str, Any]) -> bool:
        """Update thresholds for the current active stage
        
        Args:
            thresholds: Dictionary with threshold values
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not self.current_stage:
            logger.error("No current stage set")
            return False
            
        return self.update_stage_thresholds(
            self.current_stage.species,
            self.current_stage.stage,
            thresholds
        )
    
    def get_all_species_stages(self) -> Dict[str, list]:
        """Get all available species and their stages from database
        
        Returns:
            Dictionary with species as keys and lists of stage names as values
        """
        try:
            all_thresholds = self.db_manager.get_all_stage_thresholds()
            species_stages = {}
            
            for threshold in all_thresholds:
                species = threshold['species']
                stage = threshold['stage']
                
                if species not in species_stages:
                    species_stages[species] = []
                species_stages[species].append(stage)
            
            return species_stages
            
        except Exception as e:
            logger.error(f"Error getting species/stages: {e}")
            return {}
    
    def get_stage_thresholds(self, species: str, stage: str) -> Dict[str, Any]:
        """Get thresholds for any species/stage combination (not just current)
        
        Args:
            species: Species name
            stage: Stage name
            
        Returns:
            Dictionary with threshold values
        """
        try:
            thresholds = self.db_manager.get_stage_thresholds(species, stage)
            
            if thresholds:
                # Convert to format with light as nested dict (remove flat keys)
                result = dict(thresholds)
                
                # Create nested light structure
                if 'light_mode' in result:
                    result['light'] = {
                        'mode': result.get('light_mode', 'off'),
                        'on_min': result.get('light_on_minutes', 0),
                        'off_min': result.get('light_off_minutes', 0)
                    }
                    # Remove flat light keys to avoid confusion
                    result.pop('light_mode', None)
                    result.pop('light_on_minutes', None)
                    result.pop('light_off_minutes', None)
                    result.pop('light_min', None)  # Not used in Flutter
                    result.pop('light_max', None)  # Not used in Flutter
                
                return result
            return {}
            
        except Exception as e:
            logger.error(f"Error getting stage thresholds: {e}")
            return {}
        
    def set_stage(self, species: str, stage: str, mode: Optional[StageMode] = None, start_time: Optional[datetime] = None) -> bool:
        """Set current stage manually
        
        Args:
            species: Species name
            stage: Stage name
            mode: Optional control mode (defaults to SEMI or current mode)
            start_time: Optional start time (defaults to now)
        """
        try:
            # Load thresholds from database to validate stage exists
            stage_thresholds = self.db_manager.get_stage_thresholds(species, stage)
                
            if not stage_thresholds:
                logger.warning(f"No database thresholds for {species} - {stage}, trying thresholds.json")
                # Fall back to thresholds.json
                if self.thresholds_path.exists():
                    with open(self.thresholds_path, 'r') as f:
                        thresholds_data = json.load(f)
                    
                    species_data = thresholds_data.get(species, {})
                    stage_data = species_data.get(stage, {})
                    
                    if stage_data:
                        stage_thresholds = stage_data
                        logger.info(f"✅ Loaded thresholds from thresholds.json for {species} - {stage}")
                    else:
                        logger.error(f"Unknown species/stage combination: {species} - {stage}")
                        return False
                else:
                    logger.error(f"Unknown species/stage combination: {species} - {stage}")
                    return False
                
            # Get expected days for this stage
            expected_days = stage_thresholds.get('expected_days', 0)
            
            # If expected_days is 0 and we got it from database, try thresholds.json as fallback
            if expected_days == 0 and self.thresholds_path.exists():
                try:
                    with open(self.thresholds_path, 'r') as f:
                        thresholds_data = json.load(f)
                    species_data = thresholds_data.get(species, {})
                    stage_data = species_data.get(stage, {})
                    json_expected_days = stage_data.get('expected_days', 0)
                    if json_expected_days > 0:
                        expected_days = json_expected_days
                        logger.info(f"📅 Using expected_days={expected_days} from thresholds.json for {species} - {stage}")
                except Exception as e:
                    logger.warning(f"Could not read expected_days from thresholds.json: {e}")
            
            # Update current stage
            old_stage = f"{self.current_stage.species}-{self.current_stage.stage}" if self.current_stage else "None"
            
            # Determine mode: use provided mode, or fallback to current/default
            # CRITICAL: Use explicit None check to avoid Python truthiness bug
            # (mode=0/FULL would be falsy and incorrectly skip to fallback)
            if mode is not None:
                new_mode = mode
            elif self.current_stage:
                new_mode = self.current_stage.mode
            else:
                new_mode = StageMode.SEMI
            
            self.current_stage = StageInfo(
                species=species,
                stage=stage,
                start_time=start_time or datetime.now(),
                expected_days=expected_days,
                mode=new_mode,
                thresholds=stage_thresholds
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
        
        # Check if expected days have been reached
        if age_days >= self.current_stage.expected_days:
            return True, f"Stage complete ({age_days:.1f}/{self.current_stage.expected_days} days elapsed)"
            
        return False, f"Stage in progress ({age_days:.1f}/{self.current_stage.expected_days} days)"
    
    def advance_stage(self) -> bool:
        """Advance to the next stage in the cultivation cycle
        
        Returns:
            bool: True if successfully advanced, False otherwise
        """
        if not self.current_stage:
            logger.error("No current stage to advance from")
            return False
        
        # Define stage progression order
        stage_order = {
            'Oyster': ['Incubation', 'Pinning', 'Fruiting', 'Harvest'],
            'Shiitake': ['Incubation', 'Pinning', 'Fruiting', 'Harvest'],
            "Lion's Mane": ['Incubation', 'Pinning', 'Fruiting', 'Harvest']
        }
        
        species = self.current_stage.species
        current_stage_name = self.current_stage.stage
        
        if species not in stage_order:
            logger.error(f"Unknown species: {species}")
            return False
        
        stages = stage_order[species]
        if current_stage_name not in stages:
            logger.error(f"Unknown stage: {current_stage_name}")
            return False
        
        current_index = stages.index(current_stage_name)
        if current_index >= len(stages) - 1:
            logger.info(f"Already at final stage: {current_stage_name}")
            return False
        
        next_stage_name = stages[current_index + 1]
        logger.info(f"🔄 Advancing from {current_stage_name} to {next_stage_name}")
        
        # Set the new stage with current time as start_time
        success = self.set_stage(
            species=species,
            stage=next_stage_name,
            mode=self.current_stage.mode,
            start_time=datetime.now()
        )
        
        if success:
            # Get the thresholds for the new stage and save with start_time to database
            new_thresholds = self.get_stage_thresholds(species, next_stage_name)
            if new_thresholds:
                # Add the start_time to the thresholds before saving to DB
                new_thresholds['start_time'] = datetime.now().isoformat()
                self.db_manager.save_stage_thresholds(species, next_stage_name, new_thresholds)
                logger.info(f"✅ Saved start_time to database for {species} - {next_stage_name}")
            
            logger.info(f"✅ Successfully advanced to {next_stage_name}")
            return True
        else:
            logger.error(f"❌ Failed to advance to {next_stage_name}")
            return False
        
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