import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold with bottom navigation bar.
///
/// Provides persistent bottom navigation across 5 main screens:
/// Farms, Monitoring, Control, Stage, and Settings.
/// Uses GoRouter's StatefulShellRoute for proper navigation state management.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Navigate to the selected branch (tab)
          navigationShell.goBranch(
            index,
            // Use true to restore the branch's navigation state
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: 'Farms',
            tooltip: 'View all farms',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Monitoring',
            tooltip: 'Monitor environmental conditions',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Control',
            tooltip: 'Environmental control settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Stage',
            tooltip: 'Growth stage management',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'App settings',
          ),
        ],
      ),
    );
  }
}
