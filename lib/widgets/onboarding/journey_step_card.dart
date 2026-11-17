import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class JourneyStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const JourneyStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(
          color: HomeSureColors.borderSlate,
        ),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: HomeSureColors.midnightInteractive,
            child: Icon(
              icon,
              color: HomeSureColors.champagneHighlight,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HomeSureColors.champagneInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: HomeSureColors.slateMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}