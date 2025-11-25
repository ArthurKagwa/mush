import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ThingSpeak configuration for the Flutter app.
///
/// All values are loaded from the runtime `.env` file via flutter_dotenv.
/// No hard-coded API keys, channel IDs, or field mappings are used.
class ThingSpeakConfig {
  final bool enabled;
  final String readApiKey;
  final String channelId;
  final String baseUrl;
  final String fieldTemperature;
  final String fieldHumidity;
  final String fieldCo2;
  final String fieldLight;

  const ThingSpeakConfig({
    required this.enabled,
    required this.readApiKey,
    required this.channelId,
    required this.baseUrl,
    required this.fieldTemperature,
    required this.fieldHumidity,
    required this.fieldCo2,
    required this.fieldLight,
  });

  /// Load configuration from `.env` using flutter_dotenv.
  ///
  /// This intentionally does not provide default API keys or channel IDs;
  /// if required values are missing, the integration will be considered
  /// "effectively disabled" at runtime.
  static ThingSpeakConfig fromEnv() {
    final env = dotenv.env;

    bool _getBool(String key, bool defaultValue) {
      final v = env[key];
      if (v == null) return defaultValue;
      final lower = v.toLowerCase().trim();
      return lower == 'true' ||
          lower == '1' ||
          lower == 'yes' ||
          lower == 'on';
    }

    String _getString(String key, [String defaultValue = '']) {
      final v = env[key];
      if (v == null) return defaultValue;
      return v.trim();
    }

    return ThingSpeakConfig(
      enabled: _getBool('MUSHPI_THINGSPEAK_ENABLED', false),
      // Separate read key so backend can use write key; caller may set them equal.
      readApiKey: _getString('MUSHPI_THINGSPEAK_READ_API_KEY'),
      channelId: _getString('MUSHPI_THINGSPEAK_CHANNEL_ID'),
      baseUrl: _getString(
        'MUSHPI_THINGSPEAK_BASE_URL',
        'https://api.thingspeak.com/channels',
      ),
      fieldTemperature: _getString('MUSHPI_THINGSPEAK_FIELD_TEMPERATURE'),
      fieldHumidity: _getString('MUSHPI_THINGSPEAK_FIELD_HUMIDITY'),
      fieldCo2: _getString('MUSHPI_THINGSPEAK_FIELD_CO2'),
      fieldLight: _getString('MUSHPI_THINGSPEAK_FIELD_LIGHT'),
    );
  }

  bool get hasRequiredCredentials =>
      enabled && readApiKey.isNotEmpty && channelId.isNotEmpty;
}


