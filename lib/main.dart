import 'package:budget_ai/app.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
        clientId:
            "706321535461-dpk7qs2sd140d59c5ke8ll392krpg50v.apps.googleusercontent.com"),
  ]);

  runApp(
    ChangeNotifierProvider<ExpenseStore>(
      create: (context) => ExpenseStore(),
      child: ChangeNotifierProvider<ChatStore>(
          create: (context) => ChatStore(), 
          child: const MyApp()),
    ),
  );
}
