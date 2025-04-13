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
    final activeColor = isDark ? Colors.amber : Colors.indigo;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 80,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[200],
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            // Static icons
            Positioned(
              right: 12,
              top: 7,
              child: Icon(
                Icons.dark_mode,
                size: 16,
                color: isDarkMode ? activeColor : Colors.grey[500],
              ),
            ),
            // Animated thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: isDarkMode ? 44 : 3,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 16,
                      color: activeColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
