import 'package:flutter/material.dart';
import 'package:finly/theme/index.dart';

/// A custom app bar with Neumorphic design
class NeumorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final double height;
  final bool showShadow;
  final bool useAccentColor;
  final Widget? bottom;
  final Widget? flexibleContent;
  final double? expandedHeight;

  const NeumorphicAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.elevation = 4.0,
    this.height = kToolbarHeight,
    this.showShadow = true,
    this.useAccentColor = true,
    this.bottom,
    this.flexibleContent,
    this.expandedHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use accent color (purple) as background if specified, otherwise use theme background
    final backgroundColor =
        useAccentColor
            ? (isDark
                ? NeumorphicColors.darkPurpleBackground
                : NeumorphicColors.lightPurpleBackground)
            : (isDark
                ? NeumorphicColors.darkPrimaryBackground
                : NeumorphicColors.lightPrimaryBackground);

    // Text is white when on purple background, otherwise use theme text color
    final textColor =
        useAccentColor
            ? Colors.white
            : (isDark
                ? NeumorphicColors.darkTextPrimary
                : NeumorphicColors.lightTextPrimary);

    if (expandedHeight != null && flexibleContent != null) {
      // Return a flexible space app bar if expandedHeight and flexibleContent are provided
      return SliverAppBar(
        expandedHeight: expandedHeight,
        floating: false,
        pinned: true,
        backgroundColor: backgroundColor,
        elevation: showShadow ? elevation : 0,
        leading: leading,
        actions: actions,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
              bottom: bottom != null ? 50 : 0,
            ),
            child: flexibleContent,
          ),
        ),
        bottom:
            bottom != null
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: bottom!,
                )
                : null,
      );
    }

    // Regular app bar with modern styling
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: showShadow ? elevation : 0,
      scrolledUnderElevation: showShadow ? elevation : 0,
      automaticallyImplyLeading: false,
      leading: leading,
      leadingWidth: 120,
      actions: actions,
      centerTitle: true,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottom:
          bottom != null
              ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: bottom!,
              )
              : null,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom != null ? height + 50 : height);
}
