import 'evidence_validation_result.dart';

/// Represents the overall evidence coverage for a set of
/// evidence requirements.
///
/// This model summarizes evidence validation results without
/// modifying or influencing the PHS score.
class EvidenceCoverage {
  /// Total number of evidence requirements evaluated.
  final int totalRequirements;

  /// Number of requirements whose evidence is fully satisfied.
  final int satisfiedRequirements;

  /// Number of requirements with evidence supplied but not verified.
  final int providedRequirements;

  /// Number of requirements that require additional review.
  final int needsReviewRequirements;

  /// Number of requirements for which evidence is missing.
  final int missingRequirements;

  /// Number of requirements whose evidence was rejected.
  final int rejectedRequirements;

  /// Percentage of requirements that are fully satisfied.
  ///
  /// Returns 0 when there are no requirements.
  final double coveragePercentage;

  const EvidenceCoverage({
    required this.totalRequirements,
    required this.satisfiedRequirements,
    required this.providedRequirements,
    required this.needsReviewRequirements,
    required this.missingRequirements,
    required this.rejectedRequirements,
    required this.coveragePercentage,
  });

  /// Whether every evidence requirement is fully satisfied.
  bool get isComplete =>
      totalRequirements > 0 &&
      satisfiedRequirements == totalRequirements;

  /// Whether at least one requirement is not fully satisfied.
  bool get hasEvidenceGaps =>
      missingRequirements > 0 ||
      providedRequirements > 0 ||
      needsReviewRequirements > 0 ||
      rejectedRequirements > 0;

  /// Calculates overall evidence coverage from validation results.
  ///
  /// Only `satisfied` requirements contribute to the coverage
  /// percentage. Provided, needs-review, missing, and rejected
  /// requirements do not count as fully covered.
  static EvidenceCoverage calculate(
    List<EvidenceValidationResult> results,
  ) {
    final total = results.length;

    if (total == 0) {
      return const EvidenceCoverage(
        totalRequirements: 0,
        satisfiedRequirements: 0,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 0,
      );
    }

    var satisfied = 0;
    var provided = 0;
    var needsReview = 0;
    var missing = 0;
    var rejected = 0;

    for (final result in results) {
      switch (result.status) {
        case EvidenceValidationStatus.satisfied:
          satisfied++;
          break;

        case EvidenceValidationStatus.provided:
          provided++;
          break;

        case EvidenceValidationStatus.needsReview:
          needsReview++;
          break;

        case EvidenceValidationStatus.missing:
          missing++;
          break;

        case EvidenceValidationStatus.rejected:
          rejected++;
          break;
      }
    }

    return EvidenceCoverage(
      totalRequirements: total,
      satisfiedRequirements: satisfied,
      providedRequirements: provided,
      needsReviewRequirements: needsReview,
      missingRequirements: missing,
      rejectedRequirements: rejected,
      coveragePercentage: (satisfied / total) * 100,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceCoverage &&
        other.totalRequirements == totalRequirements &&
        other.satisfiedRequirements == satisfiedRequirements &&
        other.providedRequirements == providedRequirements &&
        other.needsReviewRequirements == needsReviewRequirements &&
        other.missingRequirements == missingRequirements &&
        other.rejectedRequirements == rejectedRequirements &&
        other.coveragePercentage == coveragePercentage;
  }

  @override
  int get hashCode => Object.hash(
        totalRequirements,
        satisfiedRequirements,
        providedRequirements,
        needsReviewRequirements,
        missingRequirements,
        rejectedRequirements,
        coveragePercentage,
      );

  @override
  String toString() {
    return 'EvidenceCoverage('
        'totalRequirements: $totalRequirements, '
        'satisfiedRequirements: $satisfiedRequirements, '
        'providedRequirements: $providedRequirements, '
        'needsReviewRequirements: $needsReviewRequirements, '
        'missingRequirements: $missingRequirements, '
        'rejectedRequirements: $rejectedRequirements, '
        'coveragePercentage: $coveragePercentage'
        ')';
  }
}