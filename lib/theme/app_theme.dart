import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finly/theme/neumorphic_colors.dart';

/// App theme configuration for Finly
/// Based on Neumorphism 2.0 Design Specification
class AppTheme {
  /// Creates light theme data
  static ThemeData lightTheme(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    final textTheme = GoogleFonts.robotoTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: GoogleFonts.roboto(
        color: NeumorphicColors.lightTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: NeumorphicColors.lightAccent,
      scaffoldBackgroundColor: NeumorphicColors.lightPrimaryBackground,
      canvasColor: NeumorphicColors.lightPrimaryBackground,
      colorScheme: ColorScheme.light(
        primary: NeumorphicColors.lightAccent,
        secondary: NeumorphicColors.lightSecondaryAccent,
        surface: NeumorphicColors.lightSecondaryBackground,
        background: NeumorphicColors.lightPrimaryBackground,
        onPrimary: Colors.white,
        onSecondary: NeumorphicColors.lightTextPrimary,
        onSurface: NeumorphicColors.lightTextPrimary,
        onBackground: NeumorphicColors.lightTextPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: NeumorphicColors.lightPrimaryBackground,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: NeumorphicColors.lightTextPrimary),
      ),
      cardTheme: CardTheme(
        color: NeumorphicColors.lightPrimaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeumorphicColors.lightPrimaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: NeumorphicColors.lightAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Creates dark theme data
  static ThemeData darkTheme(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    final textTheme = GoogleFonts.robotoTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: GoogleFonts.roboto(
        color: NeumorphicColors.darkTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: NeumorphicColors.darkAccent,
      scaffoldBackgroundColor: NeumorphicColors.darkPrimaryBackground,
      canvasColor: NeumorphicColors.darkPrimaryBackground,
      colorScheme: ColorScheme.dark(
        primary: NeumorphicColors.darkAccent,
        secondary: NeumorphicColors.darkSecondaryAccent,
        surface: NeumorphicColors.darkSecondaryBackground,
        background: NeumorphicColors.darkPrimaryBackground,
        onPrimary: Colors.white,
        onSecondary: NeumorphicColors.darkTextPrimary,
        onSurface: NeumorphicColors.darkTextPrimary,
        onBackground: NeumorphicColors.darkTextPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: NeumorphicColors.darkPrimaryBackground,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: NeumorphicColors.darkTextPrimary),
      ),
      cardTheme: CardTheme(
        color: NeumorphicColors.darkPrimaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeumorphicColors.darkPrimaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: NeumorphicColors.darkAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}
