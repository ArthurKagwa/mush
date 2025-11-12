#!/usr/bin/env python3
"""Basic tests for EnvironmentalSerializer robustness.
Ensures packing succeeds with None/float/out-of-range inputs and produces 12 bytes.
No mock data introduced; uses protocol ranges only.
"""
import os
import sys

# Ensure repository root is on sys.path so `mushpi` package resolves
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from mushpi.app.ble.serialization import EnvironmentalSerializer, EnvironmentalData, SerializationError


def make_data(co2, temp_x10, rh_x10, light_raw, uptime_ms):
    return EnvironmentalData(
        co2_ppm=co2,
        temp_x10=temp_x10,
        rh_x10=rh_x10,
        light_raw=light_raw,
        uptime_ms=uptime_ms,
    )


def test_pack_nominal():
    d = make_data(450, 225, 650, 42, 123456)
    packed = EnvironmentalSerializer.pack(d)
    assert len(packed) == EnvironmentalSerializer.SIZE


def test_pack_with_none_and_floats():
    # Simulate None/float upstream values by constructing then mutating
    d = make_data(0, 0, 0, 0, 0)
    d.co2_ppm = None  # becomes 0
    d.temp_x10 = int(21.7 * 10)  # already int
    d.rh_x10 = int(65.4 * 10)    # already int
    d.light_raw = 0.0            # becomes 0
    d.uptime_ms = 1000.9         # becomes 1000
    packed = EnvironmentalSerializer.pack(d)
    assert len(packed) == EnvironmentalSerializer.SIZE


def test_pack_out_of_range_clamped():
    # Values beyond protocol bounds should clamp without raising
    d = make_data(999999, 999999, 999999, 999999, 999999999999)
    packed = EnvironmentalSerializer.pack(d)
    assert len(packed) == EnvironmentalSerializer.SIZE


def test_pack_negative_values():
    # Negative values for unsigned fields should clamp to 0
    d = make_data(-10, -40000, -50, -1, -5)
    packed = EnvironmentalSerializer.pack(d)
    assert len(packed) == EnvironmentalSerializer.SIZE


def test_pack_missing_attribute_defaults():
    # Missing attributes should default to 0 and still pack successfully
    d = make_data(1, 1, 1, 1, 1)
    delattr(d, 'co2_ppm')
    packed = EnvironmentalSerializer.pack(d)
    assert len(packed) == EnvironmentalSerializer.SIZE


if __name__ == "__main__":
    # Simple manual runner fallback
    for fn in [
        test_pack_nominal,
        test_pack_with_none_and_floats,
        test_pack_out_of_range_clamped,
        test_pack_negative_values,
        test_pack_missing_attribute_defaults,
    ]:
        fn()
    print("All EnvironmentalSerializer tests passed.")
