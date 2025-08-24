import 'package:finly/pages/homepage.dart';
import 'package:finly/pages/login.dart';
import 'package:finly/services/initialization_service.dart';
import 'package:finly/services/app_init_service.dart';
import 'package:finly/state/budget_store.dart';
import 'package:finly/state/expense_store.dart';
import 'package:finly/state/chat_store.dart';
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
        });

        return const MyHomePage(title: 'Finly');
      },
    );
  }
}
