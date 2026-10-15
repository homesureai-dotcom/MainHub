import 'package:flutter/material.dart';

import '../../core/evidence/assessment_evidence_summary.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_risk_signal.dart';
import '../../core/evidence/evidence_validation_result.dart';
import '../../screens/assessment/evidence_details_screen.dart';

/// Displays the most important evidence gaps that require
/// homeowner attention.
///
/// This widget intentionally consumes the existing
/// AssessmentEvidenceSummary rather than introducing a new
/// evidence model or repository.
///
/// The purpose is to transform evidence coverage from a
/// reporting metric into an actionable homeowner workflow.
class EvidenceActionCenter extends StatelessWidget {
  final AssessmentEvidenceSummary summary;

  /// Maximum number of actions shown in the compact dashboard-style view.
  final int maxItems;

  const EvidenceActionCenter({
    super.key,
    required this.summary,
    this.maxItems = 5,
  });

  List<EvidenceValidationResult> get _actionItems {
    final results = summary.validationResults
        .where((result) => result.status != EvidenceValidationStatus.satisfied)
        .toList();

    results.sort(_compareResults);

    if (results.length <= maxItems) {
      return results;
    }

    return results.take(maxItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _actionItems;

    if (items.isEmpty) {
      return _buildCompleteState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EvidenceActionItem(
                result: result,
                onTap: () => _openRequirement(context, result),
              ),
            ),
          ),
          const SizedBox(height: 4),
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
              label: Text(_viewAllLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.assignment_turned_in_outlined,
            color: Color(0xFF2563EB),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Evidence Action Center',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        _CoverageBadge(
          satisfied: summary.satisfiedRequirements,
          total: summary.totalRequirements,
        ),
      ],
    );
  }

  Widget _buildCompleteState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: Color(0xFF15803D), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evidence requirements complete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'All evidence requirements currently have '
                  'satisfied validation status.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final activeRiskCount = summary.activeRiskSignalCount;

    if (activeRiskCount > 0) {
      return '$activeRiskCount evidence '
          '${activeRiskCount == 1 ? 'item requires' : 'items require'} '
          'attention. Start with the highest-risk items.';
    }

    if (summary.needsReviewRequirements > 0) {
      return 'Some evidence has been provided but still '
          'requires review.';
    }

    if (summary.rejectedRequirements > 0) {
      return 'Some evidence items were rejected and '
          'need to be addressed.';
    }

    return 'Start by resolving the evidence requirements '
        'that are still outstanding.';
  }

  String get _viewAllLabel {
    final remaining = summary.totalRequirements - _actionItems.length;

    if (remaining > 0) {
      return 'View all evidence requirements';
    }

    return 'View evidence details';
  }

  void _openRequirement(BuildContext context, EvidenceValidationResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenceRequirementDetailScreen(result: result),
      ),
    );
  }

  static int _compareResults(
    EvidenceValidationResult first,
    EvidenceValidationResult second,
  ) {
    final firstRisk = EvidenceRiskSignal.fromValidationResult(first);

    final secondRisk = EvidenceRiskSignal.fromValidationResult(second);

    final riskComparison = _riskRank(
      secondRisk.level,
    ).compareTo(_riskRank(firstRisk.level));

    if (riskComparison != 0) {
      return riskComparison;
    }

    final statusComparison = _statusRank(
      first.status,
    ).compareTo(_statusRank(second.status));

    if (statusComparison != 0) {
      return statusComparison;
    }

    return first.requirement.label.toLowerCase().compareTo(
      second.requirement.label.toLowerCase(),
    );
  }

  static int _riskRank(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.high:
        return 0;
      case EvidenceRiskLevel.medium:
        return 1;
      case EvidenceRiskLevel.low:
        return 2;
      case EvidenceRiskLevel.none:
        return 3;
    }
  }

  static int _statusRank(EvidenceValidationStatus status) {
    switch (status) {
      case EvidenceValidationStatus.rejected:
        return 0;
      case EvidenceValidationStatus.needsReview:
        return 1;
      case EvidenceValidationStatus.missing:
        return 2;
      case EvidenceValidationStatus.provided:
        return 3;
      case EvidenceValidationStatus.satisfied:
        return 4;
    }
  }
}

class _EvidenceActionItem extends StatelessWidget {
  final EvidenceValidationResult result;
  final VoidCallback onTap;

  const _EvidenceActionItem({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final requirement = result.requirement;

    final risk = EvidenceRiskSignal.fromValidationResult(result);

    final riskColor = _riskColor(risk.level);

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _typeIcon(requirement.type),
                  color: riskColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _StatusBadge(status: result.status),
                        if (risk.hasRisk) ...[
                          const SizedBox(width: 6),
                          _RiskBadge(level: risk.level),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
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

  Color _riskColor(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.high:
        return const Color(0xFFDC2626);
      case EvidenceRiskLevel.medium:
        return const Color(0xFFD97706);
      case EvidenceRiskLevel.low:
        return const Color(0xFF2563EB);
      case EvidenceRiskLevel.none:
        return const Color(0xFF64748B);
    }
  }
}

class _CoverageBadge extends StatelessWidget {
  final int satisfied;
  final int total;

  const _CoverageBadge({required this.satisfied, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$satisfied/$total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EvidenceValidationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _colors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors.foreground,
        ),
      ),
    );
  }

  static String _label(EvidenceValidationStatus status) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return 'Missing';
      case EvidenceValidationStatus.provided:
        return 'Provided';
      case EvidenceValidationStatus.satisfied:
        return 'Satisfied';
      case EvidenceValidationStatus.needsReview:
        return 'Review';
      case EvidenceValidationStatus.rejected:
        return 'Rejected';
    }
  }

  static _BadgeColors _colors(EvidenceValidationStatus status) {
    switch (status) {
      case EvidenceValidationStatus.missing:
        return const _BadgeColors(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFB91C1C),
        );
      case EvidenceValidationStatus.provided:
        return const _BadgeColors(
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF1D4ED8),
        );
      case EvidenceValidationStatus.satisfied:
        return const _BadgeColors(
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF15803D),
        );
      case EvidenceValidationStatus.needsReview:
        return const _BadgeColors(
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFB45309),
        );
      case EvidenceValidationStatus.rejected:
        return const _BadgeColors(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFB91C1C),
        );
    }
  }
}

class _RiskBadge extends StatelessWidget {
  final EvidenceRiskLevel level;

  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _color(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(level),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  static String _label(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.high:
        return 'High Risk';
      case EvidenceRiskLevel.medium:
        return 'Review';
      case EvidenceRiskLevel.low:
        return 'Low Risk';
      case EvidenceRiskLevel.none:
        return 'No Risk';
    }
  }

  static Color _color(EvidenceRiskLevel level) {
    switch (level) {
      case EvidenceRiskLevel.high:
        return const Color(0xFFDC2626);
      case EvidenceRiskLevel.medium:
        return const Color(0xFFD97706);
      case EvidenceRiskLevel.low:
        return const Color(0xFF2563EB);
      case EvidenceRiskLevel.none:
        return const Color(0xFF64748B);
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;

  const _BadgeColors({required this.background, required this.foreground});
}
