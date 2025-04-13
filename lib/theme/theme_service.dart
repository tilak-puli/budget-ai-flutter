import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage theme mode and persist user preference
class ThemeService extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';

  late ThemeMode _themeMode;
  bool _isInitialized = false;

  /// Get current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if theme is dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize theme service and load saved preference
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);

    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Set specific theme mode and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String themeValue;

    switch (mode) {
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.system:
      default:
        themeValue = 'system';
        break;
    }

    await prefs.setString(_themePreferenceKey, themeValue);
  }
}
