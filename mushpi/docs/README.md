# MushPi Documentation

Comprehensive documentation for the MushPi mushroom growing controller.

## Directory Structure

```
docs/
├── troubleshooting/  # Troubleshooting guides and fix procedures
├── guides/           # How-to guides and tutorials
└── reference/        # Reference documentation and technical specs
```

## Troubleshooting Documentation (`troubleshooting/`)

### `BLUETOOTH_TROUBLESHOOTING.md`
Complete Bluetooth and BLE troubleshooting guide
- Bluetooth service issues
- Adapter configuration
- BLE advertising problems
- Connection failures
- Bonding/pairing conflicts

### `FIX_SUMMARY.md`
Summary of major fixes and their solutions
- Critical bug fixes
- Known issues and workarounds
- Patch history

### `FLUTTER_BLE_DEBUG.md`
Flutter app BLE debugging guide
- Connection debugging
- Service discovery issues
- Characteristic read/write problems
- Notification setup

### `LED_TEST_GUIDE.md`
LED and light control testing procedures
- GPIO relay testing
- Light sensor verification
- Schedule testing

## Guides (`guides/`)

### `ESP32_README.md`
ESP32 sensor integration guide
- Arduino code setup
- Serial communication protocol
- Sensor wiring diagrams

### `PIN_REVIEW.md`
Complete GPIO pin reference
- Pin assignments (BCM numbering)
- Sensor connections
- Relay wiring
- I2C bus configuration

### `pin_map.md`
Quick pin mapping reference
- Physical pin to BCM GPIO mapping
- Component connection table
- Wiring diagrams

## Reference Documentation (`reference/`)

### `PLAN.md`
Project roadmap and development plan
- Feature milestones
- Architecture decisions
- Backend migration plan
- BLE protocol evolution

### `PATCH_NOTES.md`
Detailed changelog of all patches
- Version history
- Feature additions
- Bug fixes
- Breaking changes

### `QUICK_REFERENCE.md`
Quick reference for common tasks
- Command cheat sheet
- Configuration reference
- API endpoints
- BLE characteristics

### `bluezero.md`
BlueZero library documentation
- API usage examples
- Migration notes
- Known limitations

### `CMakeLists.txt`
CMake configuration (if building native extensions)

### `t.txt`
Development notes and temporary documentation

## Main Documentation (Root Level)

Located in parent directory:

### `README.md`
Main project documentation
- Quick start guide
- Installation instructions
- Configuration
- Hardware requirements

### `SYSTEMCTL_README.md`
Complete systemd service management guide
- Service installation
- systemctl commands
- Log management
- Troubleshooting

## Documentation By Topic

### Getting Started
1. `../README.md` - Start here
2. `guides/PIN_REVIEW.md` - Hardware setup
3. `../SYSTEMCTL_README.md` - Service installation

### BLE Development
1. `reference/bluezero.md` - BlueZero API
2. `reference/QUICK_REFERENCE.md` - BLE characteristics
3. `FLUTTER_BLE_DEBUG.md` - Flutter app debugging

### Troubleshooting
1. `troubleshooting/BLUETOOTH_TROUBLESHOOTING.md` - BLE issues
2. `troubleshooting/FIX_SUMMARY.md` - Known fixes
3. `../SYSTEMCTL_README.md` - Service issues

### Hardware
1. `guides/PIN_REVIEW.md` - Complete pin reference
2. `guides/pin_map.md` - Quick pin mapping
3. `guides/ESP32_README.md` - ESP32 integration

### Development
1. `reference/PLAN.md` - Development roadmap
2. `reference/PATCH_NOTES.md` - Change history
3. `reference/QUICK_REFERENCE.md` - API reference

## Documentation Standards

### File Naming
- Troubleshooting: `<TOPIC>_TROUBLESHOOTING.md`
- Guides: `<TOPIC>_GUIDE.md` or `<COMPONENT>_README.md`
- Reference: `<TOPIC>.md` (lowercase) or `<TOPIC>_REFERENCE.md`

### Document Structure
```markdown
# Title

Brief description

## Table of Contents
- Links to major sections

## Section 1
Content with examples

## Section 2
Content with code blocks

## Resources
Links to related docs
```

### Code Examples
Use proper syntax highlighting:
```bash
# Bash commands
sudo systemctl restart mushpi
```

```python
# Python code
from app.core.config import load_config
config = load_config()
```

### Cross-References
Link to related documentation:
```markdown
See [SYSTEMCTL_README.md](../../SYSTEMCTL_README.md) for service management.
See [../tests/README.md](../tests/README.md) for testing guide.
```

## Contributing to Documentation

### Before Adding New Docs
1. Check if topic already covered
2. Determine appropriate category:
   - Troubleshooting: Problem-solution format
   - Guides: Step-by-step tutorials
   - Reference: Technical specifications

### Documentation Checklist
- [ ] Clear title and description
- [ ] Table of contents (if >3 sections)
- [ ] Code examples with syntax highlighting
- [ ] Cross-references to related docs
- [ ] Links to external resources
- [ ] Screenshots/diagrams (if helpful)
- [ ] Last updated date

### Updating Existing Docs
1. Keep "latest first" order for changelogs
2. Mark outdated information clearly
3. Update cross-references
4. Update BASELINE.md if major changes

## Documentation Tools

### Markdown Preview
```bash
# VS Code
Ctrl/Cmd + Shift + V

# Command line (requires grip)
grip README.md
```

### Generate PDF
```bash
# Using pandoc
pandoc TROUBLESHOOTING.md -o troubleshooting.pdf

# Using markdown-pdf
markdown-pdf troubleshooting/BLUETOOTH_TROUBLESHOOTING.md
```

### Search Documentation
```bash
# Search all docs
grep -r "keyword" docs/

# Search specific type
grep -r "BLE" docs/troubleshooting/

# Case-insensitive
grep -ri "bluetooth" docs/
```

## Documentation Maintenance

### Regular Updates
- Update PATCH_NOTES.md with each change
- Keep QUICK_REFERENCE.md current
- Review troubleshooting docs quarterly
- Archive outdated documents

### Version Management
- Major changes: Update version in docs
- Breaking changes: Add migration guide
- Deprecations: Mark clearly and provide timeline

## Resources

### External Documentation
- [systemd documentation](https://www.freedesktop.org/wiki/Software/systemd/)
- [BlueZ documentation](http://www.bluez.org/documentation/)
- [Raspberry Pi GPIO](https://www.raspberrypi.com/documentation/computers/gpio.html)
- [Python documentation](https://docs.python.org/3/)

### Project Links
- Main README: `../README.md`
- Service management: `../SYSTEMCTL_README.md`
- Test documentation: `../tests/README.md`
- Script documentation: `../scripts/README.md`
