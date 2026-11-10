import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../../features/dashboard/models/dashboard_data.dart';
import '../../features/dashboard/models/dashboard_priority.dart';
import '../../models/property_health/recommendation.dart';
import '../../screens/assessment/property_health_result_screen.dart';
import '../app_card.dart';

class AIInsightsCard extends StatelessWidget {
  final DashboardData data;

  const AIInsightsCard({super.key, required this.data});

  DashboardPriority? get _topPriority {
    if (data.priorities.isEmpty) {
      return null;
    }

    return data.priorities.first;
  }

  String get _scoreLabel {
    final score = data.healthScore;

    if (score == null) {
      return 'Not Assessed';
    }

    return '${score.round()}%';
  }

  String get _profileLabel {
    final grade = data.healthGrade;

    if (grade == null) {
      return 'Complete your assessment';
    }

    return grade;
  }

  String get _riskTitle {
    final priority = _topPriority;

    if (priority == null) {
      if (!data.hasAssessment) {
        return 'Assessment required';
      }

      return 'No immediate actions identified';
    }

    return priority.title;
  }

  String get _riskDescription {
    final priority = _topPriority;

    if (priority == null) {
      if (!data.hasAssessment) {
        return 'Complete your property assessment to identify the most important risks and actions.';
      }

      return 'Your current assessment has not generated any actionable recommendations.';
    }

    return priority.description;
  }

  String get _recommendationTitle {
    final priority = _topPriority;

    if (priority == null) {
      if (!data.hasAssessment) {
        return 'Start your property assessment';
      }

      return 'Continue monitoring your property';
    }

    return priority.title;
  }

  String get _estimatedGain {
    final priority = _topPriority;

    if (priority == null) {
      return '—';
    }

    if (priority.estimatedPHIGain <= 0) {
      return 'No score improvement estimated';
    }

    return '+${priority.estimatedPHIGain} PHI points';
  }

  String get _priorityLabel {
    final priority = _topPriority;

    if (priority == null) {
      return 'INFO';
    }

    switch (priority.priority) {
      case RecommendationPriority.critical:
        return 'CRITICAL';
      case RecommendationPriority.high:
        return 'HIGH PRIORITY';
      case RecommendationPriority.medium:
        return 'MEDIUM PRIORITY';
      case RecommendationPriority.low:
        return 'LOW PRIORITY';
    }
  }

  Color get _priorityColor {
    final priority = _topPriority;

    if (priority == null) {
      return HomeSureColors.textSecondary;
    }

    switch (priority.priority) {
      case RecommendationPriority.critical:
        return HomeSureColors.statusCriticalText;
      case RecommendationPriority.high:
        return HomeSureColors.statusWarningText;
      case RecommendationPriority.medium:
        return HomeSureColors.primaryNavy;
      case RecommendationPriority.low:
        return HomeSureColors.accentTealDark;
    }
  }

  String get _evidenceLabel {
    final priority = _topPriority;

    if (priority == null || priority.requiredDocuments.isEmpty) {
      return 'No additional evidence specified';
    }

    return priority.requiredDocuments.join(', ');
  }

  void _openFullAnalysis(BuildContext context) {
    final result = data.healthResult;

    if (result == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyHealthResultScreen(
          result: result,
          evidenceSummary: data.evidenceSummary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = data.healthScore != null;
    final priority = _topPriority;
    final hasPriority = priority != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HomeSureColors.accentTealTint,
                  borderRadius: BorderRadius.circular(HomeSureRadius.md),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: HomeSureColors.accentTealDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HomeSure AI',
                      style: HomeSureTypography.sectionTitle,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AI Property Intelligence',
                      style: HomeSureTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HomeSureColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(HomeSureRadius.md),
              border: Border.all(color: HomeSureColors.borderDivider),
            ),
            child: Column(
              children: [
                const Text(
                  'PROPERTY INTELLIGENCE',
                  style: HomeSureTypography.eyebrow,
                ),
                const SizedBox(height: 8),
                Text(
                  _scoreLabel,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: HomeSureColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasScore ? _starRating(data.healthScore!) : '☆☆☆☆☆',
                  style: const TextStyle(
                    fontSize: 18,
                    color: HomeSureColors.statusWarningText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _profileLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasScore
                        ? _statusColor(data.healthScore!)
                        : HomeSureColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (hasPriority) ...[_priorityBadge(), const SizedBox(height: 14)],
          _info(
            Icons.warning_amber_rounded,
            _priorityColor,
            'Biggest Risk',
            _riskTitle,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              _riskDescription,
              style: HomeSureTypography.bodySecondary,
            ),
          ),
          const SizedBox(height: 16),
          _info(
            Icons.lightbulb_outline,
            HomeSureColors.primaryNavy,
            'Recommended Action',
            _recommendationTitle,
          ),
          const SizedBox(height: 16),
          _info(
            Icons.trending_up,
            HomeSureColors.statusPositiveText,
            'Potential PHI Improvement',
            _estimatedGain,
          ),
          const SizedBox(height: 16),
          _info(
            Icons.description_outlined,
            HomeSureColors.accentTealDark,
            'Evidence Required',
            _evidenceLabel,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: data.healthResult == null
                  ? null
                  : () => _openFullAnalysis(context),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('View Full Property Analysis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _priorityColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(HomeSureRadius.pill),
        border: Border.all(color: _priorityColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 14, color: _priorityColor),
          const SizedBox(width: 5),
          Text(
            _priorityLabel,
            style: TextStyle(
              color: _priorityColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  static String _starRating(double score) {
    final filledStars = (score / 20).round().clamp(0, 5);
    return List.generate(5, (index) => index < filledStars ? '★' : '☆').join();
  }

  static Color _statusColor(double score) {
    if (score >= 75) {
      return HomeSureColors.statusPositiveText;
    }
    if (score >= 60) {
      return HomeSureColors.statusWarningText;
    }
    return HomeSureColors.statusCriticalText;
  }

  static Widget _info(IconData icon, Color color, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(HomeSureRadius.sm),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HomeSureTypography.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: HomeSureTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
