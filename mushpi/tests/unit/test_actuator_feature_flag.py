#!/usr/bin/env python3
"""Minimal test verifying actuator_status characteristic gating.

Run twice:
  1. Without MUSHPI_BLE_ACTUATOR_STATUS_ENABLE (should NOT include actuator_status)
  2. With   MUSHPI_BLE_ACTUATOR_STATUS_ENABLE=true (should include actuator_status)

This avoids starting full BLE stack; we instantiate the service manager in simulation mode
by setting MUSHPI_SIMULATION_MODE=true to prevent hardware side effects.
"""
import os
import sys

# Force simulation to avoid real BLE requirements
os.environ.setdefault("MUSHPI_SIMULATION_MODE", "true")
# Redirect paths to local workspace to avoid permission issues on /opt
repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
app_dir = os.path.join(repo_root, "mushpi", "app")
data_dir = os.path.join(repo_root, "mushpi", "data")
config_dir = os.path.join(app_dir, "config")
venv_dir = os.path.join(repo_root, "mushpi", ".venv")
os.environ.setdefault("MUSHPI_APP_DIR", app_dir)
os.environ.setdefault("MUSHPI_DATA_DIR", data_dir)
os.environ.setdefault("MUSHPI_CONFIG_DIR", config_dir)
os.environ.setdefault("MUSHPI_VENV_PATH", venv_dir)
os.environ.setdefault("MUSHPI_DB_PATH", os.path.join(repo_root, "mushpi", "data", "sensors.db"))

# Ensure Python can import 'app' package when running from repo root
if repo_root not in sys.path:
    sys.path.append(os.path.join(repo_root, "mushpi"))

# Allow user override for the feature flag
flag = os.environ.get("MUSHPI_BLE_ACTUATOR_STATUS_ENABLE", "false").lower() in ("true","1","yes","on")

from app.ble.service import BLEGATTServiceManager

mgr = BLEGATTServiceManager()

chars = sorted(list(mgr.characteristics.keys()))
print("Feature flag MUSHPI_BLE_ACTUATOR_STATUS_ENABLE=", flag)
print("Characteristics:", chars)

expected_without = {"env_measurements","control_targets","stage_state","override_bits","status_flags","uart_rx","uart_tx"}
expected_with = expected_without | {"actuator_status"}

if flag:
    if "actuator_status" in chars and set(chars) == expected_with:
        print("✅ Actuator status characteristic present as expected")
        sys.exit(0)
    else:
        print("❌ Actuator status characteristic missing or unexpected set")
        sys.exit(1)
else:
    if "actuator_status" not in chars and set(chars) == expected_without:
        print("✅ Actuator status characteristic correctly absent")
        sys.exit(0)
    else:
        print("❌ Backward-compatible set violated (actuator_status should be absent)")
        sys.exit(1)
