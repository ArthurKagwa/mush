import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/farm_detail_screen.dart';
import 'screens/device_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/main_scaffold.dart';

/// Main application widget with theme and routing configuration.
class MushPiApp extends ConsumerWidget {
  const MushPiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MushPi',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Routing configuration
      routerConfig: router,
    );
  }
}

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Main app with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Farms tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/farms',
                name: 'farms',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Device scan screen
                  GoRoute(
                    path: 'scan',
                    name: 'scan',
                    builder: (context, state) => const DeviceScanScreen(),
                  ),
                  // History screen
                  GoRoute(
                    path: 'history',
                    name: 'history',
                    builder: (context, state) => const HistoryScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Monitoring tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/monitoring',
                name: 'monitoring',
                builder: (context, state) => const MonitoringScreen(),
              ),
            ],
          ),

          // Settings tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Farm detail screen (outside bottom nav)
      GoRoute(
        path: '/farm/:id',
        name: 'farm-detail',
        builder: (context, state) {
          final farmId = state.pathParameters['id']!;
          return FarmDetailScreen(farmId: farmId);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/farms'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Farms'),
            ),
          ],
        ),
      ),
    ),
  );
});
