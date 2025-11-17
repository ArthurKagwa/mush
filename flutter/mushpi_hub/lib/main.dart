import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mushpi_hub/data/repositories/ble_repository.dart';
import 'app.dart';

/// MushPi Mobile Controller
/// 
/// Main entry point for the MushPi mobile application.
/// Wraps the app with ProviderScope for Riverpod state management.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (must be listed in pubspec assets)
  // If .env is missing, continue with empty env and log to console.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Safe to continue; repository will use fallbacks and log appropriately
    // ignore: avoid_print
    print('⚠️  .env not found or failed to load: $e');
  }

  // Inject runtime env into BLERepository (keeps repository decoupled from flutter_dotenv)
  BLERepository.setRuntimeEnv(dotenv.env);

  runApp(
    const ProviderScope(
      child: MushPiApp(),
    ),
  );
}
