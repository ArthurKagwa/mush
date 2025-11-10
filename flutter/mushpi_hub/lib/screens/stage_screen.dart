import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../core/constants/ble_constants.dart';
import '../core/utils/ble_serializer.dart';
import '../providers/current_farm_provider.dart';
import '../providers/farms_provider.dart';
import '../providers/ble_provider.dart';

/// Stage screen for managing growth stage state.
///
/// Allows users to:
/// - View current stage information
/// - Change automation mode (FULL/SEMI/MANUAL)
/// - Select species
/// - Advance to next stage
/// - Set expected stage duration
///
/// Uses batch send: changes are applied when "Update Stage" button is pressed.
class StageScreen extends ConsumerStatefulWidget {
  const StageScreen({super.key});

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen> {
  // Form state
  ControlMode _mode = ControlMode.semi;
  Species _species = Species.oyster;
  GrowthStage _stage = GrowthStage.incubation;
  int _expectedDays = 14;

  // UI state
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _errorMessage;
  String? _successMessage;
  DateTime? _stageStartTime;
  int? _daysInCurrentStage;

  @override
  void initState() {
    super.initState();
    // Load current stage state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStageState();
    });
  }

  /// Load current stage state from BLE device
  Future<void> _loadCurrentStageState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bleOps = ref.read(bleOperationsProvider);
      final stageState = await bleOps.readStageState();

      if (stageState != null) {
        setState(() {
          _mode = stageState.mode;
          _species = stageState.species;
          _stage = stageState.stage;
          _expectedDays = stageState.expectedDays;
          _stageStartTime = stageState.stageStartTime;
          _daysInCurrentStage = stageState.daysInStage;
          _hasChanges = false;
        });

        developer.log(
          '✅ Loaded stage state: ${stageState.toString()}',
          name: 'mushpi.stage_screen',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load stage state: $e';
      });
      developer.log(
        '❌ Failed to load stage state: $e',
        name: 'mushpi.stage_screen',
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
    if (_expectedDays <= 0) {
      setState(() {
        _errorMessage = 'Expected days must be greater than 0';
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

      // Create stage state data
      final stageState = StageStateData(
        mode: _mode,
        species: _species,
        stage: _stage,
        stageStartTime: DateTime.now(), // Reset start time when updating
        expectedDays: _expectedDays,
      );

      await bleOps.writeStageState(stageState);

      developer.log(
        '✅ Applied stage state: ${stageState.toString()}',
        name: 'mushpi.stage_screen',
      );

      setState(() {
        _hasChanges = false;
        _successMessage = 'Stage updated successfully';
        _stageStartTime = DateTime.now();
        _daysInCurrentStage = 0;
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
        _errorMessage = 'Failed to update stage: $e';
      });
      developer.log(
        '❌ Failed to update stage: $e',
        name: 'mushpi.stage_screen',
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
        title: const Text('Growth Stage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCurrentStageState,
            tooltip: 'Reload Stage State',
          ),
        ],
      ),
      body: selectedFarmId == null
          ? _buildFarmSelector(context)
          : _buildStagePanel(context, isConnected),
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
                  'Add a farm to manage growth stages',
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

  /// Build stage panel
  Widget _buildStagePanel(BuildContext context, bool isConnected) {
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
                            'Not connected to device. Connect to a farm to manage stages.',
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

              // Current Stage Info
              if (_stageStartTime != null && _daysInCurrentStage != null)
                _buildSection(
                  context,
                  title: 'Current Stage Progress',
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Days in Stage', '$_daysInCurrentStage / $_expectedDays days'),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Stage Started',
                        _formatDate(_stageStartTime!),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _expectedDays > 0
                            ? (_daysInCurrentStage! / _expectedDays).clamp(0.0, 1.0)
                            : 0.0,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Automation Mode
              _buildSection(
                context,
                title: 'Automation Mode',
                icon: Icons.auto_mode,
                child: Column(
                  children: [
                    RadioListTile<ControlMode>(
                      title: const Text('Full Auto'),
                      subtitle: const Text('Automatic control + automatic stage advancement'),
                      value: ControlMode.full,
                      groupValue: _mode,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _mode = value;
                            _markChanged();
                          });
                        }
                      },
                    ),
                    RadioListTile<ControlMode>(
                      title: const Text('Semi Auto'),
                      subtitle: const Text('Automatic control + manual stage confirmation'),
                      value: ControlMode.semi,
                      groupValue: _mode,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _mode = value;
                            _markChanged();
                          });
                        }
                      },
                    ),
                    RadioListTile<ControlMode>(
                      title: const Text('Manual'),
                      subtitle: const Text('Full manual control for experimental grows'),
                      value: ControlMode.manual,
                      groupValue: _mode,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _mode = value;
                            _markChanged();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Species Selection
              _buildSection(
                context,
                title: 'Species',
                icon: Icons.eco,
                child: SegmentedButton<Species>(
                  segments: const [
                    ButtonSegment(
                      value: Species.oyster,
                      label: Text('Oyster'),
                      icon: Icon(Icons.eco),
                    ),
                    ButtonSegment(
                      value: Species.shiitake,
                      label: Text('Shiitake'),
                      icon: Icon(Icons.eco),
                    ),
                    ButtonSegment(
                      value: Species.lionsMane,
                      label: Text("Lion's Mane"),
                      icon: Icon(Icons.eco),
                    ),
                  ],
                  selected: {_species},
                  onSelectionChanged: (Set<Species> selection) {
                    setState(() {
                      _species = selection.first;
                      _markChanged();
                    });
                  },
                  showSelectedIcon: true,
                ),
              ),

              const SizedBox(height: 16),

              // Growth Stage Selection
              _buildSection(
                context,
                title: 'Growth Stage',
                icon: Icons.timeline,
                child: Column(
                  children: [
                    SegmentedButton<GrowthStage>(
                      segments: const [
                        ButtonSegment(
                          value: GrowthStage.incubation,
                          label: Text('Incubation'),
                          icon: Icon(Icons.pending),
                        ),
                        ButtonSegment(
                          value: GrowthStage.pinning,
                          label: Text('Pinning'),
                          icon: Icon(Icons.brightness_low),
                        ),
                        ButtonSegment(
                          value: GrowthStage.fruiting,
                          label: Text('Fruiting'),
                          icon: Icon(Icons.eco),
                        ),
                      ],
                      selected: {_stage},
                      onSelectionChanged: (Set<GrowthStage> selection) {
                        setState(() {
                          _stage = selection.first;
                          _markChanged();
                          // Update expected days based on stage defaults
                          _expectedDays = _getDefaultExpectedDays(_species, _stage);
                        });
                      },
                      showSelectedIcon: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Expected Duration (days)',
                        border: OutlineInputBorder(),
                        helperText: 'How long should this stage last?',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _expectedDays.toString()),
                      onChanged: (value) {
                        final days = int.tryParse(value);
                        if (days != null && days > 0) {
                          setState(() {
                            _expectedDays = days;
                            _markChanged();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stage Guidelines
              _buildSection(
                context,
                title: 'Stage Guidelines',
                icon: Icons.help_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStageGuidelines(_species, _stage),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Update Stage FAB
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
                  : const Icon(Icons.update),
              label: Text(_isLoading ? 'Updating...' : 'Update Stage'),
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

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Get default expected days for a species and stage
  int _getDefaultExpectedDays(Species species, GrowthStage stage) {
    switch (species) {
      case Species.oyster:
        switch (stage) {
          case GrowthStage.incubation:
            return 14;
          case GrowthStage.pinning:
            return 5;
          case GrowthStage.fruiting:
            return 7;
        }
      case Species.shiitake:
        switch (stage) {
          case GrowthStage.incubation:
            return 21;
          case GrowthStage.pinning:
            return 7;
          case GrowthStage.fruiting:
            return 10;
        }
      case Species.lionsMane:
        switch (stage) {
          case GrowthStage.incubation:
            return 18;
          case GrowthStage.pinning:
            return 6;
          case GrowthStage.fruiting:
            return 8;
        }
      case Species.custom:
        return 14; // Default
    }
  }

  /// Get stage guidelines text
  String _getStageGuidelines(Species species, GrowthStage stage) {
    final speciesName = species.displayName;
    
    switch (stage) {
      case GrowthStage.incubation:
        return '$speciesName - Incubation: Colonization period where mycelium spreads through substrate. '
            'Keep temperature warm, humidity high, light off, and CO₂ elevated.';
      case GrowthStage.pinning:
        return '$speciesName - Pinning: Initiation of mushroom primordia (pins). '
            'Lower temperature, increase humidity, introduce light cycles, and fresh air.';
      case GrowthStage.fruiting:
        return '$speciesName - Fruiting: Active mushroom growth and maturation. '
            'Maintain optimal conditions for mushroom development until harvest.';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
