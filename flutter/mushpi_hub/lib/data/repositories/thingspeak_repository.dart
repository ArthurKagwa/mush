import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mushpi_hub/data/config/thingspeak_config.dart';
import 'package:mushpi_hub/data/database/app_database.dart';
import 'package:intl/intl.dart';

/// Repository for fetching historical readings from ThingSpeak.
///
/// This is used to "fill in the blanks" on charts when the local database
/// has gaps (e.g., phone was offline) but the Pi successfully pushed data
/// to ThingSpeak.
class ThingSpeakRepository {
  ThingSpeakRepository({ThingSpeakConfig? config})
      : _config = config ?? ThingSpeakConfig.fromEnv();

  final ThingSpeakConfig _config;

  bool get isEnabled => _config.hasRequiredCredentials;

  /// Fetch readings for a time window and map them into `Reading` models.
  ///
  /// The `farmId` is attached to each Reading so they can be merged with
  /// local DB readings for that farm, but the data itself comes entirely
  /// from ThingSpeak.
  Future<List<Reading>> fetchReadingsForPeriod({
    required String farmId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isEnabled) {
      return const [];
    }

    try {
      final uri = Uri.parse(
        '${_config.baseUrl}/${_config.channelId}/feeds.json',
      ).replace(
        queryParameters: {
          'api_key': _config.readApiKey,
          // Use ISO8601 in UTC; ThingSpeak supports start/end query params.
          'start': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(start.toUtc()),
          'end': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(end.toUtc()),
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        // Non-200 is treated as "no remote data" to avoid breaking UI.
        return const [];
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final feeds = decoded['feeds'];
      if (feeds is! List) {
        return const [];
      }

      final readings = <Reading>[];
      for (final feed in feeds) {
        if (feed is! Map<String, dynamic>) continue;

        final createdAtRaw = feed['created_at'] as String?;
        if (createdAtRaw == null) continue;

        DateTime timestamp;
        try {
          timestamp = DateTime.parse(createdAtRaw).toLocal();
        } catch (_) {
          continue;
        }

        final tempStr = _getField(feed, _config.fieldTemperature);
        final rhStr = _getField(feed, _config.fieldHumidity);
        final co2Str = _getField(feed, _config.fieldCo2);
        final lightStr = _getField(feed, _config.fieldLight);

        if (tempStr == null ||
            rhStr == null ||
            co2Str == null ||
            lightStr == null) {
          // Require all four values to avoid partial/invalid points.
          continue;
        }

        final temp = double.tryParse(tempStr);
        final rh = double.tryParse(rhStr);
        final co2 = int.tryParse(co2Str);
        final light = int.tryParse(lightStr);

        if (temp == null || rh == null || co2 == null || light == null) {
          continue;
        }

        readings.add(
          Reading(
            id: 0, // In-memory only; not persisted to DB
            farmId: farmId,
            timestamp: timestamp,
            co2Ppm: co2,
            temperatureC: temp,
            relativeHumidity: rh,
            lightRaw: light,
          ),
        );
      }

      return readings;
    } catch (_) {
      // On any error (network, parse), fall back to local-only data.
      return const [];
    }
  }

  /// Fetch the latest reading from ThingSpeak.
  ///
  /// Returns the most recent feed entry as a Reading, or null if no data available.
  Future<Reading?> fetchLatestReading({required String farmId}) async {
    if (!isEnabled) {
      return null;
    }

    try {
      final uri = Uri.parse(
        '${_config.baseUrl}/${_config.channelId}/feeds.json',
      ).replace(
        queryParameters: {
          'api_key': _config.readApiKey,
          'results': '1', // Only fetch the latest entry
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final feeds = decoded['feeds'];
      if (feeds is! List || feeds.isEmpty) {
        return null;
      }

      final feed = feeds.first;
      if (feed is! Map<String, dynamic>) return null;

      final createdAtRaw = feed['created_at'] as String?;
      if (createdAtRaw == null) return null;

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(createdAtRaw).toLocal();
      } catch (_) {
        return null;
      }

      final tempStr = _getField(feed, _config.fieldTemperature);
      final rhStr = _getField(feed, _config.fieldHumidity);
      final co2Str = _getField(feed, _config.fieldCo2);
      final lightStr = _getField(feed, _config.fieldLight);

      if (tempStr == null ||
          rhStr == null ||
          co2Str == null ||
          lightStr == null) {
        return null;
      }

      final temp = double.tryParse(tempStr);
      final rh = double.tryParse(rhStr);
      final co2 = int.tryParse(co2Str);
      final light = int.tryParse(lightStr);

      if (temp == null || rh == null || co2 == null || light == null) {
        return null;
      }

      return Reading(
        id: 0, // In-memory only; not persisted to DB
        farmId: farmId,
        timestamp: timestamp,
        co2Ppm: co2,
        temperatureC: temp,
        relativeHumidity: rh,
        lightRaw: light,
      );
    } catch (_) {
      return null;
    }
  }

  String? _getField(Map<String, dynamic> feed, String fieldName) {
    if (fieldName.isEmpty) return null;
    final value = feed[fieldName];
    if (value == null) return null;
    return value.toString();
  }
}


