import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

class HeroScoreCard extends StatelessWidget {
  final int score;
  final String status;
  final String subtitle;

  const HeroScoreCard({
    super.key,
    required this.score,
    required this.status,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PROPERTY HEALTH SCORE",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Column(
              children: [
                Text(
                  "$score",
                  style: const TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}