import 'package:budget_ai/app.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider<ExpenseStore>(
      create: (context) => ExpenseStore(),
      child: const MyApp(),
    ),
  );
}
