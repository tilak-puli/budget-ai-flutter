import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthStateListener<OAuthController>(
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                  child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Text("Finget",
                        style: GoogleFonts.arimo(
                            textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 100,
                                fontWeight: FontWeight.bold))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        "Making Personal finance \nas simple as chatting",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                  ),
                ],
              )),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OAuthProviderButton(
                  // or any other OAuthProvider
                  provider: GoogleProvider(
                      clientId:
                          "706321535461-dpk7qs2sd140d59c5ke8ll392krpg50v.apps.googleusercontent.com"),
                ),
              ),
            ],
          ),
        ),
      ),
      listener: (oldState, newState, ctrl) {
        return null;
      },
    );
  }
}
