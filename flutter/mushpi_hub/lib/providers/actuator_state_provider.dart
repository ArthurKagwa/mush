import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/ble_serializer.dart';
import 'ble_provider.dart';

/// Exposes current control targets from the device for showing actuator modes
/// on the monitoring screen (e.g., Light mode and cycle timings).
///
/// Note: The device currently does not expose real-time relay ON/OFF states
/// over BLE; only the configured targets and modes are readable. This provider
/// fetches the latest ControlTargetsData when watched/refreshed.
final controlTargetsFutureProvider =
    FutureProvider<ControlTargetsData?>((ref) async {
  final bleOps = ref.read(bleOperationsProvider);
  try {
    return await bleOps.readControlTargets();
  } catch (_) {
    return null;
  }
});
