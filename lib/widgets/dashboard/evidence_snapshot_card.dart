import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../../features/dashboard/models/dashboard_data.dart';
import '../app_card.dart';

class EvidenceSnapshotCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onViewDetails;

  const EvidenceSnapshotCard({
    super.key,
    required this.data,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvidence = data.hasEvidenceSummary;
    final coverage = data.evidenceCoveragePercentage.clamp(0.0, 100.0);
    final coverageProgress = coverage / 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeSureColors.primaryNavyTint,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: HomeSureColors.primaryNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence Snapshot',
                      style: HomeSureTypography.sectionTitle,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Supporting documents and proof',
                      style: HomeSureTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasEvidence)
            const _NoEvidenceState()
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${coverage.round()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: HomeSureColors.textPrimary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 4),
                  child: Text(
                    'coverage',
                    style: HomeSureTypography.bodySecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(HomeSureRadius.pill),
              child: LinearProgressIndicator(
                value: coverageProgress,
                minHeight: 7,
                backgroundColor: HomeSureColors.surfaceSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HomeSureColors.accentTeal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _EvidenceMetric(
                    value: data.satisfiedEvidenceRequirements,
                    label: 'Satisfied',
                    icon: Icons.check_circle_outline,
                    iconColor: HomeSureColors.statusPositiveText,
                  ),
                ),
                Expanded(
                  child: _EvidenceMetric(
                    value: data.evidenceNeedsReviewCount,
                    label: 'Review',
                    icon: Icons.rate_review_outlined,
                    iconColor: HomeSureColors.statusWarningText,
                  ),
                ),
                Expanded(
                  child: _EvidenceMetric(
                    value: data.missingEvidenceCount,
                    label: 'Missing',
                    icon: Icons.help_outline,
                    iconColor: HomeSureColors.statusCriticalText,
                  ),
                ),
              ],
            ),
            if (data.rejectedEvidenceCount > 0) ...[
              const SizedBox(height: 12),
              _RejectedEvidenceNotice(
                count: data.rejectedEvidenceCount,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text('View Evidence Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoEvidenceState extends StatelessWidget {
  const _NoEvidenceState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.upload_file_outlined,
            color: HomeSureColors.textSecondary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No evidence has been added yet. Add supporting documents, photographs, videos, or other evidence to strengthen your assessment.',
              style: HomeSureTypography.bodySecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceMetric extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _EvidenceMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 19,
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HomeSureColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: HomeSureTypography.caption,
        ),
      ],
    );
  }
}

class _RejectedEvidenceNotice extends StatelessWidget {
  final int count;

  const _RejectedEvidenceNotice({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: HomeSureColors.statusCriticalBg,
        borderRadius: BorderRadius.circular(HomeSureRadius.sm),
        border: Border.all(color: HomeSureColors.statusCriticalBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: HomeSureColors.statusCriticalText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count evidence ${count == 1 ? 'item needs' : 'items need'} attention.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: HomeSureColors.statusCriticalText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
