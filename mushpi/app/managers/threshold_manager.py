"""
MushPi Threshold Manager

Manages environmental thresholds with JSON persistence and database integration.
"""

import json
import sqlite3
import logging
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List

from ..models.dataclasses import SensorReading, Threshold, ThresholdEvent
from ..database.manager import DatabaseManager
from ..core.config import config

# Logging Setup
logger = logging.getLogger(__name__)


class ThresholdManager:
    """Manages environmental thresholds with JSON persistence"""
    
    def __init__(self, json_path: Optional[Path] = None, db_manager: DatabaseManager = None):
        self.json_path = json_path or config.thresholds_path
        self.db_manager = db_manager or DatabaseManager()
        self.json_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_default_thresholds()
        
    def _init_default_thresholds(self) -> None:
        """Initialize default mushroom growing thresholds"""
        default_thresholds = {
            "temperature": {
                "min_value": 18.0,
                "max_value": 24.0,
                "hysteresis": 1.0,
                "active": True,
                "description": "Temperature range for optimal mushroom growth"
            },
            "humidity": {
                "min_value": 80.0,
                "max_value": 95.0,
                "hysteresis": 5.0,
                "active": True,
                "description": "Humidity range for fruiting stage"
            },
            "co2": {
                "min_value": None,
                "max_value": 1000.0,
                "hysteresis": 100.0,
                "active": True,
                "description": "CO2 level for air exchange trigger"
            },
            "light": {
                "min_value": 200.0,
                "max_value": 800.0,
                "hysteresis": 50.0,
                "active": True,
                "description": "Light level for growth cycle"
            }
        }
        
        # Create JSON file if it doesn't exist
        if not self.json_path.exists():
            self.save_thresholds_to_json(default_thresholds)
            
        # Sync JSON to database
        self.sync_json_to_database()
        
    def load_thresholds_from_json(self) -> Dict[str, Dict]:
        """Load thresholds from JSON file"""
        try:
            with open(self.json_path, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            logger.error(f"Error loading thresholds from JSON: {e}")
            return {}
            
    def save_thresholds_to_json(self, thresholds: Dict[str, Dict]) -> None:
        """Save thresholds to JSON file"""
        try:
            with open(self.json_path, 'w') as f:
                json.dump(thresholds, f, indent=2)
            logger.info(f"Thresholds saved to {self.json_path}")
        except Exception as e:
            logger.error(f"Error saving thresholds to JSON: {e}")
            
    def sync_json_to_database(self) -> None:
        """Sync JSON thresholds to database"""
        thresholds = self.load_thresholds_from_json()
        
        with sqlite3.connect(self.db_manager.db_path) as conn:
            for param, config in thresholds.items():
                conn.execute("""
                    INSERT OR REPLACE INTO thresholds 
                    (parameter, min_value, max_value, hysteresis, active)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    param,
                    config.get('min_value'),
                    config.get('max_value'),
                    config.get('hysteresis', 1.0),
                    config.get('active', True)
                ))
                
    def get_threshold(self, parameter: str) -> Optional[Threshold]:
        """Get threshold configuration for a parameter"""
        with sqlite3.connect(self.db_manager.db_path) as conn:
            cursor = conn.execute("""
                SELECT parameter, min_value, max_value, hysteresis, active
                FROM thresholds WHERE parameter = ?
            """, (parameter,))
            
            row = cursor.fetchone()
            if row:
                return Threshold(
                    parameter=row[0],
                    min_value=row[1],
                    max_value=row[2],
                    hysteresis=row[3],
                    active=bool(row[4])
                )
        return None
        
    def update_threshold(self, parameter: str, **kwargs) -> None:
        """Update threshold values"""
        current = self.get_threshold(parameter)
        if not current:
            logger.error(f"Threshold {parameter} not found")
            return
            
        # Update database
        with sqlite3.connect(self.db_manager.db_path) as conn:
            conn.execute("""
                UPDATE thresholds SET 
                min_value = COALESCE(?, min_value),
                max_value = COALESCE(?, max_value),
                hysteresis = COALESCE(?, hysteresis),
                active = COALESCE(?, active)
                WHERE parameter = ?
            """, (
                kwargs.get('min_value'),
                kwargs.get('max_value'),
                kwargs.get('hysteresis'),
                kwargs.get('active'),
                parameter
            ))
            
        # Update JSON file
        thresholds = self.load_thresholds_from_json()
        if parameter in thresholds:
            thresholds[parameter].update(kwargs)
            self.save_thresholds_to_json(thresholds)
            
    def check_thresholds(self, reading: SensorReading) -> List[ThresholdEvent]:
        """Check sensor reading against all thresholds"""
        events = []
        current_time = datetime.now()
        
        # Check each parameter
        checks = [
            ('temperature', reading.temperature_c),
            ('humidity', reading.humidity_percent),
            ('co2', reading.co2_ppm),
            ('light', reading.light_level)
        ]
        
        for param_name, value in checks:
            if value is None:
                continue
                
            threshold = self.get_threshold(param_name)
            if not threshold or not threshold.active:
                continue
                
            # Check minimum threshold
            if threshold.min_value is not None and value < threshold.min_value:
                event = ThresholdEvent(
                    timestamp=current_time,
                    parameter=param_name,
                    current_value=value,
                    threshold_type='min',
                    threshold_value=threshold.min_value,
                    action_taken=f'{param_name}_low'
                )
                events.append(event)
                
            # Check maximum threshold  
            if threshold.max_value is not None and value > threshold.max_value:
                event = ThresholdEvent(
                    timestamp=current_time,
                    parameter=param_name,
                    current_value=value,
                    threshold_type='max',
                    threshold_value=threshold.max_value,
                    action_taken=f'{param_name}_high'
                )
                events.append(event)
                
        return events