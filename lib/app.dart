import 'package:budget_ai/auth_gate.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  const MyApp({
    super.key,
    required this.themeService,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Ensure system overlay styles are set
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: themeService.isDarkMode
          ? NeumorphicColors.darkPrimaryBackground
          : NeumorphicColors.lightPrimaryBackground,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    return ThemeProvider(
      service: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Coin Master AI',
            themeMode: themeService.themeMode,
            theme: AppTheme.lightTheme(context),
            darkTheme: AppTheme.darkTheme(context),
            home: const AuthGate(),
            builder: (context, child) {
              // Initialize GlobalContext for neumorphic styling in chat bubbles
              GlobalContext.context = context;

              // Apply the EasyLoading builder
              child = EasyLoading.init()(context, child);

              // Set background color for the entire app, including system navigation areas
              return Container(
                color: themeService.isDarkMode
                    ? NeumorphicColors.darkPrimaryBackground
                    : NeumorphicColors.lightPrimaryBackground,
                child: child,
              );
            },
            localizationsDelegates: const [
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              MonthYearPickerLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
