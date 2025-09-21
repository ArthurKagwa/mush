#!/usr/bin/env python3
"""
Test script for verifying the modularized sensor system imports correctly.
This script can be used to validate that all components are accessible.
"""

try:
    print("Testing modularized sensor imports...")
    
    # Test individual module imports
    from mushpi.app.models.dataclasses import SensorReading, Threshold, ThresholdEvent
    print("✅ Data models imported successfully")
    
    from mushpi.app.database.manager import DatabaseManager
    print("✅ Database manager imported successfully")
    
    from mushpi.app.managers.threshold_manager import ThresholdManager
    from mushpi.app.managers.sensor_manager import SensorManager
    print("✅ Managers imported successfully")
    
    from mushpi.app.sensors.base import BaseSensor, SensorError
    from mushpi.app.sensors.scd41 import SCD41Sensor
    from mushpi.app.sensors.dht22 import DHT22Sensor
    from mushpi.app.sensors.light_sensor import LightSensor
    print("✅ Individual sensors imported successfully")
    
    # Test backward-compatible imports through main sensors.py
    from mushpi.app.core.sensors import (
        SensorReading, DatabaseManager, SensorManager,
        SCD41Sensor, DHT22Sensor, LightSensor,
        get_current_readings, start_sensor_monitoring
    )
    print("✅ Backward-compatible imports working")
    
    print("\n🎉 All imports successful! Modularization complete.")
    print("\nNew structure provides:")
    print("  - Separated concerns (database, sensors, managers)")
    print("  - Individual sensor files for easier maintenance")
    print("  - Base classes for consistent sensor interface")
    print("  - Full backward compatibility")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
except Exception as e:
    print(f"❌ Unexpected error: {e}")