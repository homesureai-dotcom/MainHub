import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class ScoreCircle extends StatelessWidget {
  final int score;

  const ScoreCircle({
    super.key,
    required this.score,
  });

  Color get scoreColor {
    if (score >= 85) return HomeSureColors.statusPositiveText;
    if (score >= 70) return HomeSureColors.champagneHighlight;
    return HomeSureColors.statusCriticalText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeSureColors.midnightCard,
        border: Border.all(
          color: scoreColor,
          width: 7,
        ),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              '$score',
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: HomeSureColors.champagneInk,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'HomeSure Score™',
              style: TextStyle(
                color: HomeSureColors.champagneHighlight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}