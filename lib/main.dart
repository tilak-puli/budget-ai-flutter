import 'package:budget_ai/app.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/theme/theme_service.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay style to match our app background
  // This ensures the navigation bar area has the same color as our app
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black, // Use black for the nav bar
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Set the color for the entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
        clientId:
            "706321535461-dpk7qs2sd140d59c5ke8ll392krpg50v.apps.googleusercontent.com"),
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
      child: MyApp(themeService: themeService),
    ),
  );
}
