import 'package:flutter/material.dart';

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
      return Colors.blueGrey;
    }

    switch (priority.priority) {
      case RecommendationPriority.critical:
        return Colors.red;
      case RecommendationPriority.high:
        return Colors.orange;
      case RecommendationPriority.medium:
        return Colors.amber.shade800;
      case RecommendationPriority.low:
        return Colors.blue;
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xff2563EB).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xff2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HomeSure AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI Property Intelligence',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'PROPERTY INTELLIGENCE',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              _scoreLabel,
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              hasScore ? _starRating(data.healthScore!) : '☆☆☆☆☆',
              style: const TextStyle(fontSize: 24, color: Colors.amber),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              _profileLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hasScore ? _statusColor(data.healthScore!) : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          if (hasPriority) ...[_priorityBadge(), const SizedBox(height: 16)],

          _info(
            Icons.warning_amber_rounded,
            _priorityColor,
            'Biggest Risk',
            _riskTitle,
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Text(
              _riskDescription,
              style: TextStyle(color: Colors.grey.shade700, height: 1.45),
            ),
          ),

          const SizedBox(height: 24),

          _info(
            Icons.lightbulb_outline,
            Colors.blue,
            'Recommended Action',
            _recommendationTitle,
          ),

          const SizedBox(height: 24),

          _info(
            Icons.trending_up,
            Colors.green,
            'Potential PHI Improvement',
            _estimatedGain,
          ),

          const SizedBox(height: 24),

          _info(
            Icons.description_outlined,
            Colors.indigo,
            'Evidence Required',
            _evidenceLabel,
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: data.healthResult == null
                  ? null
                  : () => _openFullAnalysis(context),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('View Full Property Analysis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _priorityColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _priorityColor.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 16, color: _priorityColor),
          const SizedBox(width: 6),
          Text(
            _priorityLabel,
            style: TextStyle(
              color: _priorityColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
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
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return Colors.green;
    }

    if (score >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  static Widget _info(IconData icon, Color color, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: .10),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
