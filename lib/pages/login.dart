import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthStateListener<OAuthController>(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF121212),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Column(
                children: [
                  // App Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A1A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(0, 12),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          offset: const Offset(0, 6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/new_icon.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Text(
                    "Finly",
                    style: GoogleFonts.satisfy(
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 48,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: Colors.blue.withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  Text(
                    "Making Personal Finance\nAs Simple As Chatting",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              // Sign in message
              Text(
                "Start managing your finances with AI",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sign in button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(0, 12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    Container(
                      color: const Color(0xFF4285F4),
                      child: OAuthProviderButton(
                        provider: GoogleProvider(
                          clientId: Platform.isAndroid
                              ? "706321535461-6n6h3ponqh88p0p3u02eds96o6v3ivs2.apps.googleusercontent.com" // SHA-1 specific client ID
                              : "706321535461-dpk7qs2sd140d59c5ke8ll392krpg50v.apps.googleusercontent.com", // Web client ID
                        ),
                        variant: OAuthButtonVariant.icon_and_text,
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ],
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
