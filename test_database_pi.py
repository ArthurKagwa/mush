#!/usr/bin/env python3
"""
Test script to verify database and threshold operations on Raspberry Pi
Run this on the Pi after deploying changes: python3 /tmp/test_database_pi.py
"""
import sys
sys.path.insert(0, '/opt/mushpi')

from app.database.manager import DatabaseManager
from app.core.stage import StageManager
import json
from pathlib import Path

print("=" * 60)
print("MushPi Database Test Script")
print("=" * 60)

# Test 1: Database connection
print("\n1. Testing database connection...")
try:
    db = DatabaseManager()
    print(f"✅ Database connected: {db.db_path}")
    print(f"   Timeout: {db.timeout}s")
    print(f"   File exists: {db.db_path.exists()}")
    if db.db_path.exists():
        import os
        size = os.path.getsize(db.db_path)
        print(f"   File size: {size} bytes ({size/1024:.2f} KB)")
except Exception as e:
    print(f"❌ Database connection failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 2: Check if stage_thresholds table exists
print("\n2. Checking stage_thresholds table...")
try:
    all_thresholds = db.get_all_stage_thresholds()
    print(f"✅ Table exists with {len(all_thresholds)} records")
    
    if len(all_thresholds) > 0:
        print("\n   Existing thresholds:")
        for t in all_thresholds[:5]:  # Show first 5
            print(f"   - {t['species']}/{t['stage']}: temp={t.get('temp_min')}-{t.get('temp_max')}°C, rh={t.get('rh_min')}-{t.get('rh_max')}%")
    else:
        print("   ⚠️  Table is empty (no records yet)")
except Exception as e:
    print(f"⚠️  Table query failed: {e}")
    import traceback
    traceback.print_exc()

# Test 3: Test write operation (defensive table creation)
print("\n3. Testing write operation (with defensive table creation)...")
try:
    test_thresholds = {
        'temp_min': 18.0,
        'temp_max': 24.0,
        'rh_min': 85.0,
        'rh_max': 95.0,
        'co2_max': 2000,
        'light_mode': 'off',
        'expected_days': 7
    }
    db.save_stage_thresholds('TestSpecies', 'TestStage', test_thresholds)
    print("✅ Write successful (table created if needed)")
    
    # Verify the write
    result = db.get_stage_thresholds('TestSpecies', 'TestStage')
    if result:
        print(f"✅ Verified: Read back temp={result.get('temp_min')}-{result.get('temp_max')}°C")
    else:
        print("⚠️  Write succeeded but read failed")
except Exception as e:
    print(f"❌ Write failed: {e}")
    import traceback
    traceback.print_exc()

# Test 4: Test StageManager integration
print("\n4. Testing StageManager integration...")
try:
    stage_mgr = StageManager()
    
    # Test reading a stage
    thresholds = stage_mgr.get_stage_thresholds('Oyster', 'Pinning')
    if thresholds:
        print(f"✅ StageManager read successful")
        print(f"   Oyster/Pinning: temp={thresholds.get('temp_min')}-{thresholds.get('temp_max')}°C")
    else:
        print("⚠️  No thresholds found for Oyster/Pinning")
        print("   Checking if migration is needed...")
        
        # Check thresholds.json
        json_path = Path('/opt/mushpi/app/config/thresholds.json')
        if json_path.exists():
            print(f"   ✅ Found thresholds.json at {json_path}")
            print("   Migration should happen on next service start or manual trigger")
        else:
            print(f"   ⚠️  thresholds.json not found at {json_path}")
            
except Exception as e:
    print(f"❌ StageManager test failed: {e}")
    import traceback
    traceback.print_exc()

# Test 5: Check migration status
print("\n5. Checking migration status...")
try:
    json_path = Path('/opt/mushpi/app/config/thresholds.json')
    if json_path.exists():
        with open(json_path, 'r') as f:
            json_data = json.load(f)
        
        # Count stages
        total_stages = 0
        species_data = json_data.get('species', {})
        for species, data in species_data.items():
            stages = data.get('stages', {})
            total_stages += len(stages)
            
        print(f"✅ thresholds.json exists")
        print(f"   Species: {len(species_data)}")
        print(f"   Total stages: {total_stages}")
        
        # Check if data is in database
        db_data = db.get_all_stage_thresholds()
        print(f"   Database records: {len(db_data)}")
        
        if len(db_data) == 0:
            print("   ⚠️  Migration hasn't run yet - will happen on service start")
            print("\n   To manually trigger migration, run:")
            print("   python3 -c 'from app.core.stage import StageManager; StageManager()._migrate_thresholds_if_needed()'")
        elif len(db_data) < total_stages:
            print(f"   ⚠️  Partial migration: {len(db_data)}/{total_stages} stages")
        else:
            print("   ✅ Data fully migrated to database")
    else:
        print(f"⚠️  thresholds.json not found at {json_path}")
except Exception as e:
    print(f"⚠️  Migration check failed: {e}")
    import traceback
    traceback.print_exc()

# Test 6: Test backward compatibility fallback
print("\n6. Testing backward compatibility (read from JSON if DB empty)...")
try:
    from app.core.config import config
    json_path = config.thresholds_path
    
    if json_path.exists():
        with open(json_path, 'r') as f:
            json_data = json.load(f)
        
        # Try to read from JSON structure
        species_data = json_data.get('species', {}).get('Oyster', {})
        stage_data = species_data.get('stages', {}).get('Pinning', {})
        
        if stage_data:
            print("✅ Can read from thresholds.json as fallback")
            print(f"   Oyster/Pinning from JSON: temp={stage_data.get('temp_min')}-{stage_data.get('temp_max')}°C")
        else:
            print("⚠️  Oyster/Pinning not found in JSON")
    else:
        print(f"⚠️  thresholds.json not accessible at {json_path}")
except Exception as e:
    print(f"⚠️  Fallback test failed: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
print("Test complete!")
print("=" * 60)
print("\nSummary:")
print("- If all tests passed (✅), the system is working correctly")
print("- If migration is pending (⚠️), restart the mushpi service")
print("- If errors occurred (❌), check logs with: sudo journalctl -u mushpi.service -n 50")
