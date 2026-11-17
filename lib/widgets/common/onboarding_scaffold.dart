import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class OnboardingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottom;

  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeSureColors.midnightBg,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: HomeSureColors.champagneInk,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: HomeSureColors.slateMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              Expanded(child: child),

              if (bottom != null) ...[
                const SizedBox(height: 24),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}