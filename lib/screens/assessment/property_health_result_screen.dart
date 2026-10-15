import 'package:flutter/material.dart';

import '../../core/engine/models/property_health_result.dart';
import '../../core/evidence/assessment_evidence_summary.dart';
import '../../core/phs/phs_categories.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/property_health/evidence_action_center.dart';
import '../../widgets/property_health/property_risk_card.dart';
import '../../widgets/property_health/recommendation_card.dart';
import '../../widgets/score/score_badge.dart';
import '../../widgets/score/score_breakdown_card.dart';
import '../../widgets/score/score_circle.dart';
import '../home_screen_v2.dart';
import 'evidence_details_screen.dart';

class PropertyHealthResultScreen extends StatelessWidget {
  final PropertyHealthResult result;
  final AssessmentEvidenceSummary? evidenceSummary;

  const PropertyHealthResultScreen({
    super.key,
    required this.result,
    this.evidenceSummary,
  });

  @override
  Widget build(BuildContext context) {
    final categoryEntries = result.categoryScores.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Property Health'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // -------------------------------------------------
              // Header
              // -------------------------------------------------
              Center(
                child: Text(
                  result.hasFinalScore
                      ? 'PROPERTY HEALTH INDEX™'
                      : 'PROPERTY HEALTH ASSESSMENT',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // -------------------------------------------------
              // Score / Partial Score
              // -------------------------------------------------
              if (result.hasFinalScore) ...[
                Center(child: ScoreCircle(score: result.overallScore.round())),

                const SizedBox(height: 20),

                Center(child: ScoreBadge(score: result.overallScore.round())),
              ] else ...[
                const _PartialScoreCard(),
              ],

              const SizedBox(height: 20),

              Center(
                child: Text(
                  result.hasFinalScore
                      ? 'Your Property Health Score is ready.'
                      : 'Your complete six-pillar Property Health Score '
                            'will be available after all PHS categories are evaluated.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // -------------------------------------------------
              // Assessment Progress
              // -------------------------------------------------
              _AssessmentProgressCard(
                evaluated: result.evaluatedQuestionCount,
                total: result.totalQuestionCount,
                percentage: result.questionCompletionPercentage,
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // PHS Pillar Coverage
              // -------------------------------------------------
              _CategoryCoverageCard(
                evaluated: result.evaluatedCategoryCount,
                total: result.totalCategoryCount,
                percentage: result.categoryCompletionPercentage,
              ),

              if (evidenceSummary != null) ...[
                const SizedBox(height: 18),

                // -------------------------------------------------
                // Evidence Coverage
                // -------------------------------------------------
                _EvidenceCoverageCard(summary: evidenceSummary!),

                const SizedBox(height: 18),

                // -------------------------------------------------
                // Evidence Action Center
                // -------------------------------------------------
                EvidenceActionCenter(summary: evidenceSummary!),
              ],

              const SizedBox(height: 32),

              // -------------------------------------------------
              // Category Scores
              // -------------------------------------------------
              Text(
                'Category Scores',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              if (categoryEntries.isEmpty)
                const _EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No category scores yet',
                  message:
                      'Category scores will appear as assessment '
                      'questions are evaluated.',
                )
              else
                ...categoryEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScoreBreakdownCard(
                      title: entry.key.displayName,
                      score: entry.value.round(),
                    ),
                  ),
                ),

              // -------------------------------------------------
              // Risks
              // -------------------------------------------------
              const SizedBox(height: 28),

              Text(
                'Risks Identified',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              if (result.risks.isEmpty)
                const _EmptyState(
                  icon: Icons.verified_outlined,
                  title: 'No significant risks identified',
                  message:
                      'No risks have been generated by the rules '
                      'evaluated so far.',
                )
              else
                ...result.risks.map(
                  (risk) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PropertyRiskCard(risk: risk),
                  ),
                ),

              // -------------------------------------------------
              // Recommendations
              // -------------------------------------------------
              const SizedBox(height: 28),

              Text(
                'Recommended Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              if (result.recommendations.isEmpty)
                const _EmptyState(
                  icon: Icons.task_alt_outlined,
                  title: 'No immediate actions',
                  message:
                      'No recommendations have been generated by '
                      'the rules evaluated so far.',
                )
              else
                ...result.recommendations.map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PropertyHealthRecommendationCard(
                      recommendation: recommendation,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // -------------------------------------------------
              // Dashboard
              // -------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Continue to Dashboard',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreenV2()),
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the assessment-level evidence coverage.
class _EvidenceCoverageCard extends StatelessWidget {
  final AssessmentEvidenceSummary summary;

  const _EvidenceCoverageCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percentage = summary.coveragePercentage.clamp(0, 100).toDouble();

    final isComplete = summary.isComplete;

    final hasRisk = summary.hasEvidenceRisk;

    final Color accentColor;
    final Color backgroundColor;
    final Color borderColor;
    final IconData icon;

    if (isComplete) {
      accentColor = const Color(0xFF15803D);
      backgroundColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      icon = Icons.verified_outlined;
    } else if (hasRisk) {
      accentColor = const Color(0xFFB45309);
      backgroundColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      icon = Icons.warning_amber_rounded;
    } else {
      accentColor = const Color(0xFF2563EB);
      backgroundColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      icon = Icons.fact_check_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Evidence Coverage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            '${summary.satisfiedRequirements} of '
            '${summary.totalRequirements} evidence requirements satisfied',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isComplete
                  ? const Color(0xFF166534)
                  : const Color(0xFF92400E),
            ),
          ),

          if (summary.providedRequirements > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${summary.providedRequirements} provided but not yet verified',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],

          if (summary.needsReviewRequirements > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${summary.needsReviewRequirements} evidence items need review',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],

          if (summary.missingRequirements > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${summary.missingRequirements} evidence requirements missing',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],

          if (summary.rejectedRequirements > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${summary.rejectedRequirements} evidence requirements rejected',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],

          if (hasRisk) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${summary.activeRiskSignalCount} evidence risk'
                    '${summary.activeRiskSignalCount == 1 ? '' : 's'} '
                    'require attention.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (isComplete) ...[
            const SizedBox(height: 12),
            Text(
              'All evidence requirements are satisfied.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EvidenceDetailsScreen(summary: summary),
                  ),
                );
              },
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('View Evidence Details'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displayed when the six-pillar PHS is not yet available.
class _PartialScoreCard extends StatelessWidget {
  const _PartialScoreCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.blue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Final Property Health Score',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pending complete PHS assessment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We have evaluated the available categories, '
              'but the final HomeSure Property Health Index '
              'requires all six PHS pillars.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays question-level assessment completion.
class _AssessmentProgressCard extends StatelessWidget {
  final int evaluated;
  final int total;
  final double percentage;

  const _AssessmentProgressCard({
    required this.evaluated,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (percentage / 100.0).clamp(0.0, 1.0).toDouble();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rounded, color: Colors.blue),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Assessment Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '$evaluated / $total',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.round()}% of questions evaluated',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays how many of the six PHS pillars have been evaluated.
class _CategoryCoverageCard extends StatelessWidget {
  final int evaluated;
  final int total;
  final double percentage;

  const _CategoryCoverageCard({
    required this.evaluated,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (percentage / 100.0).clamp(0.0, 1.0).toDouble();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: Colors.indigo),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'PHS Pillar Coverage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '$evaluated / $total',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.round()}% of PHS pillars evaluated',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic empty-state card.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
