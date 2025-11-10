import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../core/constants/ble_constants.dart';
import '../core/utils/ble_serializer.dart';
import '../providers/current_farm_provider.dart';
import '../providers/farms_provider.dart';
import '../providers/ble_provider.dart';

/// Control screen for managing environmental control parameters.
///
/// Allows users to adjust:
/// - Temperature range (min/max)
/// - Humidity minimum
/// - CO₂ maximum
/// - Light mode and timing
/// - Manual relay overrides
///
/// Uses batch send: changes are applied when "Apply Changes" button is pressed.
class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  // Form state
  double _tempMin = 20.0;
  double _tempMax = 26.0;
  double _rhMin = 60.0;
  int _co2Max = 1000;
  LightMode _lightMode = LightMode.off;
  int _onMinutes = 960; // 16 hours
  int _offMinutes = 480; // 8 hours
  
  // Override bits
  bool _lightOverride = false;
  bool _fanOverride = false;
  bool _mistOverride = false;
  bool _heaterOverride = false;
  bool _disableAuto = false;

  // UI state
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Load current settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  /// Load current control settings from BLE device
  Future<void> _loadCurrentSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bleOps = ref.read(bleOperationsProvider);
      final controlTargets = await bleOps.readControlTargets();

      if (controlTargets != null) {
        setState(() {
          _tempMin = controlTargets.tempMin;
          _tempMax = controlTargets.tempMax;
          _rhMin = controlTargets.rhMin;
          _co2Max = controlTargets.co2Max;
          _lightMode = controlTargets.lightMode;
          _onMinutes = controlTargets.onMinutes;
          _offMinutes = controlTargets.offMinutes;
          _hasChanges = false;
        });

        developer.log(
          '✅ Loaded control settings: ${controlTargets.toString()}',
          name: 'mushpi.control_screen',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: $e';
      });
      developer.log(
        '❌ Failed to load control settings: $e',
        name: 'mushpi.control_screen',
        error: e,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Apply changes to BLE device
  Future<void> _applyChanges() async {
    // Validate
    if (_tempMin >= _tempMax) {
      setState(() {
        _errorMessage = 'Temperature min must be less than max';
      });
      return;
    }

    if (_lightMode == LightMode.cycle && (_onMinutes <= 0 || _offMinutes <= 0)) {
      setState(() {
        _errorMessage = 'Light cycle times must be greater than 0';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final bleOps = ref.read(bleOperationsProvider);

      // Write control targets
      final controlTargets = ControlTargetsData(
        tempMin: _tempMin,
        tempMax: _tempMax,
        rhMin: _rhMin,
        co2Max: _co2Max,
        lightMode: _lightMode,
        onMinutes: _onMinutes,
        offMinutes: _offMinutes,
      );

      await bleOps.writeControlTargets(controlTargets);

      developer.log(
        '✅ Applied control settings: ${controlTargets.toString()}',
        name: 'mushpi.control_screen',
      );

      // Write override bits if any are set
      if (_lightOverride || _fanOverride || _mistOverride || _heaterOverride || _disableAuto) {
        int overrideBits = 0;
        if (_lightOverride) overrideBits |= 0x01;
        if (_fanOverride) overrideBits |= 0x02;
        if (_mistOverride) overrideBits |= 0x04;
        if (_heaterOverride) overrideBits |= 0x08;
        if (_disableAuto) overrideBits |= 0x80;

        await bleOps.writeOverrideBits(overrideBits);

        developer.log(
          '✅ Applied override bits: 0x${overrideBits.toRadixString(16)}',
          name: 'mushpi.control_screen',
        );
      }

      setState(() {
        _hasChanges = false;
        _successMessage = 'Settings applied successfully';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to apply settings: $e';
      });
      developer.log(
        '❌ Failed to apply control settings: $e',
        name: 'mushpi.control_screen',
        error: e,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mark that changes have been made
  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFarmId = ref.watch(selectedMonitoringFarmIdProvider);
    final isConnected = ref.watch(bleRepositoryProvider).isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentSettings,
            tooltip: 'Reload Settings',
          ),
        ],
      ),
      body: selectedFarmId == null
          ? _buildFarmSelector(context)
          : _buildControlPanel(context, isConnected),
    );
  }

  /// Build farm selector if no farm selected
  Widget _buildFarmSelector(BuildContext context) {
    final farmsAsync = ref.watch(activeFarmsProvider);

    return farmsAsync.when(
      data: (farms) {
        if (farms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.agriculture_outlined,
                  size: 120,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Farms Available',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add a farm to access control settings',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        if (farms.length == 1) {
          // Auto-select single farm
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedMonitoringFarmIdProvider.notifier).state = farms.first.id;
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Show farm selector
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: farms.length,
          itemBuilder: (context, index) {
            final farm = farms[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.agriculture),
                title: Text(farm.name),
                subtitle: farm.location != null ? Text(farm.location!) : null,
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  ref.read(selectedMonitoringFarmIdProvider.notifier).state = farm.id;
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading farms: $error'),
      ),
    );
  }

  /// Build control panel
  Widget _buildControlPanel(BuildContext context, bool isConnected) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 88), // Space for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              if (!isConnected)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Not connected to device. Connect to a farm to adjust settings.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Success/Error messages
              if (_successMessage != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Temperature Control
              _buildSection(
                context,
                title: 'Temperature Range',
                icon: Icons.thermostat,
                child: Column(
                  children: [
                    _buildSlider(
                      label: 'Minimum',
                      value: _tempMin,
                      min: -20,
                      max: 60,
                      divisions: 160,
                      unit: '°C',
                      onChanged: (value) {
                        setState(() {
                          _tempMin = value;
                          _markChanged();
                        });
                      },
                    ),
                    _buildSlider(
                      label: 'Maximum',
                      value: _tempMax,
                      min: -20,
                      max: 60,
                      divisions: 160,
                      unit: '°C',
                      onChanged: (value) {
                        setState(() {
                          _tempMax = value;
                          _markChanged();
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Humidity Control
              _buildSection(
                context,
                title: 'Humidity',
                icon: Icons.water_drop,
                child: _buildSlider(
                  label: 'Minimum',
                  value: _rhMin,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  unit: '%',
                  onChanged: (value) {
                    setState(() {
                      _rhMin = value;
                      _markChanged();
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // CO₂ Control
              _buildSection(
                context,
                title: 'CO₂ Level',
                icon: Icons.air,
                child: _buildSlider(
                  label: 'Maximum',
                  value: _co2Max.toDouble(),
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  unit: 'ppm',
                  onChanged: (value) {
                    setState(() {
                      _co2Max = value.round();
                      _markChanged();
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Light Control
              _buildSection(
                context,
                title: 'Light Control',
                icon: Icons.lightbulb,
                child: Column(
                  children: [
                    SegmentedButton<LightMode>(
                      segments: const [
                        ButtonSegment(
                          value: LightMode.off,
                          label: Text('Off'),
                          icon: Icon(Icons.lightbulb_outline),
                        ),
                        ButtonSegment(
                          value: LightMode.on,
                          label: Text('On'),
                          icon: Icon(Icons.lightbulb),
                        ),
                        ButtonSegment(
                          value: LightMode.cycle,
                          label: Text('Cycle'),
                          icon: Icon(Icons.schedule),
                        ),
                      ],
                      selected: {_lightMode},
                      onSelectionChanged: (Set<LightMode> selection) {
                        setState(() {
                          _lightMode = selection.first;
                          _markChanged();
                        });
                      },
                    ),
                    if (_lightMode == LightMode.cycle) ...[
                      const SizedBox(height: 16),
                      _buildTimeControl(
                        label: 'On Duration',
                        minutes: _onMinutes,
                        onChanged: (value) {
                          setState(() {
                            _onMinutes = value;
                            _markChanged();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildTimeControl(
                        label: 'Off Duration',
                        minutes: _offMinutes,
                        onChanged: (value) {
                          setState(() {
                            _offMinutes = value;
                            _markChanged();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Manual Overrides
              _buildSection(
                context,
                title: 'Manual Overrides',
                icon: Icons.settings_remote,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Light Override'),
                      subtitle: const Text('Force light on/off'),
                      value: _lightOverride,
                      onChanged: (value) {
                        setState(() {
                          _lightOverride = value;
                          _markChanged();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Fan Override'),
                      subtitle: const Text('Force fan on/off'),
                      value: _fanOverride,
                      onChanged: (value) {
                        setState(() {
                          _fanOverride = value;
                          _markChanged();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mist Override'),
                      subtitle: const Text('Force mist on/off'),
                      value: _mistOverride,
                      onChanged: (value) {
                        setState(() {
                          _mistOverride = value;
                          _markChanged();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Heater Override'),
                      subtitle: const Text('Force heater on/off'),
                      value: _heaterOverride,
                      onChanged: (value) {
                        setState(() {
                          _heaterOverride = value;
                          _markChanged();
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Disable Automation'),
                      subtitle: const Text('Turn off all automatic control'),
                      value: _disableAuto,
                      onChanged: (value) {
                        setState(() {
                          _disableAuto = value;
                          _markChanged();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Apply Changes FAB
        if (_hasChanges && isConnected)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _applyChanges,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Applying...' : 'Apply Changes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
      ],
    );
  }

  /// Build section card
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  /// Build slider with label and value
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.toStringAsFixed(1)} $unit',
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Build time control (hours and minutes)
  Widget _buildTimeControl({
    required String label,
    required int minutes,
    required ValueChanged<int> onChanged,
  }) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 100,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Hours',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: hours.toString()),
            onChanged: (value) {
              final h = int.tryParse(value) ?? 0;
              onChanged(h * 60 + mins);
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Minutes',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: mins.toString()),
            onChanged: (value) {
              final m = int.tryParse(value) ?? 0;
              onChanged(hours * 60 + m);
            },
          ),
        ),
      ],
    );
  }
}
