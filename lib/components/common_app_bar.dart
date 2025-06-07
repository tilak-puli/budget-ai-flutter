import 'package:flutter/material.dart';
import 'package:finly/theme/index.dart';
import 'package:google_fonts/google_fonts.dart';

/// A common app bar used across the app for consistent styling
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0.0,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use purple/blue background color based on app theme
    final backgroundColor =
        isDark
            ? NeumorphicColors.darkPurpleBackground
            : NeumorphicColors.lightPurpleBackground;

    // Text color is white on the colored background
    final textColor = Colors.white;

    // Determine leading widget
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      // Set fixed width of 56 to ensure back button is aligned to the left
      leadingWidth: leadingWidget != null ? 56 : 0,
      actions: actions,
      centerTitle: true,
      titleSpacing:
          leadingWidget != null ? 0 : NavigationToolbar.kMiddleSpacing,
      title: Text(
        title,
        style: GoogleFonts.satisfy(
          textStyle: TextStyle(
            color: textColor,
            fontSize: 32,
            letterSpacing: 0.5,
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
