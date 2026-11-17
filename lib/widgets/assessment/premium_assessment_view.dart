import 'package:flutter/material.dart';

import '../../core/phs/phs_assessment_progress.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/phs/phs_category_progress.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../models/property_health/category_score.dart';
import '../../theme/app_gradients.dart';
import '../property_health/score_heatmap_legend.dart';

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
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeSureColors.borderSlate),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroScore(),
            const SizedBox(height: 18),
            _buildHeatmapHeader(),
            const SizedBox(height: 12),
            ScoreHeatmapLegend(
              score: assessmentCoverage > 0 ? overallScore : null,
            ),
            const SizedBox(height: 16),
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
        : HomeSureColors.slateMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeSureColors.champagneBronze),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: hasAssessment
                        ? (overallScore / 100).clamp(0.0, 1.0)
                        : 0.0,
                    strokeWidth: 9,
                    backgroundColor: HomeSureColors.midnightInteractive,
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
                        color: HomeSureColors.champagneHighlight,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: HomeSureColors.slateMuted,
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
                    color: HomeSureColors.champagneHighlight,
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
                    color: HomeSureColors.champagneInk,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your score evolves as you complete the assessment.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: HomeSureColors.slateMuted,
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
                  color: HomeSureColors.champagneInk,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap a pillar to inspect its questions',
                style: TextStyle(
                  fontSize: 12,
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HomeSureColors.borderSlate),
          ),
          child: Text(
            '${progress.answeredQuestions}/${progress.totalQuestions}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: HomeSureColors.champagneHighlight,
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

    final color = assessed ? _scoreColor(score) : HomeSureColors.slateMuted;

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
                      ? HomeSureColors.midnightSelected
                      : HomeSureColors.midnightDetail,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? HomeSureColors.champagneGold
                        : HomeSureColors.borderSlate,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
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
                                    color: HomeSureColors.champagneInk,
                                  ),
                                ),
                              ),
                              Text(
                                '${category.weight.round()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: HomeSureColors.slateMuted,
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
                              backgroundColor:
                                  HomeSureColors.midnightInteractive,
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
                                  color: HomeSureColors.slateMuted,
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
                        color: HomeSureColors.champagneHighlight,
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
