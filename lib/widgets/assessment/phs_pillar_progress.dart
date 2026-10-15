import 'package:flutter/material.dart';

import '../../core/phs/phs_assessment_progress.dart';
import '../../core/phs/phs_category_progress.dart';
import '../../core/phs/phs_categories.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          ...PHSCategory.values.map((category) {
            final categoryProgress = progress.progressFor(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
            color: const Color(0xFF2563EB).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: Color(0xFF2563EB),
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
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completed of $total pillars complete',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${progress.categoryCompletionPercentage}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
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
        ? const Color(0xFF16A34A)
        : isActive
        ? const Color(0xFF2563EB)
        : const Color(0xFF94A3B8);

    final row = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
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
                          color: Color(0xFF1E293B),
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
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildSupportingText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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
                color: Color(0xFF94A3B8),
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
