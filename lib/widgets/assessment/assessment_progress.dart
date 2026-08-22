import 'package:flutter/material.dart';

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
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Question $current of $total",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}