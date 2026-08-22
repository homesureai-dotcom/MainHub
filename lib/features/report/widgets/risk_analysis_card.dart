import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/app_status_chip.dart';

import '../models/property_health_report.dart';

class RiskAnalysisCard extends StatelessWidget {
  final PropertyHealthReport report;

  const RiskAnalysisCard({
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
            title: "Risk Analysis",
            subtitle:
                "Potential issues identified during the assessment.",
          ),

          if (report.risks.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 32,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      "Excellent! No significant property risks were detected.",
                      style: AppTextStyles.title,
                    ),
                  ),
                ],
              ),
            )
          else
            ...report.risks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                ),
                child: _RiskTile(
                  risk: risk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final ReportRisk risk;

  const _RiskTile({
    required this.risk,
  });

  Color get color {
    switch (risk.severity) {
      case RiskSeverity.low:
        return Colors.green;

      case RiskSeverity.medium:
        return Colors.orange;

      case RiskSeverity.high:
        return Colors.deepOrange;

      case RiskSeverity.critical:
        return Colors.red;
    }
  }

  StatusType get status {
    switch (risk.severity) {
      case RiskSeverity.low:
        return StatusType.success;

      case RiskSeverity.medium:
        return StatusType.warning;

      case RiskSeverity.high:
      case RiskSeverity.critical:
        return StatusType.danger;
    }
  }

  IconData get icon {
    switch (risk.severity) {
      case RiskSeverity.low:
        return Icons.check_circle;

      case RiskSeverity.medium:
        return Icons.warning_amber;

      case RiskSeverity.high:
        return Icons.error_outline;

      case RiskSeverity.critical:
        return Icons.dangerous;
    }
  }

  String get label {
    switch (risk.severity) {
      case RiskSeverity.low:
        return "Low Risk";

      case RiskSeverity.medium:
        return "Medium Risk";

      case RiskSeverity.high:
        return "High Risk";

      case RiskSeverity.critical:
        return "Critical Risk";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.title,
                  style: AppTextStyles.title,
                ),

                const SizedBox(height: AppSpacing.xs),

                AppStatusChip(
                  label: label,
                  status: status,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  risk.description,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}