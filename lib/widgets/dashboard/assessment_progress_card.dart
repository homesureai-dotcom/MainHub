import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AssessmentProgressCard extends StatelessWidget {
  final int completedQuestions;
  final int totalQuestions;
  final double completionPercentage;
  final int completedCategories;
  final int totalCategories;

  const AssessmentProgressCard({
    super.key,
    required this.completedQuestions,
    required this.totalQuestions,
    required this.completionPercentage,
    required this.completedCategories,
    required this.totalCategories,
  });

  @override
  Widget build(BuildContext context) {
    final hasStarted = completedQuestions > 0;
    final progress = completionPercentage.clamp(0.0, 100.0) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HomeSureColors.accentTealTint,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: HomeSureColors.accentTealDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assessment Progress',
                  style: HomeSureTypography.cardTitle,
                ),
              ),
              if (hasStarted)
                Text(
                  '${completionPercentage.round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HomeSureColors.accentTealDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasStarted)
            const Text(
              'Your property health assessment has not started yet.',
              style: HomeSureTypography.bodySecondary,
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completedQuestions',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: HomeSureColors.textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 2),
                  child: Text(
                    'of $totalQuestions questions completed',
                    style: HomeSureTypography.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(HomeSureRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: HomeSureColors.surfaceSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HomeSureColors.accentTeal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedCategories of $totalCategories categories started',
              style: HomeSureTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}
