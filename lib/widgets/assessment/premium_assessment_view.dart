import 'package:flutter/material.dart';

import '../../core/phs/phs_categories.dart';
import '../../core/phs/phs_category_progress.dart';
import '../../core/phs/phs_assessment_progress.dart';
import '../../models/property_health/category_score.dart';

/// Premium visual presentation of the Property Health assessment.
///
/// This widget is presentation-only. It does not own assessment state,
/// answers, evidence, or navigation. Those remain in AssessmentScreen.
class PremiumAssessmentView extends StatelessWidget {
  final PHSAssessmentProgress progress;
  final List<CategoryScore> categoryScores;
  final double overallScore;
  final double assessmentCoverage;
  final PHSCategory? selectedCategory;
  final ValueChanged<PHSCategory> onCategoryTap;

  /// Builds the current question content for the selected category.
  ///
  /// AssessmentScreen supplies the actual QuestionCard, evidence controls,
  /// answer options, and navigation controls.
  final Widget Function(PHSCategory category) questionBuilder;

  const PremiumAssessmentView({
    super.key,
    required this.progress,
    required this.categoryScores,
    required this.overallScore,
    required this.assessmentCoverage,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.questionBuilder,
  });

  CategoryScore? _scoreFor(PHSCategory category) {
    for (final score in categoryScores) {
      if (score.category == category) {
        return score;
      }
    }

    return null;
  }

  PHSCategoryProgress _progressFor(PHSCategory category) {
    return progress.progressFor(category) ??
        PHSCategoryProgress(
          category: category,
          totalQuestions: 0,
          answeredQuestions: 0,
        );
  }

  bool _isAssessed(CategoryScore? score) {
    return score != null && score.maxScore > 0;
  }

  Color _scoreColor(double score) {
    if (score >= 90) {
      return const Color(0xFF34D399);
    }

    if (score >= 75) {
      return const Color(0xFF2DD4BF);
    }

    if (score >= 60) {
      return const Color(0xFFFBBF24);
    }

    if (score >= 40) {
      return const Color(0xFFFB923C);
    }

    return const Color(0xFFF87171);
  }

  String _scoreLabel(double score) {
    if (score >= 90) {
      return 'Excellent';
    }

    if (score >= 75) {
      return 'Good';
    }

    if (score >= 60) {
      return 'Needs attention';
    }

    if (score >= 40) {
      return 'At risk';
    }

    return 'Critical';
  }

  String _coverageLabel() {
    if (assessmentCoverage <= 0) {
      return 'Assessment not started';
    }

    return '${assessmentCoverage.round()}% assessed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroScore(),
            const SizedBox(height: 20),
            _buildHeatmapHeader(),
            const SizedBox(height: 12),
            ...PHSCategory.values.map(_buildCategoryCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroScore() {
    final hasAssessment = assessmentCoverage > 0;
    final scoreColor = hasAssessment
        ? _scoreColor(overallScore)
        : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172033), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 108,
                  height: 108,
                  child: CircularProgressIndicator(
                    value: hasAssessment
                        ? (overallScore / 100).clamp(0.0, 1.0)
                        : 0.0,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFF263247),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasAssessment ? overallScore.round().toString() : '--',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROPERTY HEALTH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  hasAssessment
                      ? _scoreLabel(overallScore)
                      : 'Not assessed yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _coverageLabel(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your score evolves as you complete the assessment.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property Health Map',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap a pillar to inspect its questions',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${progress.answeredQuestions}/${progress.totalQuestions}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(PHSCategory category) {
    final categoryScore = _scoreFor(category);
    final categoryProgress = _progressFor(category);

    final assessed = _isAssessed(categoryScore);
    final isSelected = selectedCategory == category;
    final score = categoryScore?.score ?? 0.0;

    final color = assessed ? _scoreColor(score) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategoryTap(category),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF18253A)
                      : const Color(0xFF111B2D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF1E293B),
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
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
                                  category.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                '${category.weight.round()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: assessed
                                  ? (score / 100).clamp(0.0, 1.0)
                                  : categoryProgress.completion,
                              minHeight: 6,
                              backgroundColor: const Color(0xFF263247),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                assessed
                                    ? '${score.round()} · ${_scoreLabel(score)}'
                                    : 'Not assessed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${categoryProgress.answeredQuestions}/${categoryProgress.totalQuestions} questions',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: isSelected ? 0.25 : 0,
                      child: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: questionBuilder(category),
            ),
        ],
      ),
    );
  }
}
