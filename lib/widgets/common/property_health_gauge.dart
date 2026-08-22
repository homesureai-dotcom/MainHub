import 'package:flutter/material.dart';

class PropertyHealthGauge extends StatelessWidget {
  final int score;
  final int maxScore;
  final double size;
  final String status;

  const PropertyHealthGauge({
    super.key,
    required this.score,
    required this.status,
    this.maxScore = 100,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [

          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFE8EEF8),
              valueColor: AlwaysStoppedAnimation(
                _scoreColor(score),
              ),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "PROPERTY HEALTH",
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "$score",
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(score).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 90) return Colors.green;

    if (score >= 75) return Colors.lightGreen;

    if (score >= 60) return Colors.orange;

    if (score >= 40) return Colors.deepOrange;

    return Colors.red;
  }
}