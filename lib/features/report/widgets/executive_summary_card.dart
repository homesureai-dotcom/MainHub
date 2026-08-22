import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/property_health_gauge.dart';
import '../components/executive_summary/executive_summary_component.dart';

class ExecutiveSummaryCard extends StatelessWidget {
  final ExecutiveSummaryComponent summary;

  const ExecutiveSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Executive Summary",
            subtitle:
                "A high-level overview of your property's current health.",
          ),

          Center(
            child: PropertyHealthGauge(
              score: summary.propertyHealthIndex,
              status: summary.propertyStatus,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            summary.summary,
            style: AppTextStyles.body,
          ),

          const SizedBox(height: AppSpacing.xl),

          const Divider(),

          const SizedBox(height: AppSpacing.lg),

          _SummaryRow(
            label: "Overall Health",
            value: summary.propertyStatus,
          ),

          const SizedBox(height: AppSpacing.md),

          _SummaryRow(
            label: "Strongest Area",
            value: summary.strongestArea,
          ),

          const SizedBox(height: AppSpacing.md),

          _SummaryRow(
            label: "Needs Attention",
            value: summary.weakestArea,
          ),

          const SizedBox(height: AppSpacing.md),

          _SummaryRow(
            label: "Potential Score Gain",
            value: "+${summary.estimatedImprovement} Points",
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.title,
            ),
          ),
        ],
      ),
    );
  }
}