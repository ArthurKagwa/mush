import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/ble_connection_manager.dart';
import 'providers/sensor_data_listener.dart';
import 'providers/auto_reconnect_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/control_screen.dart';
import 'screens/stage_screen.dart';
import 'screens/farm_detail_screen.dart';
import 'screens/device_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/main_scaffold.dart';

/// Main application widget with theme and routing configuration.
class MushPiApp extends ConsumerStatefulWidget {
  const MushPiApp({super.key});

  @override
  ConsumerState<MushPiApp> createState() => _MushPiAppState();
}

class _MushPiAppState extends ConsumerState<MushPiApp> {
  bool _autoReconnectInitialized = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    // Initialize BLE connection manager to monitor connections and update farm status
    // This ensures farms show as "Online" when their MushPi devices are connected
    ref.read(bleConnectionManagerProvider);

    // Initialize sensor data listener to automatically save BLE readings to database
    // This captures environmental data from BLE notifications and stores it
    ref.read(sensorDataListenerProvider);

    // Initialize auto-reconnect service (only once)
    // Attempts to reconnect to last connected device on app startup
    if (!_autoReconnectInitialized) {
      _autoReconnectInitialized = true;
      _initializeAutoReconnect();
    }

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

  /// Initialize auto-reconnect service
  /// 
  /// Attempts to reconnect to the last connected device on app startup
  /// if auto-reconnect is enabled and a device was previously connected.
  void _initializeAutoReconnect() {
    // Run asynchronously to not block UI
    // Add delay to ensure database and BLE are fully initialized
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        debugPrint('🔄 [AUTO-RECONNECT] Initializing auto-reconnect service...');
        final autoReconnect = ref.read(autoReconnectServiceProvider);
        
        // Check if auto-reconnect is enabled
        final isEnabled = await autoReconnect.isEnabled();
        debugPrint('🔄 [AUTO-RECONNECT] Auto-reconnect enabled: $isEnabled');
        
        if (!isEnabled) {
          debugPrint('🔄 [AUTO-RECONNECT] Auto-reconnect is disabled, skipping');
          return;
        }

        // Attempt reconnection in background
        debugPrint('🔄 [AUTO-RECONNECT] Starting reconnection attempt...');
        final success = await autoReconnect.attemptReconnection();
        
        if (success) {
          debugPrint('✅ [AUTO-RECONNECT] Successfully reconnected to saved device');
        } else {
          debugPrint('❌ [AUTO-RECONNECT] Failed to reconnect to saved device');
        }
      } catch (error, stackTrace) {
        debugPrint('❌ [AUTO-RECONNECT] Initialization failed: $error');
        debugPrint('Stack trace: $stackTrace');
      }
    });
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

          // Control tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/control',
                name: 'control',
                builder: (context, state) => const ControlScreen(),
              ),
            ],
          ),

          // Stage tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stage',
                name: 'stage',
                builder: (context, state) => const StageScreen(),
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
