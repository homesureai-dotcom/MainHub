import 'package:flutter/material.dart';

import 'auth_screen.dart';

/// Renders authentication directly when signed out (pre-sign-in welcome and
/// walkthrough screens removed).
class SignedOutFlow extends StatelessWidget {
  const SignedOutFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthScreen(),
        );
      },
    );
  }
}
