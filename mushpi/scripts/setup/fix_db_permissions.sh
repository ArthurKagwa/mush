#!/bin/bash
# =============================================================================
# MushPi Database Permission Fix
# =============================================================================
# Quick fix for "attempt to write a readonly database" error
# Run with: bash fix_db_permissions.sh
#
# =============================================================================

echo "Fixing MushPi database permissions..."

# Create data directory if it doesn't exist
mkdir -p data

# Remove old database files (they will be recreated)
if [ -f "data/sensors.db" ]; then
    echo "Removing old database files..."
    rm -f data/sensors.db
    rm -f data/sensors.db-shm
    rm -f data/sensors.db-wal
fi

# Set proper permissions on data directory
chmod 775 data

echo "✓ Database directory is now writable"
echo ""
echo "The database will be recreated when you run: python3 main.py"
