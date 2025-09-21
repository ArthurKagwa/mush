"""
MushPi Database Manager

Handles all database operations for sensor data persistence.
"""

import sqlite3
import logging
from pathlib import Path
from typing import Optional

from ..models.dataclasses import SensorReading, ThresholdEvent

# File Paths
DB_PATH = Path("data/sensors.db")

# Logging Setup
logger = logging.getLogger(__name__)


class DatabaseManager:
    """Handles all database operations for sensor data"""
    
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()
        
    def _init_database(self):
        """Initialize database with required tables"""
        with sqlite3.connect(self.db_path) as conn:
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