# MushPi Hub (Flutter Mobile Controller)

MushPi Hub is the Flutter-based mobile controller for the MushPi mushroom cultivation system. It connects to a Raspberry Pi running the MushPi BLE GATT service and provides:

* Device scanning and secure, bondless BLE connection
* Real-time environmental monitoring (CO₂, temperature, humidity, light)
* Control target configuration (temperature, humidity, CO₂, lighting cycle)
* Stage management (species, growth stage, automation mode, expected duration)
* Manual override bits and status flags visualization
* Multi-farm management with persistent local database (Drift)

## Environment Configuration (.env)

All runtime configuration is provided via a `.env` file (declared in `pubspec.yaml` assets). No hard-coded values; absence of a key falls back to safe defaults. Load occurs in `lib/main.dart`:

```dart
await dotenv.load(fileName: '.env');
BLERepository.setRuntimeEnv(dotenv.env);
```

Create a local `.env` (never commit secrets). An example template is available in `.env.example`.

### Core BLE Write Preferences

| Key | Purpose | Default |
| --- | --- | --- |
| `MUSHPI_BLE_CONTROL_PREFER_NO_RESPONSE` | Prefer WRITE_NO_RESPONSE for Control Targets | false |
| `MUSHPI_BLE_STAGE_PREFER_NO_RESPONSE` | Prefer WRITE_NO_RESPONSE for Stage State | false |
| `MUSHPI_BLE_OVERRIDE_PREFER_NO_RESPONSE` | Prefer WRITE_NO_RESPONSE for Override Bits | true |
| `MUSHPI_BLE_WRITE_RETRY_DELAY_MS` | Delay between fallback write attempts | 200 |

### Read Robustness (Control Targets)

| Key | Purpose | Default |
| --- | --- | --- |
| `MUSHPI_BLE_READ_TIMEOUT_MS` | Max time for a single read attempt | 4000 |
| `MUSHPI_BLE_READ_RETRY_DELAY_MS` | Delay before retry on failure | 600 |
| `MUSHPI_BLE_READ_MAX_RETRIES` | Number of retry attempts (in addition to first) | 1 |

### Stage Write Backward Compatibility

Older Pi deployments may only recognize a subset of species IDs (e.g., only Oyster). The repository normalizes the outgoing StageState before serialization using env-driven mapping and allow-lists—no mock data, no hard-coded species remapping.

| Key | Purpose | Example |
| --- | --- | --- |
| `MUSHPI_SPECIES_WRITE_COMPAT_MAP` | Comma list of `src:dst` species ID mappings | `99:1,3:1` |
| `MUSHPI_PI_SUPPORTED_SPECIES_IDS` | Comma list of species IDs Pi currently supports | `1,2,3` |
| `MUSHPI_SPECIES_FALLBACK_ID` | Fallback species ID if unsupported & not mapped | `1` |
| `MUSHPI_STAGE_EXPECTED_DAYS_MIN` | Lower clamp for expectedDays | `1` |
| `MUSHPI_STAGE_EXPECTED_DAYS_MAX` | Upper clamp for expectedDays | `365` |

Behavior precedence:
1. If `MUSHPI_SPECIES_WRITE_COMPAT_MAP` contains the outgoing species ID, map it.
2. Else if `MUSHPI_PI_SUPPORTED_SPECIES_IDS` is defined and ID not in list, fallback to first allowed.
3. Else if the species is legacy Custom (99) and `MUSHPI_SPECIES_FALLBACK_ID` provided, use that.
4. Clamp `expectedDays` within min/max if provided.

Logging tag: `BLERepository.BC` (e.g., mapping/clamp events).

### Optional Offline Cache

| Key | Purpose | Default |
| --- | --- | --- |
| `MUSHPI_BLE_OFFLINE_USE_CACHE` | Show last cached Control Targets when offline | true |

## Testing Stage Write Compatibility

1. Add to `.env` (example):
	 ```env
	 MUSHPI_SPECIES_WRITE_COMPAT_MAP=99:1
	 MUSHPI_PI_SUPPORTED_SPECIES_IDS=1
	 MUSHPI_SPECIES_FALLBACK_ID=1
	 MUSHPI_STAGE_EXPECTED_DAYS_MIN=1
	 MUSHPI_STAGE_EXPECTED_DAYS_MAX=180
	 ```
2. Launch app and connect to Pi that only has Oyster thresholds.
3. In Stage screen, select a species that maps (e.g., Custom if ID=99 in UI).
4. Tap Update Stage.
5. Confirm on Pi logs that stage state accepted (no unknown species rejection) and `expectedDays` within clamp.
6. Remove mapping to test fallback behavior.

## BLE Packet Formats (Wire Contract)

| Characteristic | Size | Fields |
| -------------- | ---- | ------ |
| Environmental | 12 | u16 co2, s16 temp×10, u16 rh×10, u16 light, u32 uptime_ms |
| Control Targets | 15 | s16 tMin×10, s16 tMax×10, u16 rhMin×10, u16 co2Max, u8 lightMode, u16 onMin, u16 offMin, u16 reserved |
| Stage State | 10 | u8 mode, u8 species, u8 stage, u32 start_ts, u16 expected_days, u8 reserved |
| Override Bits | 2 | u16 bitfield |
| Status Flags | 4 | u32 bitfield |

All fields little-endian. Writes use `_smartWrite()` with capability-based fallbacks.

## Local Development Quick Start

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```

If `.env` is missing you will see a warning; the app runs with defaults.

## Project Principles

* No mock data – all persisted values originate from actual BLE packets or user input.
* Environment-driven configuration – removal of a key reverts behavior safely.
* Backward compatibility – client adapts to legacy Pi species restrictions without Pi changes.
* Logging transparency – structured logs for scan, connect, discover, notify, read, write, and normalization events.
* Maintainability – modular serializers, repositories, providers, and screens.

## Repository Structure (Excerpt)

```
lib/
	core/constants/ble_constants.dart
	core/utils/ble_serializer.dart
	data/repositories/ble_repository.dart
	screens/stage_screen.dart
	screens/control_screen.dart
	app.dart
	main.dart
```

## Next Enhancements

* Config streaming characteristics integration (GET/PUT JSON) with chunk framing.
* Stage serializer tests + control target offline stale indicator.
* Unified config/env service for future dynamic negotiation.

## License

Internal project – proprietary MushPi system components. Do not redistribute without authorization.
