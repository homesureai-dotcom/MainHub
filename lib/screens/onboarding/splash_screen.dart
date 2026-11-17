import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/common/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: AppGradients.hero,
        ),

        child: SafeArea(
          child: Column(
            children: [

              const Spacer(),

              const AppLogo(
                variant: AppLogoVariant.full,
                height: 190,
              ),

              const SizedBox(height: 16),

              const Text(
                'Know Before You Buy',
                style: TextStyle(
                  color: HomeSureColors.slateMuted,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 5,
                  backgroundColor: HomeSureColors.midnightInteractive,
                  color: HomeSureColors.champagneGold,
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Preparing your property intelligence...',
                style: TextStyle(
                  color: HomeSureColors.slateMuted,
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}