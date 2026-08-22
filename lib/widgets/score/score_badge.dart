import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({
    super.key,
    required this.score,
  });

  String get label {
    if (score >= 85) return "Excellent";
    if (score >= 70) return "Good";
    return "Needs Attention";
  }

  Color get color {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}