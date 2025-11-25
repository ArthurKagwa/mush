# How to Check Database and Test Changes on Pi

## Prerequisites
- SSH access to the Pi
- MushPi service running or code deployed

## Method 1: Check Database Directly with SQLite

### Step 1: SSH into the Pi
```bash
ssh pi@<your-pi-ip>
# OR if you have a custom username
ssh <username>@<your-pi-ip>
```

### Step 2: Navigate to the database location
```bash
cd /opt/mushpi
# Or wherever your MUSHPI_DATA_DIR points to
ls -la data/sensors.db
```

### Step 3: Open the database with SQLite
```bash
sqlite3 data/sensors.db
```

### Step 4: Check if stage_thresholds table exists
```sql
-- List all tables
.tables

-- Check table schema
.schema stage_thresholds

-- Count records in the table
SELECT COUNT(*) FROM stage_thresholds;

-- View all threshold data
SELECT * FROM stage_thresholds;

-- View specific species/stage
SELECT * FROM stage_thresholds WHERE species = 'Oyster' AND stage = 'Pinning';

-- Check when data was last updated
SELECT species, stage, updated_at FROM stage_thresholds ORDER BY updated_at DESC;
```

### Step 5: Exit SQLite
```sql
.exit
```

## Method 2: Check via Python Script on Pi

### Create a test script on your local machine
```bash
# From your local machine in the mush directory
cat > test_database_pi.py << 'EOF'
#!/usr/bin/env python3
"""Test script to verify database and threshold operations"""
import sys
sys.path.insert(0, '/opt/mushpi')

from app.database.manager import DatabaseManager
from app.core.stage import StageManager
import json

print("=" * 60)
print("MushPi Database Test Script")
print("=" * 60)

# Test 1: Database connection
print("\n1. Testing database connection...")
try:
    db = DatabaseManager()
    print(f"✅ Database connected: {db.db_path}")
    print(f"   Timeout: {db.timeout}s")
except Exception as e:
    print(f"❌ Database connection failed: {e}")
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
except Exception as e:
    print(f"⚠️  Table query failed: {e}")

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
        import os
        json_path = '/opt/mushpi/app/config/thresholds.json'
        if os.path.exists(json_path):
            print(f"   Found thresholds.json at {json_path}")
            print("   Migration should happen on next service start")
        else:
            print(f"   ⚠️  thresholds.json not found at {json_path}")
            
except Exception as e:
    print(f"❌ StageManager test failed: {e}")

# Test 5: Check migration status
print("\n5. Checking migration status...")
try:
    from pathlib import Path
    import json
    
    json_path = Path('/opt/mushpi/app/config/thresholds.json')
    if json_path.exists():
        with open(json_path, 'r') as f:
            json_data = json.load(f)
        
        species_count = len(json_data.get('species', {}))
        print(f"✅ thresholds.json exists with {species_count} species")
        
        # Check if data is in database
        db_data = db.get_all_stage_thresholds()
        print(f"   Database has {len(db_data)} threshold records")
        
        if len(db_data) == 0:
            print("   ⚠️  Migration hasn't run yet - will happen on service start")
        else:
            print("   ✅ Data migrated to database")
    else:
        print(f"⚠️  thresholds.json not found at {json_path}")
except Exception as e:
    print(f"⚠️  Migration check failed: {e}")

print("\n" + "=" * 60)
print("Test complete!")
print("=" * 60)
EOF
```

### Deploy and run the test script on Pi
```bash
# Copy script to Pi
scp test_database_pi.py pi@<your-pi-ip>:/tmp/

# SSH into Pi and run
ssh pi@<your-pi-ip>
cd /opt/mushpi
source .venv/bin/activate
python3 /tmp/test_database_pi.py
```

## Method 3: Check Service Logs

### View service logs to see migration and database activity
```bash
# SSH into Pi
ssh pi@<your-pi-ip>

# View recent logs
sudo journalctl -u mushpi.service -n 100 --no-pager

# Follow logs in real-time
sudo journalctl -u mushpi.service -f

# Look for specific patterns
sudo journalctl -u mushpi.service | grep -i "migrate"
sudo journalctl -u mushpi.service | grep -i "database"
sudo journalctl -u mushpi.service | grep -i "thresholds"
```

### Key log messages to look for:
```
✅ "Database initialized successfully at /opt/mushpi/data/sensors.db"
✅ "Migrated X stage threshold configurations to database"
✅ "Saved stage thresholds: Species - Stage"
⚠️  "No new thresholds to migrate from JSON"
```

## Method 4: Test from Flutter App

### Step 1: Connect via BLE
1. Open the Flutter app
2. Go to Farms tab
3. Connect to your MushPi device

### Step 2: Open Stage Wizard
1. Go to Stage tab
2. Tap "Edit" or "+" to open Stage Wizard
3. Select a species and stage

### Expected behavior:
- ✅ Thresholds load without errors
- ✅ Values populate the form fields
- ✅ Can save changes successfully

### If errors occur:
1. Check Pi logs: `sudo journalctl -u mushpi.service -f`
2. Look for BLE read/write messages
3. Check for database errors

## Method 5: Manual Database Inspection Commands

### Quick one-liners to run on Pi

```bash
# Check database file exists and size
ls -lh /opt/mushpi/data/sensors.db

# Check table structure
sqlite3 /opt/mushpi/data/sensors.db "PRAGMA table_info(stage_thresholds);"

# Count records by species
sqlite3 /opt/mushpi/data/sensors.db "SELECT species, COUNT(*) as stages FROM stage_thresholds GROUP BY species;"

# Show all data in readable format
sqlite3 /opt/mushpi/data/sensors.db << EOF
.mode column
.headers on
SELECT species, stage, temp_min, temp_max, rh_min, rh_max FROM stage_thresholds;
EOF

# Check most recent update
sqlite3 /opt/mushpi/data/sensors.db "SELECT * FROM stage_thresholds ORDER BY updated_at DESC LIMIT 1;"

# Export all data to JSON
sqlite3 /opt/mushpi/data/sensors.db << EOF
.mode json
SELECT * FROM stage_thresholds;
EOF
```

## Deployment Checklist

Before testing, ensure your changes are deployed:

### 1. Sync code to Pi
```bash
# From your local machine in /home/maestro/dev/mush
rsync -avz --exclude='*.pyc' --exclude='__pycache__' \
  mushpi/ pi@<your-pi-ip>:/opt/mushpi/app/

# Or use git
ssh pi@<your-pi-ip>
cd /opt/mushpi/app
git pull
```

### 2. Restart service
```bash
ssh pi@<your-pi-ip>
sudo systemctl restart mushpi.service
sudo systemctl status mushpi.service
```

### 3. Verify service is running
```bash
# Check status
sudo systemctl status mushpi.service

# Check process
ps aux | grep python | grep mushpi

# Check BLE is advertising
sudo hcitool lescan
```

## Troubleshooting

### Database file doesn't exist
```bash
# Check environment variables
cat /opt/mushpi/.env | grep DB_PATH

# Create manually if needed
mkdir -p /opt/mushpi/data
touch /opt/mushpi/data/sensors.db
chmod 664 /opt/mushpi/data/sensors.db
```

### Permission errors
```bash
# Fix permissions
sudo chown -R pi:pi /opt/mushpi/data
chmod 775 /opt/mushpi/data
chmod 664 /opt/mushpi/data/sensors.db
```

### Table doesn't exist
```bash
# The defensive code should create it automatically
# But you can create manually:
sqlite3 /opt/mushpi/data/sensors.db < /opt/mushpi/app/database/schema.sql
# Or just restart the service - it will create tables
```

### Migration not happening
```bash
# Check thresholds.json exists
ls -la /opt/mushpi/app/config/thresholds.json

# Manually trigger migration (create Python script)
cat > /tmp/force_migrate.py << 'EOF'
import sys
sys.path.insert(0, '/opt/mushpi')
from app.core.stage import StageManager
sm = StageManager()
sm._migrate_thresholds_if_needed()
print("Migration complete!")
EOF

python3 /tmp/force_migrate.py
```

## Expected Test Results

✅ **Successful Test:**
- Database file exists at `/opt/mushpi/data/sensors.db`
- `stage_thresholds` table exists with data
- Can read and write thresholds
- Service logs show no errors
- Flutter app can read/write thresholds via BLE

⚠️ **Needs Investigation:**
- Database exists but table is empty (migration pending)
- Can read but not write (permission issue)
- Table doesn't exist (service hasn't started properly)

❌ **Problem:**
- Database file doesn't exist
- Permission denied errors
- Service won't start
- BLE not working
