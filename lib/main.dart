import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'features/design_system/screens/engine_playground_screen.dart';

void main() {
  runApp(const HomeSureAIApp());
}

///
/// Toggle this to true whenever you want to test
/// the Property Intelligence Engine.
///
/// false = Normal HomeSure App
/// true  = Engine Playground
///
const bool kDeveloperMode = false;

class HomeSureAIApp extends StatelessWidget {
  const HomeSureAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeSure AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: kDeveloperMode
          ? const EnginePlaygroundScreen()
          : const SplashScreen(),
    );
  }
}