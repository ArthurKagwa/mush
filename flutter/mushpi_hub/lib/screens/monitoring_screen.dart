import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/farms_provider.dart';
import '../providers/current_farm_provider.dart';
import '../providers/actuator_state_provider.dart';
import '../providers/ble_provider.dart';
import '../core/constants/ble_constants.dart';
import '../core/utils/ble_serializer.dart';
import '../data/models/farm.dart';

/// Monitoring screen showing real-time environmental data and system status.
///
/// Displays:
/// - Real-time environmental metrics across all farms
/// - System alerts and notifications
/// - Compliance indicators
/// - Quick action buttons
/// - Environmental trend charts
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    // Start auto-refresh when screen is shown
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        ref.invalidate(selectedMonitoringFarmLatestReadingProvider);
        _startAutoRefresh();
      }
    });
  }

  void _stopAutoRefresh() {
    // The mounted check in _startAutoRefresh will prevent further refreshes
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(activeFarmsProvider);
    final selectedFarmId = ref.watch(selectedMonitoringFarmIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring'),
        actions: [
          // Connection status indicator - shows selected farm's status
          farmsAsync.when(
            data: (farms) {
              if (selectedFarmId == null || farms.isEmpty) {
                return const SizedBox.shrink();
              }

              final selectedFarm =
                  farms.where((f) => f.id == selectedFarmId).firstOrNull;
              if (selectedFarm == null) {
                return const SizedBox.shrink();
              }

              // Single source of truth: farm is online if lastActive < 1 minute
              final isOnline = selectedFarm.lastActive != null &&
                  DateTime.now()
                          .difference(selectedFarm.lastActive!)
                          .inMinutes <
                      1;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      // Show connection help dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                isOnline ? Icons.check_circle : Icons.cancel,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(isOnline ? 'Farm Online' : 'Farm Offline'),
                            ],
                          ),
                          content: Text(
                            isOnline
                                ? '${selectedFarm.name} is online and actively reporting data.'
                                : '${selectedFarm.name} is offline.\n\nTo reconnect:\n1. Go to Farms tab\n2. Tap the farm card\n3. Tap "Connect" button\n\nNote: Farm shows "Online" if it was active within the last 1 minute.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                            if (!isOnline)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Navigate to Farms tab with mounted check
                                  // to avoid navigation stack errors
                                  if (context.mounted) {
                                    context.go('/farms');
                                  }
                                },
                                child: const Text('Go to Farms'),
                              ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(activeFarmsProvider.future),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: farmsAsync.when(
        data: (farms) {
          if (farms.isEmpty) {
            return _EmptyMonitoringView(
              onAddFarm: () => context.push('/farms/scan'),
            );
          }

          // If multiple farms and no farm selected, show farm selector
          if (farms.length > 1 && selectedFarmId == null) {
            return _FarmSelectorView(
              farms: farms,
              onSelectFarm: (farmId) {
                ref.read(selectedMonitoringFarmIdProvider.notifier).state =
                    farmId;
              },
            );
          }

          // If single farm and no selection, auto-select it
          if (farms.length == 1 && selectedFarmId == null) {
            // Auto-select the only farm
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedMonitoringFarmIdProvider.notifier).state =
                  farms.first.id;
            });
          }

          // Find the selected farm
          final selectedFarm = selectedFarmId != null
              ? farms.firstWhere(
                  (f) => f.id == selectedFarmId,
                  orElse: () => farms.first,
                )
              : farms.first;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(activeFarmsProvider.future),
            child: CustomScrollView(
              slivers: [
                // Farm selector dropdown (if multiple farms)
                if (farms.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _FarmDropdownSelector(
                        farms: farms,
                        selectedFarmId: selectedFarmId,
                        onChanged: (farmId) {
                          ref
                              .read(selectedMonitoringFarmIdProvider.notifier)
                              .state = farmId;
                        },
                      ),
                    ),
                  ),

                // System status for selected farm
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _FarmStatusCard(farm: selectedFarm),
                  ),
                ),

                // Reconnect banner if farm is offline
                if (selectedFarm.lastActive == null ||
                    DateTime.now()
                            .difference(selectedFarm.lastActive!)
                            .inMinutes >=
                        30)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Not Connected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your MushPi is offline. Showing last known data. Real-time updates paused.',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/farms/scan'),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reconnect Device'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Environmental overview for selected farm
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _EnvironmentalOverviewCard(farm: selectedFarm),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Stage Progress card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _StageProgressCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Actuator state/modes
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _ActuatorStateCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Farm details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Farm Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Farm info card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _FarmInfoCard(
                      farm: selectedFarm,
                      onViewDetails: () =>
                          context.push('/farm/${selectedFarm.id}'),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Bottom padding
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading monitoring data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(activeFarmsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Farm selector view shown when no farm is selected
class _FarmSelectorView extends StatelessWidget {
  const _FarmSelectorView({
    required this.farms,
    required this.onSelectFarm,
  });

  final List<Farm> farms;
  final ValueChanged<String> onSelectFarm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Farm to Monitor',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose which farm you want to monitor',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...farms.map((farm) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onSelectFarm(farm.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (farm.location != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    farm.location!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Farm dropdown selector
class _FarmDropdownSelector extends StatelessWidget {
  const _FarmDropdownSelector({
    required this.farms,
    required this.selectedFarmId,
    required this.onChanged,
  });

  final List<Farm> farms;
  final String? selectedFarmId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.agriculture,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: selectedFarmId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select a farm'),
                items: farms.map((farm) {
                  return DropdownMenuItem<String>(
                    value: farm.id,
                    child: Text(farm.name),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Farm status card for single farm
class _FarmStatusCard extends StatelessWidget {
  const _FarmStatusCard({required this.farm});

  final Farm farm;

  bool get isOnline {
    if (farm.lastActive == null) return false;
    return DateTime.now().difference(farm.lastActive!).inMinutes < 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    icon: Icons.eco,
                    label: 'Total Harvests',
                    value: farm.totalHarvests.toString(),
                    color: colorScheme.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.scale,
                    label: 'Total Yield',
                    value: '${farm.totalYieldKg.toStringAsFixed(1)} kg',
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Farm info card with view details button
class _FarmInfoCard extends StatelessWidget {
  const _FarmInfoCard({
    required this.farm,
    required this.onViewDetails,
  });

  final Farm farm;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farm.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (farm.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    farm.location!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
            if (farm.notes != null && farm.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                farm.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility),
                label: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no farms exist
class _EmptyMonitoringView extends StatelessWidget {
  const _EmptyMonitoringView({required this.onAddFarm});

  final VoidCallback onAddFarm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Monitoring',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first farm to start monitoring environmental conditions.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddFarm,
              icon: const Icon(Icons.add),
              label: const Text('Add Farm'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Environmental overview card for single farm
class _EnvironmentalOverviewCard extends ConsumerWidget {
  const _EnvironmentalOverviewCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the latest reading for the selected farm
    final readingAsync = ref.watch(selectedMonitoringFarmLatestReadingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Environmental Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                readingAsync.when(
                  data: (reading) => reading != null
                      ? _TimestampChip(timestamp: reading.timestamp)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            readingAsync.when(
              data: (reading) {
                if (reading == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No sensor data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _EnvironmentalMetric(
                            icon: Icons.thermostat,
                            label: 'Temperature',
                            value:
                                '${reading.temperatureC.toStringAsFixed(1)}°C',
                            color: _getTemperatureColor(reading.temperatureC),
                          ),
                        ),
                        Expanded(
                          child: _EnvironmentalMetric(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value:
                                '${reading.relativeHumidity.toStringAsFixed(0)}%',
                            color: _getHumidityColor(reading.relativeHumidity),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EnvironmentalMetric(
                            icon: Icons.air,
                            label: 'CO₂',
                            value: '${reading.co2Ppm} ppm',
                            color: _getCO2Color(reading.co2Ppm),
                          ),
                        ),
                        Expanded(
                          child: _EnvironmentalMetric(
                            icon: Icons.light_mode,
                            label: 'Light',
                            value: reading.lightRaw.toString(),
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading sensor data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp > 28) return Colors.red;
    return Colors.orange;
  }

  Color _getHumidityColor(double rh) {
    if (rh < 60) return Colors.orange;
    if (rh > 95) return Colors.red;
    return Colors.blue;
  }

  Color _getCO2Color(int co2) {
    if (co2 > 2000) return Colors.red;
    if (co2 > 1000) return Colors.orange;
    return Colors.green;
  }
}

/// Timestamp chip showing when data was last updated
class _TimestampChip extends StatelessWidget {
  const _TimestampChip({required this.timestamp});

  final DateTime timestamp;

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecent = DateTime.now().difference(timestamp).inMinutes < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRecent
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: isRecent ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            _getTimeAgo(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isRecent ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Individual status item
class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Environmental metric display
class _EnvironmentalMetric extends StatelessWidget {
  const _EnvironmentalMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Actuator modes/state card
class _ActuatorStateCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(controlTargetsFutureProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_remote),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Actuators',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload',
                  onPressed: () => ref.refresh(controlTargetsFutureProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            targetsAsync.when(
              data: (targets) {
                if (targets == null) {
                  return _ActuatorUnavailable();
                }

                final theme = Theme.of(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ActuatorChip(
                          icon: Icons.lightbulb,
                          label: 'Light',
                          value: targets.lightMode.displayName,
                          color: Colors.amber,
                          subtitle: targets.lightMode == LightMode.cycle
                              ? 'On ${targets.onMinutes}m / Off ${targets.offMinutes}m'
                              : null,
                        ),
                        _ActuatorChip(
                          icon: Icons.air,
                          label: 'Fan',
                          value: 'Auto',
                          color: theme.colorScheme.primary,
                          subtitle: 'State not reported',
                        ),
                        _ActuatorChip(
                          icon: Icons.grain,
                          label: 'Mist',
                          value: 'Auto',
                          color: theme.colorScheme.tertiary,
                          subtitle: 'State not reported',
                        ),
                        _ActuatorChip(
                          icon: Icons.local_fire_department,
                          label: 'Heater',
                          value: 'Auto',
                          color: Colors.redAccent,
                          subtitle: 'State not reported',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note: Real-time relay ON/OFF states are not yet exposed by the device; showing configured modes where available.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const _ActuatorUnavailable(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActuatorChip extends StatelessWidget {
  const _ActuatorChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActuatorUnavailable extends StatelessWidget {
  const _ActuatorUnavailable();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Actuator modes unavailable. Connect to the device and tap reload.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stage Progress card showing cultivation stage and progression
class _StageProgressCard extends ConsumerStatefulWidget {
  const _StageProgressCard();

  @override
  ConsumerState<_StageProgressCard> createState() => _StageProgressCardState();
}

class _StageProgressCardState extends ConsumerState<_StageProgressCard> {
  StageStateData? _stageData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStageData();
  }

  Future<void> _loadStageData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bleOps = ref.read(bleOperationsProvider);
      final data = await bleOps.readStageState();

      if (!mounted) return;

      if (data != null) {
        developer.log(
          '🎯 MONITORING DISPLAY: Received mode=${data.mode.name} (id=${data.mode.id}, displayName="${data.mode.displayName}")',
          name: 'MonitoringScreen._StageProgressCard',
        );
      }

      setState(() {
        _stageData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load stage data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Stage Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadStageData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContent(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
          ],
        ),
      );
    }

    if (_stageData == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No stage data available. Configure stages to begin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate progress
    final daysElapsed = _stageData!.daysInStage;
    final expectedDays = _stageData!.expectedDays;
    final progressPercent = expectedDays > 0
        ? (daysElapsed / expectedDays * 100).clamp(0, 100)
        : 0.0;
    final daysRemaining = (expectedDays - daysElapsed).clamp(0, expectedDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Stage Info
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_stageData!.species.displayName} - ${_stageData!.stage.displayName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stageData!.mode.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: progressPercent >= 100
                    ? cs.tertiaryContainer
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                progressPercent >= 100 ? 'COMPLETE' : 'IN PROGRESS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressPercent >= 100
                          ? cs.onTertiaryContainer
                          : cs.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Progress Bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day $daysElapsed of $expectedDays',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${progressPercent.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 12,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercent >= 100 ? cs.tertiary : cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Additional Info
        Row(
          children: [
            Expanded(
              child: _StageMetric(
                icon: Icons.calendar_today,
                label: 'Started',
                value: _formatDate(_stageData!.stageStartTime),
                color: cs.primary,
              ),
            ),
            Expanded(
              child: _StageMetric(
                icon: progressPercent >= 100
                    ? Icons.check_circle
                    : Icons.access_time,
                label: progressPercent >= 100 ? 'Complete' : 'Days Remaining',
                value: progressPercent >= 100
                    ? 'Ready to advance'
                    : '$daysRemaining days',
                color: progressPercent >= 100 ? cs.tertiary : cs.secondary,
              ),
            ),
          ],
        ),

        // Next stage hint (only if not complete and not in MANUAL mode)
        if (progressPercent < 100 && _stageData!.mode != ControlMode.manual)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stageData!.mode == ControlMode.full
                          ? 'Will auto-advance to next stage when complete'
                          : 'Manual advancement required when complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Stage metric display widget
class _StageMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StageMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
