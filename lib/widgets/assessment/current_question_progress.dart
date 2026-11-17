import 'package:flutter/material.dart';

import '../../core/phs/phs_question_progress.dart';
import '../../core/theme/homesure_tokens.dart';

/// Displays the user's current position within the Property Health
/// Assessment and the actual completion progress of the current PHS pillar.
///
/// Example:
///
/// Question 14 of 33
/// Construction Quality
/// Question 4 of 8
/// 3 of 8 answered
///
/// The widget intentionally keeps position and completion separate:
///
/// - Question position tells the user where they currently are.
/// - Answered progress tells the user how much of the pillar is complete.
class CurrentQuestionProgress extends StatelessWidget {
  final PHSQuestionProgress progress;

  const CurrentQuestionProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeSureColors.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgress(),
          const SizedBox(height: 14),
          _buildPillarProgress(),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assessment Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HomeSureColors.slateMuted,
              ),
            ),
            Text(
              progress.positionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: HomeSureColors.champagneInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.overallCompletion,
            minHeight: 7,
            backgroundColor: HomeSureColors.midnightInteractive,
            valueColor: const AlwaysStoppedAnimation<Color>(
              HomeSureColors.champagneGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillarProgress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: HomeSureColors.midnightSand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomeSureColors.champagneBronze),
          ),
          child: const Icon(
            Icons.category_outlined,
            size: 20,
            color: HomeSureColors.champagneHighlight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.categoryDisplayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress.categoryPositionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                progress.categoryAnsweredProgressLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeSureColors.slateMuted,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.categoryAnsweredCompletion,
                  minHeight: 6,
                  backgroundColor: HomeSureColors.midnightInteractive,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    HomeSureColors.statusPositiveText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${progress.categoryAnsweredCompletionPercentage}%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: HomeSureColors.statusPositiveText,
          ),
        ),
      ],
    );
  }
}
