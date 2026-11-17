import 'package:flutter/material.dart';

import '../../core/phs/phs_assessment_progress.dart';
import '../../core/phs/phs_category_progress.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/theme/homesure_tokens.dart';

class PHSAssessmentPillarProgress extends StatelessWidget {
  final PHSAssessmentProgress progress;
  final ValueChanged<PHSCategory>? onCategoryTap;

  const PHSAssessmentPillarProgress({
    super.key,
    required this.progress,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderSlate),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          ...PHSCategory.values.map((category) {
            final categoryProgress = progress.progressFor(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PHSCategoryProgressRow(
                progress:
                    categoryProgress ??
                    PHSCategoryProgress(
                      category: category,
                      totalQuestions: 0,
                      answeredQuestions: 0,
                    ),
                isCurrent: progress.currentCategory == category,
                isActive: progress.activeCategory == category,
                onTap: onCategoryTap == null
                    ? null
                    : () => onCategoryTap!(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final completed = progress.completedCategoryCount;

    final total = progress.totalCategoryCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HomeSureColors.midnightSand,
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
            border: Border.all(color: HomeSureColors.champagneBronze),
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: HomeSureColors.champagneHighlight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Property Health Pillars',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: HomeSureColors.champagneInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completed of $total pillars complete',
                style: const TextStyle(
                  fontSize: 13,
                  color: HomeSureColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: HomeSureColors.midnightInteractive,
            borderRadius: BorderRadius.circular(HomeSureRadius.pill),
            border: Border.all(color: HomeSureColors.borderSlate),
          ),
          child: Text(
            '${progress.categoryCompletionPercentage}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: HomeSureColors.champagneHighlight,
            ),
          ),
        ),
      ],
    );
  }
}

class _PHSCategoryProgressRow extends StatelessWidget {
  final PHSCategoryProgress progress;
  final bool isCurrent;
  final bool isActive;
  final VoidCallback? onTap;

  const _PHSCategoryProgressRow({
    required this.progress,
    required this.isCurrent,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = progress.isComplete;

    final hasQuestions = progress.totalQuestions > 0;

    final statusColor = isComplete
        ? HomeSureColors.statusPositiveText
        : isActive
        ? HomeSureColors.champagneGold
        : HomeSureColors.slateMuted;

    final row = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? HomeSureColors.midnightSelected
            : HomeSureColors.midnightDetail,
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        border: Border.all(
          color: isCurrent
              ? HomeSureColors.champagneGold
              : HomeSureColors.borderSlate,
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(
            color: statusColor,
            isComplete: isComplete,
            hasQuestions: hasQuestions,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HomeSureColors.champagneInk,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: HomeSureColors.champagneGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: HomeSureColors.midnightBg,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.completion,
                    minHeight: 6,
                    backgroundColor: HomeSureColors.midnightInteractive,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildSupportingText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: HomeSureColors.slateMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${progress.completionPercentage}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: HomeSureColors.slateMuted,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: row,
      ),
    );
  }

  Widget _buildStatusIcon({
    required Color color,
    required bool isComplete,
    required bool hasQuestions,
  }) {
    IconData icon;

    if (isComplete) {
      icon = Icons.check;
    } else if (isActive) {
      icon = Icons.arrow_forward;
    } else if (!hasQuestions) {
      icon = Icons.remove;
    } else {
      icon = Icons.circle_outlined;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _buildSupportingText() {
    if (progress.totalQuestions <= 0) {
      return 'No questions in this assessment';
    }

    if (progress.isComplete) {
      return '${progress.totalQuestions} '
          '${progress.totalQuestions == 1 ? 'question' : 'questions'} complete';
    }

    if (progress.answeredQuestions == 0) {
      return '${progress.totalQuestions} '
          '${progress.totalQuestions == 1 ? 'question' : 'questions'} to complete';
    }

    return '${progress.answeredQuestions} of '
        '${progress.totalQuestions} questions';
  }
}
