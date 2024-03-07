import 'package:budget_ai/pages/homepage.dart';
import 'package:budget_ai/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider, GoogleAuthProvider;
import 'package:flutter/material.dart';

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

        return const MyHomePage(title: 'Finget');
      },
    );
  }
}// TODO Implement this library.