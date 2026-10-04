import 'package:flutter/material.dart';

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence Snapshot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Supporting documents and proof',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!hasEvidence)
            const _NoEvidenceState()
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${coverage.round()}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    left: 6,
                    bottom: 5,
                  ),
                  child: Text(
                    'coverage',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: coverageProgress,
                minHeight: 9,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _EvidenceMetric(
                    value: data.satisfiedEvidenceRequirements,
                    label: 'Satisfied',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: _EvidenceMetric(
                    value: data.evidenceNeedsReviewCount,
                    label: 'Review',
                    icon: Icons.rate_review_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _EvidenceMetric(
                    value: data.missingEvidenceCount,
                    label: 'Missing',
                    icon: Icons.help_outline,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            ),
            if (data.rejectedEvidenceCount > 0) ...[
              const SizedBox(height: 14),
              _RejectedEvidenceNotice(
                count: data.rejectedEvidenceCount,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.upload_file_outlined,
            color: Color(0xFF64748B),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No evidence has been added yet. Add supporting documents, photographs, videos, or other evidence to strengthen your assessment.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
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
          size: 21,
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
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
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count evidence ${count == 1 ? 'item needs' : 'items need'} attention.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}