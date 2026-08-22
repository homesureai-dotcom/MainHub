import 'package:flutter/material.dart';

import '../../../core/assessment/category_result.dart';
import '../../../core/phs/phs_category_metadata.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';

import '../models/property_health_report.dart';

class CategoryAnalysisCard extends StatelessWidget {
  final PropertyHealthReport report;

  const CategoryAnalysisCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final categories = report.assessment.categoryResults;

    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Category Analysis",
            subtitle:
                "Performance across the six HomeSure Property Health pillars.",
          ),

          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.lg,
              ),
              child: _CategoryTile(
                category: category,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryResult category;

  const _CategoryTile({
    required this.category,
  });

  Color _progressColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _rating(double score) {
    if (score >= 90) return "Excellent";
    if (score >= 75) return "Good";
    if (score >= 60) return "Fair";
    return "Needs Attention";
  }

  @override
  Widget build(BuildContext context) {
    final percent = category.percentage;
    final contribution =
        category.weightedContribution.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.10),
                child: Text(
                  PHSCategoryMetadata.icon(category.category),
                  style: const TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      PHSCategoryMetadata.displayName(
                        category.category,
                      ),
                      style: AppTextStyles.title,
                    ),

                    Text(
                      _rating(percent),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _progressColor(percent),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    "${percent.round()}%",
                    style: AppTextStyles.h3,
                  ),

                  Text(
                    "$contribution / ${category.weight}",
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                _progressColor(percent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}