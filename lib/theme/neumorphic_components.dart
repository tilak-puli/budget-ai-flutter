import 'package:flutter/material.dart';
import 'package:finly/theme/neumorphic_box.dart';
import 'package:finly/theme/neumorphic_colors.dart';

/// A collection of reusable Neumorphic UI components for Finly
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
    bool isDisabled = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        final buttonColor = isDisabled ? Colors.grey.withOpacity(0.3) : color;
        final effectiveDepth = isDisabled ? depth * 0.5 : depth;

        return GestureDetector(
          onTapDown:
              isDisabled ? null : (_) => setState(() => isPressed = true),
          onTapUp:
              isDisabled
                  ? null
                  : (_) {
                    setState(() => isPressed = false);
                    onPressed();
                  },
          onTapCancel:
              isDisabled ? null : () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: NeumorphicBox.decoration(
              context: context,
              color: buttonColor,
              borderRadius: size / 2,
              depth: effectiveDepth,
              isPressed: isPressed,
            ),
            child: Center(
              child: Opacity(opacity: isDisabled ? 0.6 : 1.0, child: icon),
            ),
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
    bool isDisabled = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        final buttonColor = isDisabled ? Colors.grey.withOpacity(0.3) : color;
        final effectiveDepth = isDisabled ? depth * 0.5 : depth;

        return Container(
          width: size + 10, // Add extra space for the badge
          height: size + 10, // Add extra space for the badge
          child: Stack(
            children: [
              // The main button - centered in the container
              Positioned(
                top: 5,
                left: 5,
                child: GestureDetector(
                  onTapDown:
                      isDisabled
                          ? null
                          : (_) => setState(() => isPressed = true),
                  onTapUp:
                      isDisabled
                          ? null
                          : (_) {
                            setState(() => isPressed = false);
                            onPressed();
                          },
                  onTapCancel:
                      isDisabled
                          ? null
                          : () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: size,
                    height: size,
                    decoration: NeumorphicBox.decoration(
                      context: context,
                      color: buttonColor,
                      borderRadius: size / 2,
                      depth: effectiveDepth,
                      isPressed: isPressed,
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: isDisabled ? 0.6 : 1.0,
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ),

              // The badge (if showing) - now properly positioned
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                      // Add a border for better visibility
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Creates a neumorphic text input field that matches the form style
  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? suffixWidget,
    double borderRadius = 8.0,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark
            ? NeumorphicColors.darkTextPrimary
            : NeumorphicColors.lightTextPrimary;
    final hintColor =
        isDark
            ? NeumorphicColors.darkTextSecondary
            : NeumorphicColors.lightTextSecondary;
    final borderColor =
        isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.2);
    final fillColor =
        isDark ? Colors.grey.withOpacity(0.08) : Colors.grey.withOpacity(0.05);
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: TextStyle(color: textColor, fontSize: 16.0),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor.withOpacity(0.7), fontSize: 16.0),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffix: suffixWidget,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: accentColor.withOpacity(0.8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
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
    final bgColor =
        color ??
        (isDark
            ? NeumorphicColors.darkSecondaryBackground
            : NeumorphicColors.lightSecondaryBackground);
    final textColor =
        isDark
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
    final color =
        progressColor ??
        (isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent);
    final bgColor =
        backgroundColor ??
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
