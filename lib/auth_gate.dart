import 'package:budget_ai/pages/homepage.dart';
import 'package:budget_ai/pages/login.dart';
import 'package:budget_ai/services/initialization_service.dart';
import 'package:budget_ai/services/app_init_service.dart';
import 'package:budget_ai/state/budget_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, GoogleAuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // When user is logged in, initialize all stores from the app init data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeStoresFromAppData(context);
        });

        return const MyHomePage(title: 'Coin Master AI');
      },
    );
  }

  // Initialize all stores from app init data after login
  void _initializeStoresFromAppData(BuildContext context) async {
    // Get all stores and services from providers
    final initService =
        Provider.of<InitializationService>(context, listen: false);
    final appInitService = Provider.of<AppInitService>(context, listen: false);
    final budgetStore = Provider.of<BudgetStore>(context, listen: false);
    final expenseStore = Provider.of<ExpenseStore>(context, listen: false);
    final chatStore = Provider.of<ChatStore>(context, listen: false);

    // Get current month's date range
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Try using AppInitService first
    final initData = await appInitService.fetchAppInitData(
        fromDate: firstDayOfMonth, toDate: lastDayOfMonth);

    if (initData != null) {
      // Initialize stores with data from unified API
      budgetStore.initializeFromAppData(initData);
      expenseStore.initializeFromAppData(initData);
      return;
    }

    // Fall back to InitializationService if AppInitService failed
    if (initService.appInitData != null) {
      // Initialize all stores from the cached data
      await initService.initializeStores(budgetStore, expenseStore, chatStore);
    } else {
      // Initialize from API if needed
      final success = await initService.initializeAppData(
          fromDate: firstDayOfMonth, toDate: lastDayOfMonth);

      if (success) {
        // Initialize all stores with the fetched data
        await initService.initializeStores(
            budgetStore, expenseStore, chatStore);
      }
    }
  }
}
