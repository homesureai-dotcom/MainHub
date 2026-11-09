import 'package:flutter/material.dart';

import '../../../screens/onboarding/splash_screen.dart';
import '../../../screens/onboarding/welcome_screen.dart';
import '../../../screens/onboarding/how_it_works_screen.dart';
import 'auth_screen.dart';

/// Keeps signed-out navigation separate from the root AuthGate.
///
/// When Firebase authentication changes, AuthGate replaces this entire
/// widget with the appropriate authenticated screen.
class SignedOutFlow extends StatelessWidget {
  const SignedOutFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            switch (settings.name) {
              case '/welcome':
                return const WelcomeScreen();
              case '/how-it-works':
                return const HowItWorksScreen();
              case '/sign-in':
                return const AuthScreen();
              case '/':
              default:
                return const SplashScreen();
            }
          },
        );
      },
    );
  }
}
