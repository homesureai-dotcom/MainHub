import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
      percent: score / 100,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: const Color(0xff22C55E),
      backgroundColor: Colors.white24,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            "$score",
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}