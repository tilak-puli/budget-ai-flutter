import 'package:flutter/material.dart';
import 'package:budget_ai/theme/neumorphic_colors.dart';

/// Neumorphic Box Decoration helper for Coin Master AI
class NeumorphicBox {
  /// Creates a neumorphic box decoration with elevation effect
  static BoxDecoration decoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 15.0,
    double depth = 5.0,
    bool isPressed = false,
    Offset? lightSource,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on theme
    final baseColor = color ??
        (isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground);

    final lightShadowColor = isDark
        ? NeumorphicColors.darkShadowLight
        : NeumorphicColors.lightShadowLight;

    final darkShadowColor = isDark
        ? NeumorphicColors.darkShadowDark
        : NeumorphicColors.lightShadowDark;

    // Default light source is top-left
    final source = lightSource ?? const Offset(-3, -3);

    // Invert shadow direction if pressed
    final lightOffset = isPressed ? -source : source;
    final darkOffset = isPressed ? source : -source;

    // Shadow blur and spread based on depth
    final blurRadius = depth * 1.0;
    final spreadRadius = depth * 0.2;

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Light shadow
        BoxShadow(
          color: lightShadowColor.withOpacity(isPressed ? 0.5 : 0.8),
          offset: lightOffset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        // Dark shadow
        BoxShadow(
          color: darkShadowColor.withOpacity(isPressed ? 0.8 : 0.6),
          offset: darkOffset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }

  /// Creates an inset/pressed neumorphic box decoration
  static BoxDecoration insetDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 15.0,
    double depth = 2.0,
  }) {
    return decoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: depth,
      isPressed: true,
    );
  }
}
