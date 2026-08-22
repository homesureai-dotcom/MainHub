import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/app_status_chip.dart';

import '../models/property_health_report.dart';

class RecommendationsCard extends StatelessWidget {
  final PropertyHealthReport report;

  const RecommendationsCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Recommendations",
            subtitle:
                "Actions that will improve your Property Health Score.",
          ),

          if (report.recommendations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                "No recommendations available.",
                style: AppTextStyles.body,
              ),
            )
          else
            ...report.recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                ),
                child: _RecommendationTile(
                  recommendation: recommendation,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final ReportRecommendation recommendation;

  const _RecommendationTile({
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final bool highPriority =
        recommendation.expectedScoreIncrease >= 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primary.withValues(alpha: .10),
                child: const Icon(
                  Icons.rocket_launch,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Text(
                  recommendation.title,
                  style: AppTextStyles.title,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            recommendation.description,
            style: AppTextStyles.body,
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.green,
              ),

              const SizedBox(width: 8),

              Text(
                "+${recommendation.expectedScoreIncrease} Score",
                style: AppTextStyles.label.copyWith(
                  color: Colors.green,
                ),
              ),

              const Spacer(),

              AppStatusChip(
                label: highPriority
                    ? "High Priority"
                    : "Medium Priority",
                status: highPriority
                    ? StatusType.danger
                    : StatusType.warning,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 8),

              Text(
                recommendation.estimatedTimeline,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}