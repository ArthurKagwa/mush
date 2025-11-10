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
                    
                    CREATE INDEX IF NOT EXISTS idx_readings_timestamp 
                    ON sensor_readings(timestamp);
                    
                    CREATE INDEX IF NOT EXISTS idx_events_timestamp 
                    ON threshold_events(timestamp);
                """)
                
            # Set permissions on database file (readable/writable by user and group)
            if self.db_path.exists():
                self.db_path.chmod(0o664)
                
            logger.info(f"Database initialized successfully at {self.db_path}")
            
        except sqlite3.OperationalError as e:
            if "readonly" in str(e).lower():
                logger.error(f"Database is read-only: {self.db_path}")
                logger.error(f"Fix with: chmod 664 {self.db_path} && chmod 775 {self.db_path.parent}")
                raise RuntimeError(f"Database file is read-only: {self.db_path}. Check file permissions.") from e
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