import 'package:flutter/material.dart';
import 'package:finly/theme/neumorphic_colors.dart';

/// Neumorphic Box Decoration helper for Finly
/// Implements consistent shadow styles based on the Neumorphism 2.0 design specification
class NeumorphicBox {
  /// Light source direction, consistent across all elements
  static const Offset defaultLightSource = Offset(-3, -3);

  /// Creates a neumorphic box decoration with elevation effect
  /// Standard raised effect for cards, buttons, and other elevated elements
  static BoxDecoration decoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 15.0,
    double depth = 5.0,
    bool isPressed = false,
    Offset? lightSource,
    double? intensity,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on theme
    final baseColor =
        color ??
        (isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground);

    final lightShadowColor =
        isDark
            ? NeumorphicColors.darkShadowLight
            : NeumorphicColors.lightShadowLight;

    final darkShadowColor =
        isDark
            ? NeumorphicColors.darkShadowDark
            : NeumorphicColors.lightShadowDark;

    // Default light source is top-left per design spec
    final source = lightSource ?? defaultLightSource;

    // Invert shadow direction if pressed
    final lightOffset = isPressed ? -source : source;
    final darkOffset = isPressed ? source : -source;

    // Shadow blur and spread based on depth
    final blurRadius = depth * 1.0;
    final spreadRadius = depth * 0.2;

    // Default intensity from design spec (0.8 for standard, 0.6 for dark)
    final lightIntensity = intensity ?? (isPressed ? 0.5 : 0.8);
    final darkIntensity = intensity ?? (isPressed ? 0.8 : 0.6);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Light shadow
        BoxShadow(
          color: lightShadowColor.withOpacity(lightIntensity),
          offset: lightOffset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        // Dark shadow
        BoxShadow(
          color: darkShadowColor.withOpacity(darkIntensity),
          offset: darkOffset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }

  /// Creates an inset/pressed neumorphic box decoration
  /// Used for pressed buttons, input fields, and selected items
  static BoxDecoration insetDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 15.0,
    double depth = 2.0,
    double? intensity,
  }) {
    return decoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: depth,
      isPressed: true,
      intensity: intensity,
    );
  }

  /// Creates a neumorphic card decoration
  /// Specialized for card elements with appropriate depth and radius
  static BoxDecoration cardDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 18.0,
    double depth = 5.0,
  }) {
    return decoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: depth,
    );
  }

  /// Creates a neumorphic button decoration
  /// Specialized for button elements with appropriate depth and radius
  static BoxDecoration buttonDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 12.0,
    double depth = 5.0,
    bool isPressed = false,
  }) {
    return decoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: depth,
      isPressed: isPressed,
    );
  }

  /// Creates a floating action button decoration
  /// Higher elevation for FABs as specified in the design
  static BoxDecoration fabDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 24.0,
    bool isPressed = false,
  }) {
    // FABs have highest elevation (8dp per design spec)
    return decoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: isPressed ? 2.0 : 8.0,
      isPressed: isPressed,
    );
  }

  /// Creates a decoration for text fields
  /// Inset appearance for text input elements
  static BoxDecoration textFieldDecoration({
    required BuildContext context,
    Color? color,
    double borderRadius = 12.0,
  }) {
    return insetDecoration(
      context: context,
      color: color,
      borderRadius: borderRadius,
      depth: 2.0,
    );
  }
}
