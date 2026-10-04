import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_requirement_matcher.dart';

/// Represents the evidence coverage for a collection of requirements.
///
/// Completeness is deliberately separate from PHS scoring. It describes
/// how many evidence requirements have matching supplied evidence.
class EvidenceCompleteness {
  /// Total number of evidence requirements.
  final int totalRequirements;

  /// Number of requirements that have at least one matching evidence item.
  final int matchedRequirements;

  /// Number of requirements without matching evidence.
  final int missingRequirements;

  /// Percentage of requirements with matching evidence.
  ///
  /// Returns 0 when there are no requirements.
  final double coveragePercentage;

  const EvidenceCompleteness({
    required this.totalRequirements,
    required this.matchedRequirements,
    required this.missingRequirements,
    required this.coveragePercentage,
  });

  /// Whether every evidence requirement has a matching evidence item.
  bool get isComplete =>
      totalRequirements > 0 &&
      matchedRequirements == totalRequirements;

  /// Whether at least one evidence requirement is missing.
  bool get hasMissingEvidence => missingRequirements > 0;

  /// Calculates evidence completeness for [requirements] against
  /// the supplied [evidence].
  static EvidenceCompleteness calculate({
    required List<EvidenceRequirement> requirements,
    required List<Evidence> evidence,
    EvidenceRequirementMatcher matcher =
        const EvidenceRequirementMatcher(),
  }) {
    final total = requirements.length;

    if (total == 0) {
      return const EvidenceCompleteness(
        totalRequirements: 0,
        matchedRequirements: 0,
        missingRequirements: 0,
        coveragePercentage: 0,
      );
    }

    final matched = requirements
        .where(
          (requirement) => matcher.hasMatch(
            requirement,
            evidence,
          ),
        )
        .length;

    final missing = total - matched;
    final coverage = (matched / total) * 100;

    return EvidenceCompleteness(
      totalRequirements: total,
      matchedRequirements: matched,
      missingRequirements: missing,
      coveragePercentage: coverage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceCompleteness &&
        other.totalRequirements == totalRequirements &&
        other.matchedRequirements == matchedRequirements &&
        other.missingRequirements == missingRequirements &&
        other.coveragePercentage == coveragePercentage;
  }

  @override
  int get hashCode => Object.hash(
        totalRequirements,
        matchedRequirements,
        missingRequirements,
        coveragePercentage,
      );

  @override
  String toString() {
    return 'EvidenceCompleteness('
        'totalRequirements: $totalRequirements, '
        'matchedRequirements: $matchedRequirements, '
        'missingRequirements: $missingRequirements, '
        'coveragePercentage: $coveragePercentage'
        ')';
  }
}