import 'package:flutter/material.dart';

import '../../core/evidence/assessment_evidence_summary.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_risk_signal.dart';
import '../../core/evidence/evidence_validation_result.dart';

class EvidenceDetailsScreen extends StatefulWidget {
  final AssessmentEvidenceSummary summary;

  const EvidenceDetailsScreen({
    super.key,
    required this.summary,
  });

  @override
  State<EvidenceDetailsScreen> createState() =>
      _EvidenceDetailsScreenState();
}

class _EvidenceDetailsScreenState
    extends State<EvidenceDetailsScreen> {
  EvidenceDetailsFilter _selectedFilter =
      EvidenceDetailsFilter.all;

  List<EvidenceValidationResult> get _filteredResults {
    final results = widget.summary.validationResults;

    switch (_selectedFilter) {
      case EvidenceDetailsFilter.all:
        return results;

      case EvidenceDetailsFilter.satisfied:
        return results
            .where(
              (result) =>
                  result.status ==
                  EvidenceValidationStatus.satisfied,
            )
            .toList();

      case EvidenceDetailsFilter.missing:
        return results
            .where(
              (result) =>
                  result.status ==
                  EvidenceValidationStatus.missing,
            )
            .toList();

      case EvidenceDetailsFilter.provided:
        return results
            .where(
              (result) =>
                  result.status ==
                  EvidenceValidationStatus.provided,
            )
            .toList();

      case EvidenceDetailsFilter.needsReview:
        return results
            .where(
              (result) =>
                  result.status ==
                  EvidenceValidationStatus.needsReview,
            )
            .toList();

      case EvidenceDetailsFilter.rejected:
        return results
            .where(
              (result) =>
                  result.status ==
                  EvidenceValidationStatus.rejected,
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Evidence Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          children: [
            _SummaryHeader(
              summary: summary,
            ),
            const SizedBox(height: 20),
            _FilterSection(
              selectedFilter: _selectedFilter,
              summary: summary,
              onChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_filteredResults.isEmpty)
              const _EmptyState()
            else
              ..._filteredResults.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _EvidenceRequirementCard(
                    result: result,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum EvidenceDetailsFilter {
  all,
  satisfied,
  provided,
  needsReview,
  missing,
  rejected,
}

class _SummaryHeader extends StatelessWidget {
  final AssessmentEvidenceSummary summary;

  const _SummaryHeader({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        summary.coveragePercentage.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidence Coverage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: summary.totalRequirements == 0
                  ? 0
                  : summary.coveragePercentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.satisfiedRequirements} of '
            '${summary.totalRequirements} requirements satisfied',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final EvidenceDetailsFilter selectedFilter;
  final AssessmentEvidenceSummary summary;
  final ValueChanged<EvidenceDetailsFilter> onChanged;

  const _FilterSection({
    required this.selectedFilter,
    required this.summary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                count: summary.totalRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.all,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.all,
                ),
              ),
              _FilterChip(
                label: 'Satisfied',
                count: summary.satisfiedRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.satisfied,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.satisfied,
                ),
              ),
              _FilterChip(
                label: 'Provided',
                count: summary.providedRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.provided,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.provided,
                ),
              ),
              _FilterChip(
                label: 'Needs Review',
                count: summary.needsReviewRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.needsReview,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.needsReview,
                ),
              ),
              _FilterChip(
                label: 'Missing',
                count: summary.missingRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.missing,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.missing,
                ),
              ),
              _FilterChip(
                label: 'Rejected',
                count: summary.rejectedRequirements,
                selected:
                    selectedFilter ==
                        EvidenceDetailsFilter.rejected,
                onTap: () => onChanged(
                  EvidenceDetailsFilter.rejected,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          '$label ($count)',
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EvidenceRequirementCard extends StatelessWidget {
  final EvidenceValidationResult result;

  const _EvidenceRequirementCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = result.requirement;
    final risk =
        EvidenceRiskSignal.fromValidationResult(result);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EvidenceRequirementDetailScreen(
              result: result,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    requirement.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(
                  status: result.status,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Question: ${requirement.questionId}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _typeIcon(requirement.type),
                  size: 17,
                  color: const Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  _typeLabel(requirement.type),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (risk.hasRisk)
                  Row(
                    children: [
                      Icon(
                        _riskIcon(risk.level),
                        size: 17,
                        color: _riskColor(risk.level),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _riskLabel(risk.level),
                        style: TextStyle(
                          fontSize: 12,
                          color: _riskColor(risk.level),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.document:
        return Icons.description_outlined;
      case EvidenceType.photograph:
        return Icons.photo_camera_outlined;
      case EvidenceType.video:
        return Icons.videocam_outlined;
      case EvidenceType.manual:
        return Icons.edit_note_outlined;
    }
  }

  String _typeLabel(EvidenceType type) {
    switch (type) {
      case EvidenceType.document:
        return 'Document';
      case EvidenceType.photograph:
        return 'Photograph';
      case EvidenceType.video:
        return 'Video';
      case EvidenceType.manual:
        return 'Manual';
    }
  }

  IconData _riskIcon(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return Icons.check_circle_outline;
      case EvidenceRiskLevel.low:
        return Icons.info_outline;
      case EvidenceRiskLevel.medium:
        return Icons.warning_amber_outlined;
      case EvidenceRiskLevel.high:
        return Icons.error_outline;
    }
  }

  Color _riskColor(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return const Color(0xFF16A34A);
      case EvidenceRiskLevel.low:
        return const Color(0xFF2563EB);
      case EvidenceRiskLevel.medium:
        return const Color(0xFFD97706);
      case EvidenceRiskLevel.high:
        return const Color(0xFFDC2626);
    }
  }

  String _riskLabel(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return 'No risk';
      case EvidenceRiskLevel.low:
        return 'Low risk';
      case EvidenceRiskLevel.medium:
        return 'Review';
      case EvidenceRiskLevel.high:
        return 'High risk';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final EvidenceValidationStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _foregroundColor(status),
        ),
      ),
    );
  }

  String _label(EvidenceValidationStatus status) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return 'Missing';
      case EvidenceValidationStatus.provided:
        return 'Provided';
      case EvidenceValidationStatus.satisfied:
        return 'Satisfied';
      case EvidenceValidationStatus.needsReview:
        return 'Needs Review';
      case EvidenceValidationStatus.rejected:
        return 'Rejected';
    }
  }

  Color _backgroundColor(
    EvidenceValidationStatus status,
  ) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return const Color(0xFFFEE2E2);
      case EvidenceValidationStatus.provided:
        return const Color(0xFFDBEAFE);
      case EvidenceValidationStatus.satisfied:
        return const Color(0xFFDCFCE7);
      case EvidenceValidationStatus.needsReview:
        return const Color(0xFFFEF3C7);
      case EvidenceValidationStatus.rejected:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _foregroundColor(
    EvidenceValidationStatus status,
  ) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return const Color(0xFFB91C1C);
      case EvidenceValidationStatus.provided:
        return const Color(0xFF1D4ED8);
      case EvidenceValidationStatus.satisfied:
        return const Color(0xFF15803D);
      case EvidenceValidationStatus.needsReview:
        return const Color(0xFFB45309);
      case EvidenceValidationStatus.rejected:
        return const Color(0xFFB91C1C);
    }
  }
}

class EvidenceRequirementDetailScreen
    extends StatelessWidget {
  final EvidenceValidationResult result;

  const EvidenceRequirementDetailScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = result.requirement;
    final risk =
        EvidenceRiskSignal.fromValidationResult(result);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Requirement Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.label,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Question',
                    value: requirement.questionId,
                  ),
                  _DetailRow(
                    label: 'Evidence Type',
                    value: _typeLabel(requirement.type),
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: _statusLabel(result.status),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    result.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evidence Risk',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _riskIcon(risk.level),
                        color: _riskColor(risk.level),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _riskLabel(risk.level),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _riskColor(risk.level),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    risk.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(
    EvidenceValidationStatus status,
  ) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return 'Missing';
      case EvidenceValidationStatus.provided:
        return 'Provided';
      case EvidenceValidationStatus.satisfied:
        return 'Satisfied';
      case EvidenceValidationStatus.needsReview:
        return 'Needs Review';
      case EvidenceValidationStatus.rejected:
        return 'Rejected';
    }
  }

  String _typeLabel(EvidenceType type) {
    switch (type) {
      case EvidenceType.document:
        return 'Document';
      case EvidenceType.photograph:
        return 'Photograph';
      case EvidenceType.video:
        return 'Video';
      case EvidenceType.manual:
        return 'Manual';
    }
  }

  IconData _riskIcon(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return Icons.check_circle_outline;
      case EvidenceRiskLevel.low:
        return Icons.info_outline;
      case EvidenceRiskLevel.medium:
        return Icons.warning_amber_outlined;
      case EvidenceRiskLevel.high:
        return Icons.error_outline;
    }
  }

  Color _riskColor(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return const Color(0xFF16A34A);
      case EvidenceRiskLevel.low:
        return const Color(0xFF2563EB);
      case EvidenceRiskLevel.medium:
        return const Color(0xFFD97706);
      case EvidenceRiskLevel.high:
        return const Color(0xFFDC2626);
    }
  }

  String _riskLabel(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.none:
        return 'No active risk';
      case EvidenceRiskLevel.low:
        return 'Low risk';
      case EvidenceRiskLevel.medium:
        return 'Review required';
      case EvidenceRiskLevel.high:
        return 'High risk';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 42,
            color: Color(0xFF64748B),
          ),
          SizedBox(height: 12),
          Text(
            'No requirements found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'There are no evidence requirements for this filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}