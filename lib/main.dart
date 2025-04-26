import 'package:budget_ai/app.dart';
import 'package:budget_ai/state/budget_store.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/theme/theme_service.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/services/initialization_service.dart';
import 'package:budget_ai/services/app_init_service.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay style to match our app background
  // This ensures the navigation bar area has the same color as our app
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  // Enable edge-to-edge mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize subscription service
  final subscriptionService = SubscriptionService();
  await subscriptionService.initializeSubscriptions();

  // Initialize app data service
  final initializationService = InitializationService();
  final appInitService = AppInitService();

  // Get current month's date range
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  // Start data prefetch in background with the AppInitService
  // We don't await this as it's not critical for app startup
  // and we don't want to delay the app launch
  appInitService
      .fetchAppInitData(fromDate: firstDayOfMonth, toDate: lastDayOfMonth)
      .then((result) {
    if (result != null) {
      print('App data initialized successfully using unified API');
    } else {
      // If the unified API fails, fall back to the existing implementation
      initializationService
          .initializeAppData(fromDate: firstDayOfMonth, toDate: lastDayOfMonth)
          .then((success) {
        if (success) {
          print('App data initialized successfully using fallback method');
        } else {
          print(
              'App data initialization skipped or failed - will try again when needed');
        }
      });
    }
  });

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
        clientId: Platform.isAndroid
            ? "706321535461-6n6h3ponqh88p0p3u02eds96o6v3ivs2.apps.googleusercontent.com" // SHA-1 specific client ID
            : "706321535461-dpk7qs2sd140d59c5ke8ll392krpg50v.apps.googleusercontent.com"), // Web client ID
  ]);

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseStore>(
          create: (context) => ExpenseStore(),
        ),
        ChangeNotifierProvider<ChatStore>(
          create: (context) => ChatStore(),
        ),
        ChangeNotifierProvider<BudgetStore>(
          create: (context) => BudgetStore(),
        ),
        // Add both services as providers
        Provider<InitializationService>.value(value: initializationService),
        Provider<AppInitService>.value(value: appInitService),
      ],
      child: Builder(
        builder: (context) {
          // Connect ExpenseStore to BudgetStore
          final expenseStore =
              Provider.of<ExpenseStore>(context, listen: false);
          final budgetStore = Provider.of<BudgetStore>(context, listen: false);
          expenseStore.setBudgetStore(budgetStore);

          return MyApp(themeService: themeService);
        },
      ),
    ),
  );
}
