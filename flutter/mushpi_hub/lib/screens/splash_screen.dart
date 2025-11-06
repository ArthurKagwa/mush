import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state_provider.dart';
import '../providers/farms_provider.dart';

/// Splash screen shown during app initialization.
///
/// Displays MushPi logo and loading indicator while:
/// - Initializing database
/// - Loading saved settings
/// - Checking for saved farms
/// - Preparing app state
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Initialize app and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Watch app initialization
      await ref.read(appInitializationProvider.future);

      // Wait minimum time for splash screen
      await Future.delayed(const Duration(seconds: 2));

      // Check if we have any farms
      final farms = await ref.read(allFarmsProvider.future);

      if (!mounted) return;

      // Navigate to appropriate screen
      if (farms.isEmpty) {
        // No farms, go to farms tab (will show empty state)
        context.go('/farms');
      } else {
        // Has farms, go to farms tab
        context.go('/farms');
      }
    } catch (e, stack) {
      developer.log(
        'Splash screen initialization error',
        name: 'mushpi.splash',
        error: e,
        stackTrace: stack,
        level: 1000,
      );

      if (!mounted) return;

      // Show error and navigate to home anyway
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialization error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.go('/farms');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Logo icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.eco,
                          size: 60,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'MushPi',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Mushroom Cultivation Controller',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
