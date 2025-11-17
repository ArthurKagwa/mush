#!/usr/bin/env python3
"""
MushPi Light Control Script (Standalone Version)

Checks current light status and controls it according to the proper mushroom cultivation schedule.
Handles different stages (Incubation, Pinning, Fruiting) with appropriate light cycles.
"""

import json
import logging
import os
from datetime import datetime
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class LightController:
    """Controls grow light according to mushroom cultivation schedule"""
    
    def __init__(self):
        self.simulation_mode = True  # Default to simulation mode
        self.light_pin = 22  # GPIO pin for light relay
        self.gpio_available = False
        
        # Configuration paths
        self.config_dir = Path("mushpi/app/config")
        self.data_dir = Path("data")
        self.thresholds_file = self.config_dir / "thresholds.json"
        self.stage_config_file = self.data_dir / "stage_config.json"
        
        # Create directories
        self.data_dir.mkdir(exist_ok=True)
        
        # Try to determine if we're on actual Pi hardware
        try:
            import RPi.GPIO as GPIO
            self.simulation_mode = False
            self.gpio_available = True
            logger.info("GPIO available - real hardware mode")
            self._init_gpio()
        except ImportError:
            logger.info("GPIO not available - simulation mode")
            
    def _init_gpio(self):
        """Initialize GPIO for relay control"""
        try:
            import RPi.GPIO as GPIO
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(self.light_pin, GPIO.OUT)
            GPIO.output(self.light_pin, GPIO.LOW)  # Start with light OFF
            logger.info(f"GPIO initialized - Light relay on pin {self.light_pin}")
        except Exception as e:
            logger.error(f"GPIO initialization failed: {e}")
            self.simulation_mode = True
            
    def load_thresholds(self):
        """Load mushroom thresholds configuration"""
        try:
            with open(self.thresholds_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading thresholds: {e}")
            return {}
            
    def get_current_stage_config(self):
        """Get or create current stage configuration"""
        try:
            if self.stage_config_file.exists():
                with open(self.stage_config_file, 'r') as f:
                    config = json.load(f)
            else:
                # Create default configuration for Pinning stage (most common for light needs)
                config = {
                    'species': 'Oyster',
                    'stage': 'Pinning', 
                    'start_time': datetime.now().isoformat(),
                    'mode': 'semi'
                }
                self.save_stage_config(config)
                
            return config
        except Exception as e:
            logger.error(f"Error loading stage config: {e}")
            return {
                'species': 'Oyster',
                'stage': 'Pinning',
                'start_time': datetime.now().isoformat(),
                'mode': 'semi'
            }
            
    def save_stage_config(self, config):
        """Save stage configuration"""
        try:
            with open(self.stage_config_file, 'w') as f:
                json.dump(config, f, indent=2)
            logger.info("Stage configuration saved")
        except Exception as e:
            logger.error(f"Error saving stage config: {e}")
            
    def calculate_light_schedule(self):
        """Calculate if light should be on based on current stage and time"""
        thresholds = self.load_thresholds()
        stage_config = self.get_current_stage_config()
        
        species = stage_config.get('species', 'Oyster')
        stage = stage_config.get('stage', 'Pinning')
        
        if species not in thresholds:
            return False, f"Unknown species: {species}"
            
        if stage not in thresholds[species]:
            return False, f"Unknown stage: {stage} for species {species}"
            
        stage_thresholds = thresholds[species][stage]
        light_config = stage_thresholds.get('light', {'mode': 'off'})
        
        current_time = datetime.now()
        mode = light_config.get('mode', 'off')
        
        if mode == 'off':
            return False, f"Light mode: OFF ({species} - {stage})"
            
        elif mode == 'on':
            return True, f"Light mode: ON ({species} - {stage})"
            
        elif mode == 'cycle':
            on_minutes = light_config.get('on_min', 0)
            off_minutes = light_config.get('off_min', 0)
            
            if on_minutes <= 0 or off_minutes <= 0:
                return False, f"Invalid cycle configuration: on={on_minutes}, off={off_minutes}"
                
            # Calculate position in daily cycle (starting from midnight)
            minutes_since_midnight = current_time.hour * 60 + current_time.minute
            cycle_duration = on_minutes + off_minutes
            position_in_cycle = minutes_since_midnight % cycle_duration
            
            should_be_on = position_in_cycle < on_minutes
            
            if should_be_on:
                remaining_on = on_minutes - position_in_cycle
                return True, f"Light ON: {remaining_on:.0f}min remaining in ON phase ({species} - {stage})"
            else:
                remaining_off = cycle_duration - position_in_cycle
                return False, f"Light OFF: {remaining_off:.0f}min until next ON phase ({species} - {stage})"
                
        else:
            return False, f"Unknown light mode: {mode}"
            
    def get_current_light_state(self):
        """Get current physical light state"""
        if self.simulation_mode:
            return None, "Simulation mode - cannot read GPIO state"
            
        try:
            import RPi.GPIO as GPIO
            state = GPIO.input(self.light_pin)
            return bool(state), f"GPIO pin {self.light_pin} reads {'HIGH' if state else 'LOW'}"
        except Exception as e:
            return None, f"Error reading GPIO: {e}"
            
    def set_light_state(self, should_be_on: bool, reason: str):
        """Set the light relay state"""
        if self.simulation_mode:
            action = "Turn ON" if should_be_on else "Turn OFF"
            print(f"🔧 SIMULATION: {action} light relay (Pin {self.light_pin}) - {reason}")
            return True, f"Simulated: {action} light"
            
        try:
            import RPi.GPIO as GPIO
            GPIO.output(self.light_pin, GPIO.HIGH if should_be_on else GPIO.LOW)
            action = "Turned ON" if should_be_on else "Turned OFF"
            print(f"🔧 {action} light relay (Pin {self.light_pin}) - {reason}")
            return True, f"{action} light"
        except Exception as e:
            print(f"❌ Error setting GPIO state: {e}")
            return False, f"Error setting light: {e}"
            
    def check_and_control_light(self):
        """Main function: check if light should be on and control it accordingly"""
        print("=== MushPi Light Control Check ===")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Get stage information
        stage_config = self.get_current_stage_config()
        start_time = datetime.fromisoformat(stage_config['start_time'])
        age_days = (datetime.now() - start_time).total_seconds() / (24 * 3600)
        
        print(f"Current Stage: {stage_config['species']} - {stage_config['stage']} (Day {age_days:.1f})")
        print(f"Stage Mode: {stage_config['mode']}")
        
        # Calculate if light should be on
        should_be_on, schedule_reason = self.calculate_light_schedule()
        print(f"\\nSchedule Analysis: {schedule_reason}")
        print(f"Light SHOULD BE: {'🟢 ON' if should_be_on else '🔴 OFF'}")
        
        # Check current light state
        current_state, state_reason = self.get_current_light_state()
        if current_state is not None:
            print(f"Light IS CURRENTLY: {'🟢 ON' if current_state else '🔴 OFF'} ({state_reason})")
            
            # Determine if action is needed
            if current_state == should_be_on:
                print(f"\\n✅ Light is correctly {'ON' if should_be_on else 'OFF'} - No action needed")
                return True
            else:
                print(f"\\n⚠️  Light state mismatch! Should be {'ON' if should_be_on else 'OFF'} but is {'ON' if current_state else 'OFF'}")
        else:
            print(f"Light CURRENT STATE: ❓ Unknown ({state_reason})")
            print(f"\\n🔧 Will set light to correct state")
            
        # Set correct light state
        success, action_result = self.set_light_state(should_be_on, schedule_reason)
        
        if success:
            print(f"\\n✅ {action_result}")
            return True
        else:
            print(f"\\n❌ {action_result}")
            return False
            
    def get_detailed_schedule_info(self):
        """Get detailed information about all stages and their light schedules"""
        thresholds = self.load_thresholds()
        current_time = datetime.now()
        
        print("=== MushPi Light Schedule Information ===")
        print(f"Current Time: {current_time.strftime('%H:%M:%S (%Y-%m-%d)')}")
        print()
        
        for species, stages in thresholds.items():
            print(f"🍄 {species}:")
            for stage, config in stages.items():
                light_config = config.get('light', {})
                mode = light_config.get('mode', 'off')
                expected_days = config.get('expected_days', 0)
                
                print(f"  📍 {stage} ({expected_days} days):")
                print(f"     Light mode: {mode.upper()}")
                
                if mode == 'cycle':
                    on_min = light_config.get('on_min', 0)
                    off_min = light_config.get('off_min', 0)
                    on_hours = on_min / 60
                    off_hours = off_min / 60
                    
                    print(f"     Cycle: {on_hours:.1f}h ON, {off_hours:.1f}h OFF")
                    
                    # Calculate current status for this stage
                    minutes_since_midnight = current_time.hour * 60 + current_time.minute
                    cycle_duration = on_min + off_min
                    position_in_cycle = minutes_since_midnight % cycle_duration
                    would_be_on = position_in_cycle < on_min
                    
                    print(f"     Would be: {'🟢 ON' if would_be_on else '🔴 OFF'} right now")
                    
                elif mode == 'on':
                    print(f"     Would be: 🟢 ON (always)")
                else:
                    print(f"     Would be: 🔴 OFF")
                    
                print()
                
    def set_stage(self, species: str, stage: str):
        """Set the current mushroom stage"""
        thresholds = self.load_thresholds()
        
        if species not in thresholds:
            print(f"❌ Unknown species: {species}")
            print(f"Available species: {', '.join(thresholds.keys())}")
            return False
            
        if stage not in thresholds[species]:
            print(f"❌ Unknown stage: {stage} for species {species}")
            print(f"Available stages for {species}: {', '.join(thresholds[species].keys())}")
            return False
            
        config = {
            'species': species,
            'stage': stage,
            'start_time': datetime.now().isoformat(),
            'mode': 'semi'
        }
        
        self.save_stage_config(config)
        print(f"✅ Stage set to: {species} - {stage}")
        return True
        
    def cleanup(self):
        """Cleanup GPIO resources"""
        if not self.simulation_mode and self.gpio_available:
            try:
                import RPi.GPIO as GPIO
                GPIO.cleanup()
                logger.info("GPIO cleaned up")
            except:
                pass


def main():
    """Main function for command line usage"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MushPi Light Control', 
                                   formatter_class=argparse.RawDescriptionHelpFormatter,
                                   epilog="""
Examples:
  python3 light_control.py                    # Check and control light according to schedule
  python3 light_control.py --status           # Show detailed schedule information  
  python3 light_control.py --stage Oyster,Pinning  # Set stage to Oyster Pinning
  python3 light_control.py --force-on         # Force light ON regardless of schedule
  python3 light_control.py --force-off        # Force light OFF regardless of schedule
""")
    
    parser.add_argument('--status', action='store_true', help='Show detailed status and schedule info')
    parser.add_argument('--force-on', action='store_true', help='Force light ON regardless of schedule')
    parser.add_argument('--force-off', action='store_true', help='Force light OFF regardless of schedule')
    parser.add_argument('--stage', help='Set mushroom stage (format: "Species,Stage", e.g. "Oyster,Pinning")')
    
    args = parser.parse_args()
    
    controller = LightController()
    
    try:
        if args.stage:
            try:
                species, stage = args.stage.split(',')
                success = controller.set_stage(species.strip(), stage.strip())
                if not success:
                    return 1
            except ValueError:
                print("❌ Stage format should be: Species,Stage (e.g., 'Oyster,Pinning')")
                return 1
                
        if args.status:
            controller.get_detailed_schedule_info()
            
        elif args.force_on:
            success, result = controller.set_light_state(True, "Manual force ON")
            print(f"{'✅' if success else '❌'} {result}")
            
        elif args.force_off:
            success, result = controller.set_light_state(False, "Manual force OFF")
            print(f"{'✅' if success else '❌'} {result}")
            
        else:
            # Default behavior: check and control according to schedule
            success = controller.check_and_control_light()
            return 0 if success else 1
            
    finally:
        controller.cleanup()
        
    return 0


if __name__ == '__main__':
    exit(main())