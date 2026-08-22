import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/app_status_chip.dart';

import '../models/property_health_report.dart';


class MissingDocumentsCard extends StatelessWidget {
  final PropertyHealthReport report;

  const MissingDocumentsCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final mandatoryCount = report.missingDocuments
        .where((e) => e.mandatory)
        .length;

    final optionalCount = report.missingDocuments
        .where((e) => !e.mandatory)
        .length;

    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: "Missing Documents",
            subtitle:
                "${report.missingDocuments.length} document(s) require your attention.",
          ),

          if (report.missingDocuments.isEmpty)
            Container(
              width: double.infinity,
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
                      "Excellent! All required property documents are available.",
                      style: AppTextStyles.title,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    title: "Mandatory",
                    value: mandatoryCount.toString(),
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: _SummaryTile(
                    title: "Optional",
                    value: optionalCount.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            ...report.missingDocuments.map(
              (document) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                ),
                child: _DocumentTile(
                  document: document,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final MissingDocument document;

  const _DocumentTile({
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        document.mandatory ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: .20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .10),
            child: Icon(
              document.mandatory
                  ? Icons.warning_amber_rounded
                  : Icons.description_outlined,
              color: color,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: AppTextStyles.title,
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  document.mandatory
                      ? "Required to improve compliance."
                      : "Recommended supporting document.",
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          AppStatusChip(
            label: document.mandatory
                ? "Mandatory"
                : "Optional",
            status: document.mandatory
                ? StatusType.danger
                : StatusType.warning,
          ),
        ],
      ),
    );
  }
}