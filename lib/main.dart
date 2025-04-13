import 'package:budget_ai/app.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/theme/theme_service.dart';
import 'package:budget_ai/services/subscription_service.dart';
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
      ],
      child: Builder(
        builder: (context) {
          return MyApp(themeService: themeService);
        },
      ),
    ),
  );
}
