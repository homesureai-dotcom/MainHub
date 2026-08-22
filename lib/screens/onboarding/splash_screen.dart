import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import 'welcome_screen.dart';

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
            builder: (_) => const WelcomeScreen(),
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

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "HomeSure AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Know Before You Buy",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const Spacer(),

              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 5,
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Preparing your property intelligence...",
                style: TextStyle(
                  color: Colors.white70,
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