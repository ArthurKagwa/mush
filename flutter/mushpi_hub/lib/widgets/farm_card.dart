import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/farm.dart';
import '../core/theme/app_theme.dart';

/// Card widget displaying farm summary information.
///
/// Shows:
/// - Farm name and species
/// - Current stage and days
/// - Connection status (real-time BLE)
/// - Production stats
/// - Quick metrics
/// - Reconnect button (if showReconnect=true)
class FarmCard extends ConsumerWidget {
  const FarmCard({
    required this.farm,
    required this.onTap,
    this.showReconnect = false,
    super.key,
  });

  final Farm farm;
  final VoidCallback onTap;
  final bool showReconnect;

    @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    // Single source of truth: farm is online if lastActive < 1 minute
    final isOnline = farm.lastActive != null && 
                     DateTime.now().difference(farm.lastActive!).inMinutes < 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Farm icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Farm name and species
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (farm.primarySpecies != null)
                          Text(
                            '${farm.primarySpecies!.displayName} 🍄',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                      ],
                    ),
                  ),

                  // Connection status indicator
                  _ConnectionIndicator(
                    isConnected: isOnline,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reconnect button if disconnected and showReconnect is true
              if (showReconnect && !isOnline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to farm detail or scan screen for reconnection
                        context.push('/farms/scan');
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: customColors.warning,
                        side: BorderSide(color: customColors.warning),
                      ),
                    ),
                  ),
                ),

              // Production stats
              Row(
                children: [
                  _StatChip(
                    icon: Icons.grass,
                    label: 'Harvests',
                    value: farm.totalHarvests.toString(),
                    color: customColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.scale,
                    label: 'Yield',
                    value: '${farm.totalYieldKg.toStringAsFixed(1)} kg',
                    color: customColors.info,
                  ),
                ],
              ),

              if (farm.location != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      farm.location!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Connection status indicator
class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat chip showing metric
class _StatChip extends StatelessWidget {
  const _StatChip({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
