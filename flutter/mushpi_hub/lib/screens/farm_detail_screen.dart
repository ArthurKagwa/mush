import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

import '../providers/current_farm_provider.dart';
import '../providers/farms_provider.dart';

/// Farm detail screen showing single farm monitoring.
///
/// Displays:
/// - Real-time environmental data
/// - Control settings
/// - Stage information
/// - Historical charts
/// - Harvest records
class FarmDetailScreen extends ConsumerStatefulWidget {
  const FarmDetailScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends ConsumerState<FarmDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    developer.log(
      '📱 [FarmDetailScreen] Initializing with farm ID: ${widget.farmId}',
      name: 'mushpi.screens.farm_detail',
    );
    
    // Select this farm as current when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log(
        '🎯 [FarmDetailScreen] Selecting farm: ${widget.farmId}',
        name: 'mushpi.screens.farm_detail',
      );
      ref.read(currentFarmIdProvider.notifier).selectFarm(widget.farmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      '🎨 [FarmDetailScreen] Building screen for farm: ${widget.farmId}',
      name: 'mushpi.screens.farm_detail',
    );
    
    // Fetch farm directly by ID instead of using currentFarmProvider
    // This avoids timing issues with the currentFarmIdProvider
    final farmAsync = ref.watch(farmByIdProvider(widget.farmId));

    return Scaffold(
      appBar: AppBar(
        title: farmAsync.when(
          data: (farm) {
            final title = farm?.name ?? 'Farm Not Found';
            developer.log(
              '📋 [FarmDetailScreen] AppBar title: $title',
              name: 'mushpi.screens.farm_detail',
            );
            return Text(title);
          },
          loading: () {
            developer.log(
              '⏳ [FarmDetailScreen] AppBar: Loading...',
              name: 'mushpi.screens.farm_detail',
            );
            return const Text('Loading...');
          },
          error: (error, __) {
            developer.log(
              '❌ [FarmDetailScreen] AppBar error: $error',
              name: 'mushpi.screens.farm_detail',
              error: error,
              level: 1000,
            );
            return const Text('Error');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            developer.log(
              '⬅️ [FarmDetailScreen] Navigating back to home',
              name: 'mushpi.screens.farm_detail',
            );
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              developer.log(
                '⚙️ [FarmDetailScreen] Opening farm options menu',
                name: 'mushpi.screens.farm_detail',
              );
              // TODO: Show farm options menu
            },
          ),
        ],
      ),
      body: farmAsync.when(
        data: (farm) {
          if (farm == null) {
            developer.log(
              '❌ [FarmDetailScreen] Farm not found in database: ${widget.farmId}',
              name: 'mushpi.screens.farm_detail',
              level: 900,
            );
            return _buildNotFoundState(context);
          }

          developer.log(
            '✅ [FarmDetailScreen] Rendering farm: ${farm.name}',
            name: 'mushpi.screens.farm_detail',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (farm.primarySpecies != null) ...[
                          const SizedBox(height: 8),
                          Text('Species: ${farm.primarySpecies!.displayName}'),
                        ],
                        if (farm.location != null) ...[
                          const SizedBox(height: 4),
                          Text('Location: ${farm.location}'),
                        ],
                        const SizedBox(height: 8),
                        Text('Device ID: ${farm.deviceId}'),
                        const SizedBox(height: 4),
                        Text('Total Harvests: ${farm.totalHarvests}'),
                        Text('Total Yield: ${farm.totalYieldKg.toStringAsFixed(1)} kg'),
                        const SizedBox(height: 8),
                        Text(
                          'Created: ${_formatDate(farm.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (farm.lastActive != null)
                          Text(
                            'Last Active: ${_formatDate(farm.lastActive!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // TODO: Add environmental data cards
                // TODO: Add control panels
                // TODO: Add charts
                // TODO: Add harvest list

                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Farm monitoring interface coming soon...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () {
          developer.log(
            '⏳ [FarmDetailScreen] Loading farm data...',
            name: 'mushpi.screens.farm_detail',
          );
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          developer.log(
            '❌ [FarmDetailScreen] Error loading farm',
            name: 'mushpi.screens.farm_detail',
            error: error,
            stackTrace: stack,
            level: 1000,
          );
          return _buildErrorState(context, error);
        },
      ),
    );
  }

  /// Build not found state
  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 120,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Farm Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'The farm you\'re looking for doesn\'t exist or has been deleted.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Farm ID: ${widget.farmId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                developer.log(
                  '🔄 [FarmDetailScreen] Retrying farm fetch',
                  name: 'mushpi.screens.farm_detail',
                );
                ref.invalidate(farmByIdProvider(widget.farmId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Farm',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                developer.log(
                  '🔄 [FarmDetailScreen] Retrying after error',
                  name: 'mushpi.screens.farm_detail',
                );
                ref.invalidate(farmByIdProvider(widget.farmId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
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
