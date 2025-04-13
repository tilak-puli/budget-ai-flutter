import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget_ai/theme/theme_service.dart';

/// Provider for theme service
/// Use this to access theme functionality throughout the app
class ThemeProvider extends StatelessWidget {
  final Widget child;
  final ThemeService service;

  const ThemeProvider({
    Key? key,
    required this.child,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeService>.value(
      value: service,
      child: child,
    );
  }

  /// Get the ThemeService instance from the context
  static ThemeService of(BuildContext context) {
    return Provider.of<ThemeService>(context, listen: false);
  }

  /// Get the ThemeService instance from the context with listening
  static ThemeService watch(BuildContext context) {
    return Provider.of<ThemeService>(context);
  }
}
