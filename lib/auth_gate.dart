import 'package:budget_ai/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              PhoneAuthProvider()
            ],
          );
        }

        return const MyHomePage(title: 'FinGet');
      },
    );
  }
}// TODO Implement this library.