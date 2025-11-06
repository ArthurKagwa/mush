import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';

/// A widget that allows users to select between light, dark, and system themes.
///
/// This widget integrates with [themeModeProvider] to persist the theme selection.
/// It can be displayed as a dialog, bottom sheet, or inline widget.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Theme',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _ThemeModeOption(
          title: 'Light',
          subtitle: 'Always use light theme',
          icon: Icons.light_mode_outlined,
          themeMode: ThemeMode.light,
          isSelected: currentThemeMode == ThemeMode.light,
          onTap: () => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(ThemeMode.light),
        ),
        _ThemeModeOption(
          title: 'Dark',
          subtitle: 'Always use dark theme',
          icon: Icons.dark_mode_outlined,
          themeMode: ThemeMode.dark,
          isSelected: currentThemeMode == ThemeMode.dark,
          onTap: () => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(ThemeMode.dark),
        ),
        _ThemeModeOption(
          title: 'System',
          subtitle: 'Follow system settings',
          icon: Icons.brightness_auto_outlined,
          themeMode: ThemeMode.system,
          isSelected: currentThemeMode == ThemeMode.system,
          onTap: () => ref
              .read(themeModeProvider.notifier)
              .setThemeMode(ThemeMode.system),
        ),
      ],
    );
  }

  /// Show theme selector as a bottom sheet
  static void showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const ThemeSelector(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  /// Show theme selector as a dialog
  static void showAsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: const ThemeSelector(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Individual theme mode option tile
class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: colorScheme.primary,
            )
          : Icon(
              Icons.radio_button_unchecked,
              color: colorScheme.onSurfaceVariant,
            ),
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Compact theme toggle button for app bars and toolbars
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;

    // Determine icon based on current theme mode and actual brightness
    IconData icon;
    String tooltip;

    if (currentThemeMode == ThemeMode.system) {
      icon = Icons.brightness_auto;
      tooltip = 'Theme: System';
    } else if (brightness == Brightness.light) {
      icon = Icons.light_mode;
      tooltip = 'Theme: Light';
    } else {
      icon = Icons.dark_mode;
      tooltip = 'Theme: Dark';
    }

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => _cycleTheme(ref),
    );
  }

  void _cycleTheme(WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    // Cycle through: Light → Dark → System → Light
    switch (currentMode) {
      case ThemeMode.light:
        notifier.setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        notifier.setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        notifier.setThemeMode(ThemeMode.light);
        break;
    }
  }
}

/// Animated theme toggle switch
class AnimatedThemeSwitch extends ConsumerStatefulWidget {
  const AnimatedThemeSwitch({super.key});

  @override
  ConsumerState<AnimatedThemeSwitch> createState() =>
      _AnimatedThemeSwitchState();
}

class _AnimatedThemeSwitchState extends ConsumerState<AnimatedThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Update animation based on theme
    if (isDark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return GestureDetector(
      onTap: () => _toggleTheme(),
      child: Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // Moon icon (dark mode)
            Positioned(
              left: 8,
              top: 8,
              child: Icon(
                Icons.dark_mode,
                size: 16,
                color: isDark
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // Sun icon (light mode)
            Positioned(
              right: 8,
              top: 8,
              child: Icon(
                Icons.light_mode,
                size: 16,
                color: !isDark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // Sliding indicator
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: _animation.value * 28 + 2,
                  top: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTheme() {
    final currentMode = ref.read(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final brightness = Theme.of(context).brightness;

    // Simple toggle between light and dark
    if (currentMode == ThemeMode.system) {
      // If system, switch to opposite of current
      notifier.setThemeMode(
        brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light,
      );
    } else {
      // Toggle between light and dark
      notifier.setThemeMode(
        currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );
    }
  }
}

/// Theme preview card showing how the theme looks
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    required this.themeMode,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ThemeMode themeMode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = themeMode == ThemeMode.light ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.light);

    final previewColorScheme = isLight
        ? ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          )
        : ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          );

    String title;
    IconData icon;
    switch (themeMode) {
      case ThemeMode.light:
        title = 'Light';
        icon = Icons.light_mode;
        break;
      case ThemeMode.dark:
        title = 'Dark';
        icon = Icons.dark_mode;
        break;
      case ThemeMode.system:
        title = 'System';
        icon = Icons.brightness_auto;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Mini preview of theme colors
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: previewColorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: previewColorScheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previewColorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previewColorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previewColorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
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
