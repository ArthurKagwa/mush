import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import '../core/utils/ble_serializer.dart';
import '../core/constants/ble_constants.dart';
import 'ble_provider.dart';
import 'database_provider.dart';

/// Exposes current control targets from the device for showing actuator modes
/// on the monitoring screen (e.g., Light mode and cycle timings).
///
/// Note: The device currently does not expose real-time relay ON/OFF states
/// over BLE; only the configured targets and modes are readable. This provider
/// fetches the latest ControlTargetsData when watched/refreshed.
final controlTargetsFutureProvider =
    FutureProvider<ControlTargetsData?>((ref) async {
  final bleOps = ref.read(bleOperationsProvider);
  final bleRepo = ref.read(bleRepositoryProvider);
  final settingsDao = ref.read(settingsDaoProvider);

  // Guard: don't attempt BLE read when not connected
  if (!bleRepo.isConnected) {
    final useCache =
        dotenv.env['MUSHPI_BLE_OFFLINE_USE_CACHE']?.toLowerCase() == 'true';
    if (useCache) {
      try {
        final cached = await settingsDao.getValue('last_control_targets_json');
        if (cached == null || cached.isEmpty) return null;
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return ControlTargetsData(
          tempMin: (map['tempMin'] as num).toDouble(),
          tempMax: (map['tempMax'] as num).toDouble(),
          rhMin: (map['rhMin'] as num).toDouble(),
          co2Max: map['co2Max'] as int,
          lightMode: LightMode.fromValue(map['lightMode'] as int),
          onMinutes: map['onMinutes'] as int,
          offMinutes: map['offMinutes'] as int,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  try {
    return await bleOps.readControlTargets();
  } catch (_) {
    return null;
  }
});
