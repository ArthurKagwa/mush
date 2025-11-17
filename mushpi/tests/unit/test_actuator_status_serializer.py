"""Basic tests for ActuatorStatusSerializer."""

from app.ble.serialization import ActuatorStatusSerializer


def test_actuator_status_pack_unpack():
    # LIGHT + MIST
    bits = (1 << 0) | (1 << 2)
    packed = ActuatorStatusSerializer.pack(bits)
    assert isinstance(packed, (bytes, bytearray))
    assert len(packed) == ActuatorStatusSerializer.SIZE == 2
    unpacked = ActuatorStatusSerializer.unpack(packed)
    assert unpacked & 0x0F == bits


if __name__ == "__main__":
    test_actuator_status_pack_unpack()
    print("ActuatorStatusSerializer tests passed.")
