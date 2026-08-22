import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/app_status_chip.dart';
import '../models/property_health_report.dart';

class AIInsightsCard extends StatelessWidget {
  final PropertyHealthReport report;

  const AIInsightsCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final int currentScore = report.assessment.overallScore.round();

    final int potentialScore = ((currentScore +
            report.recommendations.fold<int>(
              0,
              (sum, item) => sum + item.expectedScoreIncrease,
            ))
        .clamp(0, 100))
        .toInt();

    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "SureBot AI",
            subtitle:
                "AI-generated insights based on your Property Health Assessment",
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      child: Icon(Icons.smart_toy),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "SureBot Analysis",
                        style: AppTextStyles.title,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  "Based on your assessment, your property has a solid foundation. Completing the recommended actions below can significantly improve your Property Health Score.",
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: _ScoreCard(
                        title: "Current Score",
                        value: "$currentScore",
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward),
                    ),

                    Expanded(
                      child: _ScoreCard(
                        title: "Potential Score",
                        value: "$potentialScore",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                const AppStatusChip(
                  label: "94% Confidence",
                  status: StatusType.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          const Text(
            "Key Insights",
            style: AppTextStyles.title,
          ),

          const SizedBox(height: AppSpacing.md),

          if (report.aiInsights.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "No AI insights available.",
                style: AppTextStyles.body,
              ),
            )
          else
            ...report.aiInsights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                ),
                child: _InsightTile(
                  insight: insight,
                ),
              ),
            ),

          const Divider(height: 40),

          const Text(
            "Recommended Next Action",
            style: AppTextStyles.title,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            report.recommendations.isEmpty
                ? "No further action required."
                : report.recommendations.first.title,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String insight;

  const _InsightTile({
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb,
            color: Colors.amber,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              insight,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final String value;

  const _ScoreCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h2,
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}