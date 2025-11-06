import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// MushPi Mobile Controller
/// 
/// Main entry point for the MushPi mobile application.
/// Wraps the app with ProviderScope for Riverpod state management.
void main() {
  runApp(
    const ProviderScope(
      child: MushPiApp(),
    ),
  );
}
