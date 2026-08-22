import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import '../../theme/app_text_styles.dart';

class AppScoreBadge extends StatelessWidget {
  final int score;

  const AppScoreBadge({
    super.key,
    required this.score,
  });

  String get grade {
    if (score >= 90) return "EXCELLENT";
    if (score >= 80) return "GOOD";
    if (score >= 70) return "FAIR";
    return "NEEDS ATTENTION";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Text(
        "$score • $grade",
        style: AppTextStyles.button,
      ),
    );
  }
}