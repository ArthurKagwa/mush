"""
ThingSpeak data publisher for MushPi sensor readings.

This module sends readings to ThingSpeak when enabled via configuration.
All configuration is provided through environment variables loaded into
`config.thingspeak` (see `ThingSpeakConfig` in `app.core.config`).
"""

import logging
import time
from typing import Optional, Dict
from urllib import request, parse

from ..models.dataclasses import SensorReading
from ..core.config import config

logger = logging.getLogger(__name__)

# Module-level state for simple rate limiting
_last_publish_ts: Optional[float] = None


def _build_payload(reading: SensorReading) -> Dict[str, str]:
    """Build ThingSpeak payload from a SensorReading and current config.

    Only non-None values are included, and only for fields that have been
    mapped via environment variables.
    """
    ts_cfg = config.thingspeak
    payload: Dict[str, str] = {}

    # Required write key
    payload["api_key"] = ts_cfg.api_key

    # Optional channel identifier (ThingSpeak may ignore this, but we send it if configured)
    if ts_cfg.channel_id:
        payload["channel_id"] = ts_cfg.channel_id

    # Field mappings are all driven by env configuration
    if reading.temperature_c is not None and ts_cfg.field_temperature:
        payload[ts_cfg.field_temperature] = f"{reading.temperature_c:.2f}"

    if reading.humidity_percent is not None and ts_cfg.field_humidity:
        payload[ts_cfg.field_humidity] = f"{reading.humidity_percent:.2f}"

    if reading.co2_ppm is not None and ts_cfg.field_co2:
        payload[ts_cfg.field_co2] = str(reading.co2_ppm)

    if reading.light_level is not None and ts_cfg.field_light:
        payload[ts_cfg.field_light] = f"{reading.light_level:.2f}"

    return payload


def _should_publish_now(min_interval_seconds: int) -> bool:
    """Simple rate limiter: publish at most once per configured interval."""
    global _last_publish_ts

    # Ensure a sane minimum interval
    if min_interval_seconds <= 0:
        min_interval_seconds = 300  # Fallback to 5 minutes

    now = time.time()
    if _last_publish_ts is None or now - _last_publish_ts >= min_interval_seconds:
        _last_publish_ts = now
        return True

    return False


def publish_reading_to_thingspeak(reading: SensorReading) -> None:
    """Publish a sensor reading to ThingSpeak if integration is enabled.

    This function is safe to call on every sensor loop:
    - No-op if integration is disabled.
    - Rate-limited to at most one publish per `config.thingspeak.min_interval_seconds`.
    - Swallows network errors with logging so control loop is never blocked.
    """
    ts_cfg = config.thingspeak

    if not ts_cfg.enabled:
        return

    if not ts_cfg.api_key:
        logger.warning("ThingSpeak enabled but MUSHPI_THINGSPEAK_API_KEY is not set - skipping publish")
        return

    if not ts_cfg.update_url:
        logger.warning("ThingSpeak enabled but MUSHPI_THINGSPEAK_UPDATE_URL is not set - skipping publish")
        return

    # Build payload from reading + field mapping
    payload = _build_payload(reading)

    # If no mapped fields have values, there's nothing to publish
    field_keys = {ts_cfg.field_temperature, ts_cfg.field_humidity, ts_cfg.field_co2, ts_cfg.field_light}
    field_keys.discard("")  # Remove empty mappings
    if not field_keys or len(payload.keys() - {"api_key", "channel_id"}) == 0:
        logger.debug("ThingSpeak enabled but no fields are mapped or no data available - skipping publish")
        return

    # Rate limiting: only send if interval has elapsed
    if not _should_publish_now(ts_cfg.min_interval_seconds):
        logger.debug("ThingSpeak publish skipped due to rate limiting")
        return

    try:
        data = parse.urlencode(payload).encode("utf-8")
        req = request.Request(ts_cfg.update_url, data=data, method="POST")

        logger.debug("Publishing reading to ThingSpeak at %s", ts_cfg.update_url)
        with request.urlopen(req, timeout=ts_cfg.timeout_seconds) as resp:
            status = resp.getcode()
            if status != 200:
                logger.warning("ThingSpeak returned non-200 status: %s", status)
            else:
                logger.info("✅ ThingSpeak publish succeeded (status=%s)", status)
    except Exception as e:
        # Network / HTTP errors should never crash the control loop
        logger.warning("ThingSpeak publish failed: %s", e, exc_info=True)


