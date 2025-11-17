"""
MushPi Database Manager

Handles all database operations for sensor data persistence.
"""

import sqlite3
import logging
from pathlib import Path
from typing import Optional

from ..models.dataclasses import SensorReading, ThresholdEvent
from ..core.config import config

# Logging Setup
logger = logging.getLogger(__name__)


class DatabaseManager:
    """Handles all database operations for sensor data"""
    
    def __init__(self, db_path: Optional[Path] = None):
        self.db_path = db_path or config.database.path
        self.timeout = config.database.timeout  # Store timeout for reuse
        
        # Ensure database path is absolute
        if not self.db_path.is_absolute():
            # If path starts with 'data/', use it relative to project root, not data_dir
            if str(self.db_path).startswith('data/'):
                # Get project root (parent of mushpi directory)
                project_root = Path(__file__).parent.parent.parent
                self.db_path = project_root / self.db_path
            else:
                self.db_path = config.paths.data_dir / self.db_path
            
        # Create parent directory with proper permissions
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Ensure directory is writable
        try:
            # Test write permissions by creating a temp file
            test_file = self.db_path.parent / '.write_test'
            test_file.touch()
            test_file.unlink()
        except PermissionError:
            logger.error(f"No write permission for database directory: {self.db_path.parent}")
            logger.error("Run with appropriate permissions or change MUSHPI_DATA_DIR in .env")
            raise
            
        self._init_database()
        
    def _init_database(self):
        """Initialize database with required tables"""
        try:
            with sqlite3.connect(self.db_path, timeout=config.database.timeout) as conn:
                # Enable WAL mode for better concurrency
                conn.execute("PRAGMA journal_mode=WAL")
                
                conn.executescript("""
                    CREATE TABLE IF NOT EXISTS sensor_readings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        timestamp TEXT NOT NULL,
                        co2_ppm INTEGER,
                        temperature_c REAL,
                        humidity_percent REAL,
                        light_level REAL,
                        sensor_source TEXT DEFAULT ''
                    );
                    
                    CREATE TABLE IF NOT EXISTS thresholds (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        parameter TEXT UNIQUE NOT NULL,
                        min_value REAL,
                        max_value REAL,
                        hysteresis REAL DEFAULT 1.0,
                        active BOOLEAN DEFAULT 1
                    );
                    
                    CREATE TABLE IF NOT EXISTS threshold_events (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        timestamp TEXT NOT NULL,
                        parameter TEXT NOT NULL,
                        current_value REAL NOT NULL,
                        threshold_type TEXT NOT NULL,
                        threshold_value REAL NOT NULL,
                        action_taken TEXT DEFAULT ''
                    );
                    
                    CREATE TABLE IF NOT EXISTS stage_thresholds (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        species TEXT NOT NULL,
                        stage TEXT NOT NULL,
                        temp_min REAL,
                        temp_max REAL,
                        rh_min REAL,
                        rh_max REAL,
                        co2_max REAL,
                        light_min REAL,
                        light_max REAL,
                        light_mode TEXT DEFAULT 'off',
                        light_on_minutes INTEGER DEFAULT 0,
                        light_off_minutes INTEGER DEFAULT 0,
                        expected_days INTEGER DEFAULT 0,
                        start_time TEXT,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(species, stage)
                    );
                    
                    CREATE INDEX IF NOT EXISTS idx_readings_timestamp 
                    ON sensor_readings(timestamp);
                    
                    CREATE INDEX IF NOT EXISTS idx_events_timestamp 
                    ON threshold_events(timestamp);
                    
                    CREATE INDEX IF NOT EXISTS idx_stage_thresholds_species_stage
                    ON stage_thresholds(species, stage);
                """)
                
            # Set permissions on database file (readable/writable by user and group)
            if self.db_path.exists():
                self.db_path.chmod(0o664)
            
            # Run migrations for existing databases
            # self._run_migrations()
            
            logger.info(f"Database initialized successfully at {self.db_path}")
            
        except sqlite3.OperationalError as e:
            if "readonly" in str(e).lower():
                logger.error(f"Database is read-only: {self.db_path}")
                logger.error(f"Fix with: chmod 664 {self.db_path} && chmod 775 {self.db_path.parent}")
                raise RuntimeError(f"Database file is read-only: {self.db_path}. Check file permissions.") from e
            raise
    
    def _run_migrations(self):
        """Run database migrations for schema updates
        
        This method handles schema changes for existing databases.
        Each migration checks if it's needed before running.
        """
        with sqlite3.connect(self.db_path, timeout=self.timeout) as conn:
            # Migration 1: Add start_time column to stage_thresholds if missing
            try:
                # Check if column exists
                cursor = conn.execute("PRAGMA table_info(stage_thresholds)")
                columns = [row[1] for row in cursor.fetchall()]
                
                if 'start_time' not in columns:
                    logger.info("🔄 Running migration: Adding start_time column to stage_thresholds")
                    conn.execute("""
                        ALTER TABLE stage_thresholds 
                        ADD COLUMN start_time TEXT
                    """)
                    logger.info("✅ Migration complete: start_time column added")
            except sqlite3.OperationalError as e:
                # If table doesn't exist yet, that's fine (fresh database)
                if "no such table" not in str(e).lower():
                    logger.error(f"Error during migration: {e}")
                    raise
            
    def save_reading(self, reading: SensorReading) -> None:
        """Save sensor reading to database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO sensor_readings 
                (timestamp, co2_ppm, temperature_c, humidity_percent, light_level, sensor_source)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                reading.timestamp.isoformat(),
                reading.co2_ppm,
                reading.temperature_c, 
                reading.humidity_percent,
                reading.light_level,
                reading.sensor_source
            ))
            
    def save_threshold_event(self, event: ThresholdEvent) -> None:
        """Save threshold violation event"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO threshold_events
                (timestamp, parameter, current_value, threshold_type, threshold_value, action_taken)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                event.timestamp.isoformat(),
                event.parameter,
                event.current_value,
                event.threshold_type,
                event.threshold_value,
                event.action_taken
            ))
    
    def get_stage_thresholds(self, species: str, stage: str) -> Optional[dict]:
        """Get thresholds for a specific species and stage
        
        Ensures table exists before attempting read for robustness.
        """
        with sqlite3.connect(self.db_path, timeout=self.timeout) as conn:
            # Ensure table exists (defensive check)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS stage_thresholds (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    species TEXT NOT NULL,
                    stage TEXT NOT NULL,
                    temp_min REAL,
                    temp_max REAL,
                    rh_min REAL,
                    rh_max REAL,
                    co2_max REAL,
                    light_min REAL,
                    light_max REAL,
                    light_mode TEXT DEFAULT 'off',
                    light_on_minutes INTEGER DEFAULT 0,
                    light_off_minutes INTEGER DEFAULT 0,
                    expected_days INTEGER DEFAULT 0,
                    start_time TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(species, stage)
                )
            """)
            
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT temp_min, temp_max, rh_min, rh_max, co2_max, 
                       light_min, light_max, light_mode, light_on_minutes, 
                       light_off_minutes, expected_days, start_time
                FROM stage_thresholds
                WHERE species = ? AND stage = ?
            """, (species, stage))
            
            row = cursor.fetchone()
            if row:
                return dict(row)
        return None
    
    def get_all_stage_thresholds(self, species: Optional[str] = None) -> list:
        """Get all stage thresholds, optionally filtered by species
        
        Ensures table exists before attempting read for robustness.
        """
        with sqlite3.connect(self.db_path, timeout=self.timeout) as conn:
            # Ensure table exists (defensive check)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS stage_thresholds (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    species TEXT NOT NULL,
                    stage TEXT NOT NULL,
                    temp_min REAL,
                    temp_max REAL,
                    rh_min REAL,
                    rh_max REAL,
                    co2_max REAL,
                    light_min REAL,
                    light_max REAL,
                    light_mode TEXT DEFAULT 'off',
                    light_on_minutes INTEGER DEFAULT 0,
                    light_off_minutes INTEGER DEFAULT 0,
                    expected_days INTEGER DEFAULT 0,
                    start_time TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(species, stage)
                )
            """)
            
            conn.row_factory = sqlite3.Row
            if species:
                cursor = conn.execute("""
                    SELECT species, stage, temp_min, temp_max, rh_min, rh_max, co2_max,
                           light_min, light_max, light_mode, light_on_minutes,
                           light_off_minutes, expected_days, start_time, updated_at
                    FROM stage_thresholds
                    WHERE species = ?
                    ORDER BY species, stage
                """, (species,))
            else:
                cursor = conn.execute("""
                    SELECT species, stage, temp_min, temp_max, rh_min, rh_max, co2_max,
                           light_min, light_max, light_mode, light_on_minutes,
                           light_off_minutes, expected_days, start_time, updated_at
                    FROM stage_thresholds
                    ORDER BY species, stage
                """)
            
            return [dict(row) for row in cursor.fetchall()]
    
    def save_stage_thresholds(self, species: str, stage: str, thresholds: dict) -> None:
        """Save or update thresholds for a specific species and stage
        
        Ensures the stage_thresholds table exists before attempting write.
        This provides defensive protection against database corruption or incomplete initialization.
        """
        with sqlite3.connect(self.db_path, timeout=self.timeout) as conn:
            # Ensure table exists (defensive check for robustness)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS stage_thresholds (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    species TEXT NOT NULL,
                    stage TEXT NOT NULL,
                    temp_min REAL,
                    temp_max REAL,
                    rh_min REAL,
                    rh_max REAL,
                    co2_max REAL,
                    light_min REAL,
                    light_max REAL,
                    light_mode TEXT DEFAULT 'off',
                    light_on_minutes INTEGER DEFAULT 0,
                    light_off_minutes INTEGER DEFAULT 0,
                    expected_days INTEGER DEFAULT 0,
                    start_time TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(species, stage)
                )
            """)
            
            # Save or update the thresholds
            conn.execute("""
                INSERT INTO stage_thresholds 
                (species, stage, temp_min, temp_max, rh_min, rh_max, co2_max,
                 light_min, light_max, light_mode, light_on_minutes, light_off_minutes,
                 expected_days, start_time, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(species, stage) DO UPDATE SET
                    temp_min = COALESCE(excluded.temp_min, temp_min),
                    temp_max = COALESCE(excluded.temp_max, temp_max),
                    rh_min = COALESCE(excluded.rh_min, rh_min),
                    rh_max = COALESCE(excluded.rh_max, rh_max),
                    co2_max = COALESCE(excluded.co2_max, co2_max),
                    light_min = COALESCE(excluded.light_min, light_min),
                    light_max = COALESCE(excluded.light_max, light_max),
                    light_mode = COALESCE(excluded.light_mode, light_mode),
                    light_on_minutes = COALESCE(excluded.light_on_minutes, light_on_minutes),
                    light_off_minutes = COALESCE(excluded.light_off_minutes, light_off_minutes),
                    expected_days = COALESCE(excluded.expected_days, expected_days),
                    start_time = COALESCE(excluded.start_time, start_time),
                    updated_at = CURRENT_TIMESTAMP
            """, (
                species,
                stage,
                thresholds.get('temp_min'),
                thresholds.get('temp_max'),
                thresholds.get('rh_min'),
                thresholds.get('rh_max'),
                thresholds.get('co2_max'),
                thresholds.get('light_min'),
                thresholds.get('light_max'),
                thresholds.get('light', {}).get('mode') if isinstance(thresholds.get('light'), dict) else thresholds.get('light_mode', 'off'),
                thresholds.get('light', {}).get('on_min') if isinstance(thresholds.get('light'), dict) else thresholds.get('light_on_minutes', 0),
                thresholds.get('light', {}).get('off_min') if isinstance(thresholds.get('light'), dict) else thresholds.get('light_off_minutes', 0),
                thresholds.get('expected_days', 0),
                thresholds.get('start_time')
            ))
        logger.info(f"Saved stage thresholds: {species} - {stage}")
    
    def migrate_thresholds_from_json(self, json_data: dict) -> None:
        """Migrate thresholds from JSON format to database"""
        migrated_count = 0
        for species, stages in json_data.items():
            for stage, thresholds in stages.items():
                # Check if already exists
                existing = self.get_stage_thresholds(species, stage)
                if not existing:
                    self.save_stage_thresholds(species, stage, thresholds)
                    migrated_count += 1
                    logger.info(f"Migrated: {species} - {stage}")
        
        if migrated_count > 0:
            logger.info(f"✅ Migrated {migrated_count} stage threshold configurations to database")
        else:
            logger.debug("No new thresholds to migrate from JSON")