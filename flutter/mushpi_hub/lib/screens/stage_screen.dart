import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stage_wizard_screen.dart';

/// Stage Configuration Screen
///
/// This is a wrapper that shows the new stage wizard for configuring
/// all three growth stages (Incubation, Pinning, Fruiting) in one flow.
class StageScreen extends ConsumerWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simply show the wizard
    return const StageWizardScreen();
  }
}
