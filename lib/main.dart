import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/onboarding/splash_screen.dart';

void main() {
  runApp(const HomeSureAIApp());
}

class HomeSureAIApp extends StatelessWidget {
  const HomeSureAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeSure AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: const SplashScreen(),
    );
  }
}