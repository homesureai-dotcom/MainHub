import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AnalyzingStep extends StatelessWidget {
  final String title;
  final bool completed;

  const AnalyzingStep({
    super.key,
    required this.title,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(
          color: completed
              ? HomeSureColors.statusPositiveBorder
              : HomeSureColors.borderSlate,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: completed
                ? HomeSureColors.statusPositiveText
                : HomeSureColors.slateMuted,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HomeSureColors.champagneInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}