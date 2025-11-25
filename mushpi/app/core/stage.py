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
            config_path: DEPRECATED - kept for backwards compatibility, not used anymore
            thresholds_path: Optional override for thresholds path (for migration only)
            db_manager: Optional DatabaseManager instance
        """
        # Use centralized configuration if paths not provided
        self.thresholds_path = thresholds_path or config.thresholds_path
        self.db_manager = db_manager or DatabaseManager()
        self.current_stage: Optional[StageInfo] = None
        self.compliance_history: list = []
        
        # Migrate thresholds from JSON to database (one-time operation)
        self._migrate_thresholds_if_needed()
        
        # Load current configuration from database
        self._load_configuration()
        
    def _migrate_thresholds_if_needed(self) -> None:
        """Migrate thresholds from JSON to database if not already done
        
        This migration runs ONLY ONCE per database. After first run, the migration
        flag is set and the JSON file is never read again, ensuring database is the
        single source of truth for stage thresholds.
        
        Migration will ONLY run if:
        1. Migration flag is not set (hasn't run before)
        2. Database is empty (no stage thresholds exist)
        3. Database file exists (database has been initialized)
        
        This ensures that user-configured thresholds are NEVER overwritten by the JSON file.
        """
        MIGRATION_NAME = "thresholds_json_migration"
        
        try:
            # CRITICAL: Check migration flag FIRST - if set, never run migration again
            if self.db_manager.has_migration_run(MIGRATION_NAME):
                logger.debug(f"Migration '{MIGRATION_NAME}' already completed, skipping")
                return
            
            # Check if database already has thresholds (even if migration flag not set)
            # If thresholds exist, user has configured them - DO NOT overwrite
            existing = self.db_manager.get_all_stage_thresholds()
            if existing and len(existing) > 0:
                logger.info(f"Database already contains {len(existing)} stage threshold configurations")
                logger.info("⚠️  Skipping migration - existing thresholds will not be overwritten")
                # Mark migration complete to prevent future attempts
                self.db_manager.mark_migration_complete(
                    MIGRATION_NAME,
                    f"Existing thresholds found in database ({len(existing)} configurations) - migration skipped"
                )
                return
            
            # Only migrate if database is truly empty (no thresholds exist)
            # This is a first-time setup scenario
            if self.thresholds_path.exists():
                logger.info("🔄 First-time setup: Database is empty, migrating thresholds from JSON to database...")
                with open(self.thresholds_path, 'r') as f:
                    thresholds_data = json.load(f)
                
                # Migrate thresholds (only inserts if they don't exist)
                self.db_manager.migrate_thresholds_from_json(thresholds_data)
                
                # CRITICAL: Mark migration as complete IMMEDIATELY after successful migration
                # This ensures it never runs again, even on service restart
                self.db_manager.mark_migration_complete(
                    MIGRATION_NAME,
                    f"Migrated {len(thresholds_data)} species configurations from JSON (first-time setup only)"
                )
                logger.info("✅ Threshold migration complete - database is now source of truth")
                logger.info("⚠️  Future restarts will NOT overwrite database thresholds")
            else:
                logger.warning(f"Thresholds file not found: {self.thresholds_path}")
                logger.warning("⚠️  No initial thresholds available - configure via Flutter app")
                # Mark migration complete even if no JSON file - prevents repeated attempts
                self.db_manager.mark_migration_complete(
                    MIGRATION_NAME,
                    "No JSON file found, user must configure via app"
                )
                
        except Exception as e:
            logger.error(f"Error during threshold migration: {e}", exc_info=True)
            # On error, don't mark migration complete - allow retry on next startup
            # But log the error so user knows what happened
        
    def _load_configuration(self) -> None:
        """Load current stage configuration from database"""
        try:
            # Load from database
            stage_data = self.db_manager.get_current_stage()

            if stage_data:
                # Robust handling of start_time coming back from SQLite
                raw_start_time = stage_data.get("start_time")
                start_dt: datetime

                try:
                    # Common case: numeric unix timestamp (float/int)
                    if isinstance(raw_start_time, (int, float)):
                        start_dt = datetime.fromtimestamp(raw_start_time)
                    # Some SQLite setups may return it as TEXT; try float first
                    elif isinstance(raw_start_time, str):
                        try:
                            ts = float(raw_start_time)
                            start_dt = datetime.fromtimestamp(ts)
                        except ValueError:
                            # Fallback: ISO 8601 string stored by older versions
                            start_dt = datetime.fromisoformat(raw_start_time)
                    else:
                        # Unexpected type – fall back to "now" but log for visibility
                        logger.warning(
                            f"Unexpected start_time type '{type(raw_start_time)}' "
                            f"from database, defaulting to now()"
                        )
                        start_dt = datetime.now()
                except Exception as parse_err:
                    logger.error(
                        f"Failed to parse start_time='{raw_start_time}' from database: {parse_err}",
                        exc_info=True,
                    )
                    # On parsing failure, keep system running with a sane default
                    start_dt = datetime.now()

                # Ensure expected_days is an int (older DBs may store it as TEXT)
                raw_expected_days = stage_data.get("expected_days", 0)
                try:
                    expected_days = int(raw_expected_days)
                except (TypeError, ValueError):
                    logger.warning(
                        f"Unexpected expected_days value '{raw_expected_days}', "
                        f"defaulting to 0"
                    )
                    expected_days = 0

                self.current_stage = StageInfo(
                    species=stage_data['species'],
                    stage=stage_data['stage'],
                    start_time=start_dt,
                    expected_days=expected_days,
                    mode=StageMode(stage_data['mode']),
                    thresholds={}
                )
                logger.info(f"Loaded stage from database: {self.current_stage.species} - {self.current_stage.stage} (mode={self.current_stage.mode.value})")
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
        """Save current stage configuration to database"""
        if not self.current_stage:
            return
        
        try:
            # Note: control_mode is saved separately by control system
            self.db_manager.save_current_stage(
                species=self.current_stage.species,
                stage=self.current_stage.stage,
                mode=self.current_stage.mode.value,
                start_time=self.current_stage.start_time.timestamp(),
                expected_days=self.current_stage.expected_days,
                control_mode=None  # Saved separately by control system
            )
            logger.info(f"Stage configuration saved to database: {self.current_stage.species}/{self.current_stage.stage} (mode={self.current_stage.mode.value})")
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
        
    def get_compliance_ratio(self, min_compliance_days: int = 1) -> Tuple[float, int, int]:
        """Calculate compliance ratio for current stage
        
        Compliance is measured as the percentage of time environmental conditions
        were within thresholds during the stage duration.
        
        Args:
            min_compliance_days: Minimum number of days to analyze (default: 1 day)
            
        Returns:
            Tuple of (compliance_ratio, compliant_readings, total_readings)
            compliance_ratio: 0.0 to 1.0 (percentage of compliant readings)
        """
        if not self.current_stage:
            return 0.0, 0, 0
        
        try:
            # Get thresholds for current stage
            thresholds = self.get_current_thresholds()
            if not thresholds:
                logger.warning("No thresholds available for compliance checking")
                return 0.0, 0, 0
            
            # Calculate time window (from stage start to now, or min_compliance_days)
            stage_start = self.current_stage.start_time
            now = datetime.now()
            stage_duration_days = (now - stage_start).total_seconds() / (24 * 3600)
            
            # Use at least min_compliance_days, but not more than stage duration
            analysis_days = max(min_compliance_days, min(stage_duration_days, 7))  # Cap at 7 days for performance
            analysis_start = now - timedelta(days=analysis_days)
            
            # Get sensor readings from database for this time window
            # Note: This requires a method in DatabaseManager to query readings by time range
            # For now, we'll use a simplified approach that tracks compliance in memory
            # TODO: Implement database query for historical compliance analysis
            
            # Track compliance using compliance_history
            # Each entry: {'timestamp': datetime, 'compliant': bool}
            total_readings = len(self.compliance_history)
            if total_readings == 0:
                return 0.0, 0, 0
            
            # Count compliant readings
            compliant_readings = sum(1 for entry in self.compliance_history if entry.get('compliant', False))
            compliance_ratio = compliant_readings / total_readings if total_readings > 0 else 0.0
            
            return compliance_ratio, compliant_readings, total_readings
            
        except Exception as e:
            logger.error(f"Error calculating compliance ratio: {e}")
            return 0.0, 0, 0
    
    def record_compliance(self, reading, thresholds: Dict[str, Any]) -> None:
        """Record compliance status for a sensor reading
        
        Args:
            reading: SensorReading object
            thresholds: Current stage thresholds dict
        """
        try:
            compliant = True
            
            # Check temperature compliance
            if reading.temperature_c is not None:
                temp_min = thresholds.get('temp_min')
                temp_max = thresholds.get('temp_max')
                if temp_min is not None and reading.temperature_c < temp_min:
                    compliant = False
                if temp_max is not None and reading.temperature_c > temp_max:
                    compliant = False
            
            # Check humidity compliance
            if reading.humidity_percent is not None:
                rh_min = thresholds.get('rh_min')
                if rh_min is not None and reading.humidity_percent < rh_min:
                    compliant = False
            
            # Check CO2 compliance
            if reading.co2_ppm is not None:
                co2_max = thresholds.get('co2_max')
                if co2_max is not None and reading.co2_ppm > co2_max:
                    compliant = False
            
            # Record compliance status
            self.compliance_history.append({
                'timestamp': reading.timestamp,
                'compliant': compliant
            })
            
            # Keep only recent history (last 7 days) to prevent memory growth
            cutoff_time = datetime.now() - timedelta(days=7)
            self.compliance_history = [
                entry for entry in self.compliance_history
                if entry['timestamp'] > cutoff_time
            ]
            
        except Exception as e:
            logger.error(f"Error recording compliance: {e}")
    
    def should_advance_stage(self, min_compliance_ratio: float = 0.70) -> Tuple[bool, str]:
        """Check if stage should advance (for FULL mode)
        
        Requires both age threshold AND minimum compliance ratio to be met.
        
        Args:
            min_compliance_ratio: Minimum compliance ratio required (0.0 to 1.0, default: 0.70 = 70%)
            
        Returns:
            Tuple of (should_advance, reason_string)
        """
        if not self.current_stage or self.current_stage.mode != StageMode.FULL:
            return False, "Not in FULL mode"
            
        age_days = self.get_stage_age_days()
        
        # Check if expected days have been reached
        if age_days < self.current_stage.expected_days:
            return False, f"Stage in progress ({age_days:.1f}/{self.current_stage.expected_days} days elapsed)"
        
        # Age threshold met - now check compliance
        compliance_ratio, compliant_count, total_count = self.get_compliance_ratio()
        
        if compliance_ratio < min_compliance_ratio:
            return False, (
                f"Age threshold met ({age_days:.1f}/{self.current_stage.expected_days} days) "
                f"but compliance insufficient ({compliance_ratio:.1%} < {min_compliance_ratio:.1%}, "
                f"{compliant_count}/{total_count} readings compliant)"
            )
        
        # Both age and compliance requirements met
        return True, (
            f"Stage complete: {age_days:.1f}/{self.current_stage.expected_days} days elapsed, "
            f"{compliance_ratio:.1%} compliance ({compliant_count}/{total_count} readings)"
        )
    
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
        
        # Calculate expected start time for new stage based on previous stage timeline
        # This preserves the cultivation plan timeline even if auto-advance happens late
        current_start = self.current_stage.start_time
        current_expected_days = self.current_stage.expected_days
        expected_start_time = current_start + timedelta(days=current_expected_days)
        
        logger.info(f"📅 Previous stage started: {current_start.strftime('%Y-%m-%d %H:%M')}")
        logger.info(f"📅 Expected days: {current_expected_days}")
        logger.info(f"📅 New stage expected start: {expected_start_time.strftime('%Y-%m-%d %H:%M')}")
        
        # Set the new stage with calculated expected start time (not current time)
        success = self.set_stage(
            species=species,
            stage=next_stage_name,
            mode=self.current_stage.mode,
            start_time=expected_start_time
        )
        
        if success:
            # Get the thresholds for the new stage and save with expected start_time to database
            new_thresholds = self.get_stage_thresholds(species, next_stage_name)
            if new_thresholds:
                # Add the expected start_time to the thresholds before saving to DB
                new_thresholds['start_time'] = expected_start_time.isoformat()
                self.db_manager.save_stage_thresholds(species, next_stage_name, new_thresholds)
                logger.info(f"✅ Saved expected start_time to database for {species} - {next_stage_name}")
            
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
        compliance_ratio, compliant_count, total_count = self.get_compliance_ratio()
        
        return {
            'configured': True,
            'species': self.current_stage.species,
            'stage': self.current_stage.stage,
            'mode': self.current_stage.mode.value,
            'age_days': round(age_days, 1),
            'expected_days': self.current_stage.expected_days,
            'start_time': self.current_stage.start_time.isoformat(),
            'light_schedule': light_schedule,
            'progress_percent': min(100, (age_days / self.current_stage.expected_days) * 100) if self.current_stage.expected_days > 0 else 0,
            'compliance_ratio': round(compliance_ratio, 3),
            'compliance_readings': f"{compliant_count}/{total_count}"
        }


# Create global instance
stage_manager = StageManager()

# Export for external use
__all__ = ['StageManager', 'StageMode', 'StageInfo', 'stage_manager']