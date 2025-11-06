import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/farms_provider.dart';
import '../providers/current_farm_provider.dart';
import '../widgets/farm_card.dart';
import '../widgets/theme_selector.dart';
import '../data/models/farm.dart';

/// Home screen showing overview of all farms.
///
/// Displays:
/// - List of all farms as cards
/// - Total production statistics
/// - Quick actions (add farm, settings)
/// - Performance indicators
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(activeFarmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        actions: [
          // Theme toggle
          const ThemeToggleButton(),
        ],
      ),
      body: farmsAsync.when(
        data: (farms) {
          if (farms.isEmpty) {
            return _EmptyFarmsView(
              onAddFarm: () => context.push('/farms/scan'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(activeFarmsProvider.future),
            child: CustomScrollView(
              slivers: [
                // Header stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _StatsHeader(
                      farmCount: farms.length,
                      farms: farms,
                    ),
                  ),
                ),

                // Farm cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final farm = farms[index];
                        return FarmCard(
                          farm: farm,
                          onTap: () {
                            // Set the farm for monitoring and navigate to monitoring tab
                            ref.read(selectedMonitoringFarmIdProvider.notifier).state = farm.id;
                            context.go('/monitoring');
                          },
                        );
                      },
                      childCount: farms.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // FAB padding
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
                'Error loading farms',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farms/scan'),
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
    );
  }
}

/// Empty state when no farms exist
class _EmptyFarmsView extends StatelessWidget {
  const _EmptyFarmsView({required this.onAddFarm});

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
              Icons.eco_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Farms Yet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start your mushroom cultivation journey by adding your first farm.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddFarm,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Farm'),
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

/// Statistics header showing aggregate data
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.farmCount,
    required this.farms,
  });

  final int farmCount;
  final List<Farm> farms;

  /// Count farms that are currently online (last active within 30 minutes)
  int get onlineCount {
    final now = DateTime.now();
    return farms.where((farm) {
      return farm.lastActive != null &&
          now.difference(farm.lastActive!).inMinutes < 30;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final online = onlineCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.agriculture,
                label: 'Active Farms',
                value: farmCount.toString(),
                color: colorScheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.check_circle_outline,
                label: 'Online',
                value: online.toString(),
                color: online > 0 ? Colors.green : colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  const _StatItem({
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
