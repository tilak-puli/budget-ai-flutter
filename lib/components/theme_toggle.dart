import 'package:flutter/material.dart';
import 'package:budget_ai/theme/index.dart';

/// A neumorphic theme toggle button that switches between light and dark mode
class ThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ThemeToggle({
    Key? key,
    required this.isDarkMode,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeumorphicComponents.circularButton(
      context: context,
      size: 48.0,
      icon: Icon(
        isDarkMode ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: onToggle,
    );
  }
}

/// A neumorphic theme toggle switch component
class ThemeToggleSwitch extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ThemeToggleSwitch({
    Key? key,
    required this.isDarkMode,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;
    final inactiveColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 70,
        height: 36,
        decoration: NeumorphicBox.decoration(
          context: context,
          borderRadius: 18,
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Background icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.light_mode,
                    size: 16,
                    color: isDarkMode
                        ? Theme.of(context).textTheme.labelMedium?.color
                        : activeColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.dark_mode,
                    size: 16,
                    color: isDarkMode
                        ? activeColor
                        : Theme.of(context).textTheme.labelMedium?.color,
                  ),
                ),
              ],
            ),
            // Animated thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: isDarkMode ? 36 : 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
