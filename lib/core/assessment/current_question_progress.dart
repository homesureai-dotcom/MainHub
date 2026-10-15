import 'package:flutter/material.dart';

import '../../core/phs/phs_question_progress.dart';

/// Displays the user's current position within the Property Health
/// Assessment and the current PHS pillar.
///
/// Example:
///
/// Question 14 of 33
/// Construction Quality
/// 4 of 8 questions
///
/// All calculations come from [PHSQuestionProgress].
class CurrentQuestionProgress extends StatelessWidget {
  final PHSQuestionProgress progress;

  const CurrentQuestionProgress({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgress(),
          const SizedBox(height: 16),
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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assessment Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              progress.positionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
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
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              Color(0xFF2563EB),
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
            color: const Color(0xFF2563EB)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category_outlined,
            size: 21,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                progress.categoryDisplayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress.categoryPositionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value:
                      progress.categoryCompletion,
                  minHeight: 6,
                  backgroundColor:
                      const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${progress.categoryCompletionPercentage}%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}