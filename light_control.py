#!/usr/bin/env python3
"""
MushPi Light Control Script

Checks current light status and controls it according to the proper mushroom cultivation schedule.
Handles different stages (Incubation, Pinning, Fruiting) with appropriate light cycles.
"""

import sys
import os
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

# Add the app directory to path for imports
app_dir = Path(__file__).parent / 'mushpi' / 'app'
sys.path.insert(0, str(app_dir))

from core.stage import stage_manager, StageMode
from core.control import LightSchedule, RelayState

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class LightController:
    """Controls grow light according to mushroom cultivation schedule"""
    
    def __init__(self):
        self.stage_manager = stage_manager
        self.simulation_mode = True  # Default to simulation mode
        
        # Try to determine if we're on actual Pi hardware
        try:
            import RPi.GPIO as GPIO
            self.simulation_mode = False
            self.gpio_available = True
            logger.info("GPIO available - real hardware mode")
        except ImportError:
            self.gpio_available = False
            logger.info("GPIO not available - simulation mode")
            
        # Light relay pin (from config)
        self.light_pin = 22  # Default from GPIO config
        
        if not self.simulation_mode:
            self._init_gpio()
            
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
            
    def get_current_stage_info(self):
        """Get current mushroom stage information"""
        return self.stage_manager.get_status()
        
    def calculate_light_schedule(self):
        """Calculate if light should be on based on current stage and time"""
        stage_info = self.get_current_stage_info()
        
        if not stage_info['configured']:
            logger.error("No stage configuration found")
            return False, "No stage configuration"
            
        light_schedule = stage_info['light_schedule']
        current_time = datetime.now()
        
        mode = light_schedule.get('mode', 'off')
        
        if mode == 'off':
            return False, f"Light mode: OFF ({stage_info['species']} - {stage_info['stage']})"
            
        elif mode == 'on':
            return True, f"Light mode: ON ({stage_info['species']} - {stage_info['stage']})"
            
        elif mode == 'cycle':
            on_minutes = light_schedule.get('on_min', 0)
            off_minutes = light_schedule.get('off_min', 0)
            
            if on_minutes <= 0 or off_minutes <= 0:
                logger.error("Invalid cycle configuration")
                return False, "Invalid cycle configuration"
                
            # Calculate position in daily cycle (starting from midnight)
            minutes_since_midnight = current_time.hour * 60 + current_time.minute
            cycle_duration = on_minutes + off_minutes
            position_in_cycle = minutes_since_midnight % cycle_duration
            
            should_be_on = position_in_cycle < on_minutes
            
            if should_be_on:
                remaining_on = on_minutes - position_in_cycle
                return True, f"Light ON: {remaining_on:.0f}min remaining in cycle ({stage_info['species']} - {stage_info['stage']})"
            else:
                remaining_off = cycle_duration - position_in_cycle
                return False, f"Light OFF: {remaining_off:.0f}min until next cycle ({stage_info['species']} - {stage_info['stage']})"
                
        else:
            logger.error(f"Unknown light mode: {mode}")
            return False, f"Unknown light mode: {mode}"
            
    def get_current_light_state(self):
        """Get current physical light state"""
        if self.simulation_mode:
            # In simulation mode, we can't read actual GPIO state
            # Could check a state file or assume OFF
            return None, "Simulation mode - cannot read GPIO state"
            
        try:
            import RPi.GPIO as GPIO
            state = GPIO.input(self.light_pin)
            return bool(state), f"GPIO pin {self.light_pin} reads {'HIGH' if state else 'LOW'}"
        except Exception as e:
            logger.error(f"Error reading GPIO state: {e}")
            return None, f"Error reading GPIO: {e}"
            
    def set_light_state(self, should_be_on: bool, reason: str):
        """Set the light relay state"""
        if self.simulation_mode:
            action = "Turn ON" if should_be_on else "Turn OFF"
            logger.info(f"SIMULATION: {action} light relay (Pin {self.light_pin}) - {reason}")
            return True, f"Simulated: {action} light - {reason}"
            
        try:
            import RPi.GPIO as GPIO
            GPIO.output(self.light_pin, GPIO.HIGH if should_be_on else GPIO.LOW)
            action = "Turned ON" if should_be_on else "Turned OFF"
            logger.info(f"{action} light relay (Pin {self.light_pin}) - {reason}")
            return True, f"{action} light - {reason}"
        except Exception as e:
            logger.error(f"Error setting GPIO state: {e}")
            return False, f"Error setting light: {e}"
            
    def check_and_control_light(self):
        """Main function: check if light should be on and control it accordingly"""
        logger.info("=== MushPi Light Control Check ===")
        
        # Get stage information
        stage_info = self.get_current_stage_info()
        print(f"Current Stage: {stage_info['species']} - {stage_info['stage']} (Day {stage_info['age_days']}/{stage_info['expected_days']})")
        print(f"Stage Mode: {stage_info['mode']}")
        
        # Calculate if light should be on
        should_be_on, schedule_reason = self.calculate_light_schedule()
        print(f"\\nSchedule Analysis: {schedule_reason}")
        print(f"Light SHOULD BE: {'ON' if should_be_on else 'OFF'}")
        
        # Check current light state
        current_state, state_reason = self.get_current_light_state()
        if current_state is not None:
            print(f"Light IS CURRENTLY: {'ON' if current_state else 'OFF'} ({state_reason})")
            
            # Determine if action is needed
            if current_state == should_be_on:
                print(f"\\n✅ Light is correctly {'ON' if should_be_on else 'OFF'} - No action needed")
                return True
            else:
                print(f"\\n⚠️  Light state mismatch! Should be {'ON' if should_be_on else 'OFF'} but is {'ON' if current_state else 'OFF'}")
        else:
            print(f"Light CURRENT STATE: Unknown ({state_reason})")
            print(f"\\n🔧 Will set light to correct state")
            
        # Set correct light state
        success, action_result = self.set_light_state(should_be_on, schedule_reason)
        
        if success:
            print(f"\\n✅ {action_result}")
            return True
        else:
            print(f"\\n❌ {action_result}")
            return False
            
    def get_light_status_report(self):
        """Generate a detailed light status report"""
        report = []
        report.append("=== MushPi Light Status Report ===")
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # Stage information
        stage_info = self.get_current_stage_info()
        report.append(f"Species: {stage_info['species']}")
        report.append(f"Stage: {stage_info['stage']}")
        report.append(f"Age: {stage_info['age_days']} days (Expected: {stage_info['expected_days']} days)")
        report.append(f"Progress: {stage_info['progress_percent']:.1f}%")
        report.append("")
        
        # Light schedule
        light_schedule = stage_info['light_schedule']
        mode = light_schedule.get('mode', 'off')
        report.append(f"Light Mode: {mode.upper()}")
        
        if mode == 'cycle':
            on_hours = light_schedule.get('on_min', 0) / 60
            off_hours = light_schedule.get('off_min', 0) / 60
            report.append(f"Cycle: {on_hours:.1f}h ON, {off_hours:.1f}h OFF")
            
        # Current status
        should_be_on, reason = self.calculate_light_schedule()
        report.append(f"Should be: {'ON' if should_be_on else 'OFF'}")
        report.append(f"Reason: {reason}")
        
        current_state, state_reason = self.get_current_light_state()
        if current_state is not None:
            report.append(f"Currently: {'ON' if current_state else 'OFF'} ({state_reason})")
        else:
            report.append(f"Currently: Unknown ({state_reason})")
            
        report.append("")
        report.append(f"Hardware Mode: {'Simulation' if self.simulation_mode else 'Real GPIO'}")
        
        return "\\n".join(report)
        
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
    
    parser = argparse.ArgumentParser(description='MushPi Light Control')
    parser.add_argument('--status', action='store_true', help='Show detailed status report')
    parser.add_argument('--force-on', action='store_true', help='Force light ON regardless of schedule')
    parser.add_argument('--force-off', action='store_true', help='Force light OFF regardless of schedule')
    parser.add_argument('--stage', help='Set mushroom stage (e.g., "Oyster,Pinning")')
    
    args = parser.parse_args()
    
    controller = LightController()
    
    try:
        if args.stage:
            try:
                species, stage = args.stage.split(',')
                success = controller.stage_manager.set_stage(species.strip(), stage.strip())
                if success:
                    print(f"✅ Stage set to: {species} - {stage}")
                else:
                    print(f"❌ Failed to set stage: {species} - {stage}")
                    return 1
            except ValueError:
                print("❌ Stage format should be: Species,Stage (e.g., 'Oyster,Pinning')")
                return 1
                
        if args.status:
            print(controller.get_light_status_report())
            
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