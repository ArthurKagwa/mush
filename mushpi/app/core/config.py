"""
MushPi Configuration Management

Centralized configuration loading with environment variables, defaults, and validation.
Ensures no hardcoded values in the application code.
"""

import os
import logging
from pathlib import Path
from typing import Union, Dict, Any, Optional
from dataclasses import dataclass

# Setup basic logging for configuration loading
logger = logging.getLogger(__name__)


@dataclass
class SystemPaths:
    """System path configurations"""
    app_dir: Path
    data_dir: Path
    config_dir: Path
    venv_path: Path
    
    def __post_init__(self):
        """Ensure paths are Path objects and create directories if needed"""
        self.app_dir = Path(self.app_dir)
        self.data_dir = Path(self.data_dir)
        self.config_dir = Path(self.config_dir)
        self.venv_path = Path(self.venv_path)
        
        # Create directories if they don't exist
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.config_dir.mkdir(parents=True, exist_ok=True)


@dataclass
class DatabaseConfig:
    """Database configuration"""
    path: Path
    timeout: int
    
    def __post_init__(self):
        self.path = Path(self.path)
        # Create parent directory if needed
        self.path.parent.mkdir(parents=True, exist_ok=True)


@dataclass
class GPIOConfig:
    """GPIO pin configurations"""
    dht22_pin: int
    relay_fan: int
    relay_mist: int
    relay_light: int
    relay_heater: int
    
    def get_relay_pins(self) -> Dict[str, int]:
        """Get relay pins as dictionary for backward compatibility"""
        return {
            'humidifier': self.relay_mist,
            'exhaust_fan': self.relay_fan,
            'circulation_fan': self.relay_fan,  # Same as exhaust for now
            'grow_light': self.relay_light,
            'heater': self.relay_heater
        }


@dataclass
class I2CConfig:
    """I2C device configurations"""
    scd41_address: int
    ads1115_address: int
    light_sensor_channel: int


@dataclass
class SensorTimingConfig:
    """Sensor timing configurations"""
    scd41_interval: float
    dht22_interval: float
    light_interval: float
    monitor_interval: float


@dataclass
class HardwareCalibrationConfig:
    """Hardware calibration configurations"""
    light_fixed_resistor: int
    light_vcc: float
    light_min_resistance: int
    light_max_resistance: int


@dataclass
class ControlConfig:
    """Control system configurations"""
    relay_active_high: bool
    temp_hysteresis: float
    humidity_hysteresis: float
    co2_hysteresis: float
    light_on_threshold: float
    light_off_threshold: float
    light_verification_delay: float


@dataclass
class BluetoothConfig:
    """Bluetooth configuration"""
    service_uuid: str
    name_prefix: str


@dataclass
class LoggingConfig:
    """Logging configuration"""
    level: str
    file: Optional[str]
    max_size: int
    backup_count: int


@dataclass
class DevelopmentConfig:
    """Development and testing configuration"""
    simulation_mode: bool
    debug_mode: bool
    test_mode: bool


class ConfigurationManager:
    """Centralized configuration management with environment variables"""
    
    def __init__(self, env_file: Optional[str] = None):
        """Initialize configuration manager
        
        Args:
            env_file: Optional path to .env file to load
        """
        self._load_env_file(env_file)
        self._load_all_configs()
        
    def _load_env_file(self, env_file: Optional[str]) -> None:
        """Load environment variables from .env file if it exists"""
        if env_file:
            env_path = Path(env_file)
        else:
            # Look for .env in current directory or parent directories
            current_dir = Path.cwd()
            env_path = None
            for path in [current_dir] + list(current_dir.parents):
                potential_env = path / '.env'
                if potential_env.exists():
                    env_path = potential_env
                    break
                    
        if env_path and env_path.exists():
            logger.info(f"Loading environment from {env_path}")
            with open(env_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        # Strip inline comments from value (e.g., "17 # GPIO 17...")
                        value = value.split('#', 1)[0].strip()
                        os.environ.setdefault(key.strip(), value)
        else:
            logger.info("No .env file found, using system environment variables only")
            
    def _get_env_var(self, key: str, default: Any, var_type: type = str) -> Any:
        """Get environment variable with type conversion and default"""
        value = os.environ.get(key, default)
        
        if value == default:
            return default
            
        # Type conversion
        try:
            if var_type == bool:
                return str(value).lower() in ('true', '1', 'yes', 'on')
            elif var_type == int:
                if isinstance(value, str) and value.startswith('0x'):
                    return int(value, 16)  # Hexadecimal conversion
                return int(value)
            elif var_type == float:
                return float(value)
            elif var_type == Path:
                return Path(value)
            else:
                return str(value)
        except (ValueError, TypeError) as e:
            logger.warning(f"Invalid value for {key}: {value}, using default {default}. Error: {e}")
            return default
            
    def _load_all_configs(self) -> None:
        """Load all configuration sections"""
        # System Paths
        self.paths = SystemPaths(
            app_dir=self._get_env_var('MUSHPI_APP_DIR', '/opt/mushpi/app', Path),
            data_dir=self._get_env_var('MUSHPI_DATA_DIR', '/opt/mushpi/data', Path),
            config_dir=self._get_env_var('MUSHPI_CONFIG_DIR', '/opt/mushpi/app/config', Path),
            venv_path=self._get_env_var('MUSHPI_VENV_PATH', '/opt/mushpi/.venv', Path)
        )
        
        # Database
        self.database = DatabaseConfig(
            path=self._get_env_var('MUSHPI_DB_PATH', 'data/sensors.db', Path),
            timeout=self._get_env_var('MUSHPI_DB_TIMEOUT', 30, int)
        )
        
        # GPIO
        self.gpio = GPIOConfig(
            dht22_pin=self._get_env_var('MUSHPI_DHT22_PIN', 4, int),
            relay_fan=self._get_env_var('MUSHPI_RELAY_FAN', 17, int),
            relay_mist=self._get_env_var('MUSHPI_RELAY_MIST', 27, int),
            relay_light=self._get_env_var('MUSHPI_RELAY_LIGHT', 22, int),
            relay_heater=self._get_env_var('MUSHPI_RELAY_HEATER', 23, int)
        )
        
        # I2C
        self.i2c = I2CConfig(
            scd41_address=self._get_env_var('MUSHPI_SCD41_ADDRESS', 0x62, int),
            ads1115_address=self._get_env_var('MUSHPI_ADS1115_ADDRESS', 0x48, int),
            light_sensor_channel=self._get_env_var('MUSHPI_LIGHT_SENSOR_CHANNEL', 0, int)
        )
        
        # Sensor Timing
        self.timing = SensorTimingConfig(
            scd41_interval=self._get_env_var('MUSHPI_SCD41_INTERVAL', 5.0, float),
            dht22_interval=self._get_env_var('MUSHPI_DHT22_INTERVAL', 2.0, float),
            light_interval=self._get_env_var('MUSHPI_LIGHT_INTERVAL', 1.0, float),
            monitor_interval=self._get_env_var('MUSHPI_MONITOR_INTERVAL', 30.0, float)
        )
        
        # Hardware Calibration
        self.calibration = HardwareCalibrationConfig(
            light_fixed_resistor=self._get_env_var('MUSHPI_LIGHT_FIXED_RESISTOR', 10000, int),
            light_vcc=self._get_env_var('MUSHPI_LIGHT_VCC', 3.3, float),
            light_min_resistance=self._get_env_var('MUSHPI_LIGHT_MIN_RESISTANCE', 1000, int),
            light_max_resistance=self._get_env_var('MUSHPI_LIGHT_MAX_RESISTANCE', 100000, int)
        )
        
        # Control System
        self.control = ControlConfig(
            relay_active_high=self._get_env_var('MUSHPI_RELAY_ACTIVE_HIGH', True, bool),
            temp_hysteresis=self._get_env_var('MUSHPI_TEMP_HYSTERESIS', 1.0, float),
            humidity_hysteresis=self._get_env_var('MUSHPI_HUMIDITY_HYSTERESIS', 3.0, float),
            co2_hysteresis=self._get_env_var('MUSHPI_CO2_HYSTERESIS', 100.0, float),
            light_on_threshold=self._get_env_var('MUSHPI_LIGHT_ON_THRESHOLD', 200.0, float),
            light_off_threshold=self._get_env_var('MUSHPI_LIGHT_OFF_THRESHOLD', 50.0, float),
            light_verification_delay=self._get_env_var('MUSHPI_LIGHT_VERIFICATION_DELAY', 30.0, float)
        )
        
        # Bluetooth
        self.bluetooth = BluetoothConfig(
            service_uuid=self._get_env_var('MUSHPI_BLE_SERVICE_UUID', '12345678-1234-5678-1234-56789abcdef0'),
            name_prefix=self._get_env_var('MUSHPI_BLE_NAME_PREFIX', 'MushPi')
        )
        
        # Logging
        self.logging = LoggingConfig(
            level=self._get_env_var('MUSHPI_LOG_LEVEL', 'INFO'),
            file=self._get_env_var('MUSHPI_LOG_FILE', None),
            max_size=self._get_env_var('MUSHPI_LOG_MAX_SIZE', 10, int),
            backup_count=self._get_env_var('MUSHPI_LOG_BACKUP_COUNT', 5, int)
        )
        
        # Development
        self.development = DevelopmentConfig(
            simulation_mode=self._get_env_var('MUSHPI_SIMULATION_MODE', False, bool),
            debug_mode=self._get_env_var('MUSHPI_DEBUG_MODE', False, bool),
            test_mode=self._get_env_var('MUSHPI_TEST_MODE', False, bool)
        )
        
        # Thresholds path (special handling for relative/absolute paths)
        thresholds_path = self._get_env_var('MUSHPI_THRESHOLDS_PATH', 'config/thresholds.json')
        if not Path(thresholds_path).is_absolute():
            self.thresholds_path = self.paths.app_dir / thresholds_path
        else:
            self.thresholds_path = Path(thresholds_path)
            
    def validate_configuration(self) -> bool:
        """Validate configuration values"""
        try:
            # Validate GPIO pins are in valid range
            gpio_pins = [self.gpio.dht22_pin, self.gpio.relay_fan, 
                        self.gpio.relay_mist, self.gpio.relay_light, self.gpio.relay_heater]
            for pin in gpio_pins:
                if not (0 <= pin <= 40):
                    logger.error(f"Invalid GPIO pin: {pin}. Must be 0-40")
                    return False
                    
            # Validate I2C addresses
            if not (0x00 <= self.i2c.scd41_address <= 0x7F):
                logger.error(f"Invalid SCD41 I2C address: 0x{self.i2c.scd41_address:02x}")
                return False
                
            if not (0x00 <= self.i2c.ads1115_address <= 0x7F):
                logger.error(f"Invalid ADS1115 I2C address: 0x{self.i2c.ads1115_address:02x}")
                return False
                
            # Validate timing intervals
            if any(interval <= 0 for interval in [self.timing.scd41_interval, 
                                                 self.timing.dht22_interval, 
                                                 self.timing.light_interval, 
                                                 self.timing.monitor_interval]):
                logger.error("All timing intervals must be positive")
                return False
                
            # Validate log level
            valid_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
            if self.logging.level.upper() not in valid_levels:
                logger.error(f"Invalid log level: {self.logging.level}. Must be one of {valid_levels}")
                return False
                
            logger.info("Configuration validation passed")
            return True
            
        except Exception as e:
            logger.error(f"Configuration validation failed: {e}")
            return False
            
    def get_summary(self) -> Dict[str, Any]:
        """Get configuration summary for logging/debugging"""
        return {
            'paths': {
                'app_dir': str(self.paths.app_dir),
                'data_dir': str(self.paths.data_dir),
                'config_dir': str(self.paths.config_dir),
                'database': str(self.database.path),
                'thresholds': str(self.thresholds_path)
            },
            'gpio': {
                'dht22_pin': self.gpio.dht22_pin,
                'relay_pins': self.gpio.get_relay_pins()
            },
            'i2c': {
                'scd41_address': f"0x{self.i2c.scd41_address:02x}",
                'ads1115_address': f"0x{self.i2c.ads1115_address:02x}"
            },
            'timing': {
                'monitor_interval': self.timing.monitor_interval,
                'sensor_intervals': {
                    'scd41': self.timing.scd41_interval,
                    'dht22': self.timing.dht22_interval,
                    'light': self.timing.light_interval
                }
            },
            'modes': {
                'simulation': self.development.simulation_mode,
                'debug': self.development.debug_mode,
                'test': self.development.test_mode
            }
        }


# Global configuration instance
config = ConfigurationManager()

# Validate configuration on import
if not config.validate_configuration():
    logger.warning("Configuration validation failed - some features may not work correctly")

# Export commonly used values for backward compatibility
DHT22_PIN = config.gpio.dht22_pin
RELAY_PINS = config.gpio.get_relay_pins()
SCD41_ADDRESS = config.i2c.scd41_address
ADS1115_ADDRESS = config.i2c.ads1115_address
DB_PATH = config.database.path
THRESHOLDS_JSON = config.thresholds_path