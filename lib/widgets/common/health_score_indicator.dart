import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../core/theme/homesure_tokens.dart';

class HealthScoreIndicator extends StatelessWidget {
  final int score;
  final String status;

  const HealthScoreIndicator({
    super.key,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 72,
      lineWidth: 10,
      animation: true,
      animationDuration: 1200,
      percent: (score / 100).clamp(0.0, 1.0),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: HomeSureColors.champagneGold,
      backgroundColor: HomeSureColors.champagneInk.withValues(alpha: 0.16),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: HomeSureColors.champagneHighlight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: HomeSureColors.slateMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}