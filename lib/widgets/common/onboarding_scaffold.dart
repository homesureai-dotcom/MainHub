import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

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