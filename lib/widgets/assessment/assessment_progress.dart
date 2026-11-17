import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AssessmentProgress extends StatelessWidget {
  final int current;
  final int total;

  const AssessmentProgress({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'Question $current of $total',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: HomeSureColors.champagneInk,
          ),
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: HomeSureColors.midnightInteractive,
            color: HomeSureColors.champagneGold,
          ),
        ),
      ],
    );
  }
}