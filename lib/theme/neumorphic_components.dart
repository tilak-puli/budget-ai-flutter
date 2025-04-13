import 'package:flutter/material.dart';
import 'package:budget_ai/theme/neumorphic_box.dart';
import 'package:budget_ai/theme/neumorphic_colors.dart';

/// A collection of reusable Neumorphic UI components for Coin Master AI
class NeumorphicComponents {
  /// Creates a neumorphic card
  static Widget card({
    required BuildContext context,
    required Widget child,
    Color? color,
    double borderRadius = 18.0,
    double depth = 5.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: NeumorphicBox.decoration(
          context: context,
          color: color,
          borderRadius: borderRadius,
          depth: depth,
        ),
        padding: padding,
        child: child,
      ),
    );
  }

  /// Creates a neumorphic button
  static Widget button({
    required BuildContext context,
    required Widget child,
    required VoidCallback onPressed,
    Color? color,
    double width = double.infinity,
    double height = 56.0,
    double borderRadius = 12.0,
    double depth = 5.0,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: height,
            decoration: NeumorphicBox.decoration(
              context: context,
              color: color,
              borderRadius: borderRadius,
              depth: depth,
              isPressed: isPressed,
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  /// Creates a neumorphic circular button
  static Widget circularButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 56.0,
    double depth = 5.0,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: NeumorphicBox.decoration(
              context: context,
              color: color,
              borderRadius: size / 2,
              depth: depth,
              isPressed: isPressed,
            ),
            child: Center(child: icon),
          ),
        );
      },
    );
  }

  /// Creates a neumorphic circular button with a badge
  static Widget circularButtonWithBadge({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 56.0,
    double depth = 5.0,
    bool showBadge = false,
    String badgeText = "",
    Color badgeColor = Colors.green,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return Stack(
          children: [
            // The main button
            GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) {
                setState(() => isPressed = false);
                onPressed();
              },
              onTapCancel: () => setState(() => isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: size,
                height: size,
                decoration: NeumorphicBox.decoration(
                  context: context,
                  color: color,
                  borderRadius: size / 2,
                  depth: depth,
                  isPressed: isPressed,
                ),
                child: Center(child: icon),
              ),
            ),

            // The badge (if showing)
            if (showBadge)
              Positioned(
                bottom: -5,
                right: -3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 18,
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Creates a neumorphic text input field
  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double borderRadius = 15.0,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final hintColor = isDark
        ? NeumorphicColors.darkTextSecondary
        : NeumorphicColors.lightTextSecondary;

    return Container(
      decoration: NeumorphicBox.insetDecoration(
        context: context,
        borderRadius: borderRadius,
      ),
      constraints: const BoxConstraints(
        minHeight: 52.0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: TextField(
          controller: controller,
          style: TextStyle(
            color: textColor,
            fontSize: 16.0,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 16.0,
            ),
            border: InputBorder.none,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  /// Creates a neumorphic category badge
  static Widget categoryBadge({
    required BuildContext context,
    required String text,
    Color? color,
    double borderRadius = 24.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ??
        (isDark
            ? NeumorphicColors.darkSecondaryBackground
            : NeumorphicColors.lightSecondaryBackground);
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;

    return Container(
      decoration: NeumorphicBox.insetDecoration(
        context: context,
        color: bgColor,
        borderRadius: borderRadius,
        depth: 2.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12.0,
        ),
      ),
    );
  }

  /// Creates a neumorphic progress bar
  static Widget progressBar({
    required BuildContext context,
    required double value, // 0.0 to 1.0
    double height = 20.0,
    double borderRadius = 10.0,
    Color? progressColor,
    Color? backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = progressColor ??
        (isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent);
    final bgColor = backgroundColor ??
        (isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground);

    return Container(
      height: height,
      decoration: NeumorphicBox.insetDecoration(
        context: context,
        color: bgColor,
        borderRadius: borderRadius,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
