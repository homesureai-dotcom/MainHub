import 'evidence_coverage.dart';
import 'evidence_requirement.dart';
import 'evidence_validation_result.dart';

/// Represents evidence coverage for one PHS category.
class EvidenceCategoryCoverage {
  /// The PHS category name.
  final String categoryId;

  /// Total evidence requirements in this category.
  final int totalRequirements;

  /// Fully satisfied requirements.
  final int satisfiedRequirements;

  /// Requirements with evidence supplied but not verified.
  final int providedRequirements;

  /// Requirements requiring additional review.
  final int needsReviewRequirements;

  /// Requirements with no supplied evidence.
  final int missingRequirements;

  /// Requirements whose evidence was rejected.
  final int rejectedRequirements;

  /// Percentage of requirements fully satisfied.
  final double coveragePercentage;

  const EvidenceCategoryCoverage({
    required this.categoryId,
    required this.totalRequirements,
    required this.satisfiedRequirements,
    required this.providedRequirements,
    required this.needsReviewRequirements,
    required this.missingRequirements,
    required this.rejectedRequirements,
    required this.coveragePercentage,
  });

  /// Whether every requirement in this category is satisfied.
  bool get isComplete =>
      totalRequirements > 0 &&
      satisfiedRequirements == totalRequirements;

  /// Whether this category contains any evidence gap.
  bool get hasEvidenceGaps =>
      providedRequirements > 0 ||
      needsReviewRequirements > 0 ||
      missingRequirements > 0 ||
      rejectedRequirements > 0;

  /// Creates category coverage from validation results.
  static EvidenceCategoryCoverage calculate({
    required String categoryId,
    required List<EvidenceValidationResult> results,
  }) {
    final coverage = EvidenceCoverage.calculate(results);

    return EvidenceCategoryCoverage(
      categoryId: categoryId,
      totalRequirements: coverage.totalRequirements,
      satisfiedRequirements: coverage.satisfiedRequirements,
      providedRequirements: coverage.providedRequirements,
      needsReviewRequirements: coverage.needsReviewRequirements,
      missingRequirements: coverage.missingRequirements,
      rejectedRequirements: coverage.rejectedRequirements,
      coveragePercentage: coverage.coveragePercentage,
    );
  }

  /// Creates category coverage directly from requirements and their
  /// validation results.
  ///
  /// The requirements parameter is used to preserve the explicit
  /// relationship between category requirements and validation results.
  static EvidenceCategoryCoverage calculateForRequirements({
    required String categoryId,
    required List<EvidenceRequirement> requirements,
    required List<EvidenceValidationResult> results,
  }) {
    final requirementIds = requirements
        .map(
          (requirement) => EvidenceRequirementKey.fromRequirement(
            requirement,
          ),
        )
        .toSet();

    final filteredResults = results
        .where(
          (result) => requirementIds.contains(
            EvidenceRequirementKey.fromRequirement(
              result.requirement,
            ),
          ),
        )
        .toList(growable: false);

    return calculate(
      categoryId: categoryId,
      results: filteredResults,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceCategoryCoverage &&
        other.categoryId == categoryId &&
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
        categoryId,
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
    return 'EvidenceCategoryCoverage('
        'categoryId: $categoryId, '
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

/// Internal stable identity for an evidence requirement.
class EvidenceRequirementKey {
  final String questionId;
  final String label;

  const EvidenceRequirementKey({
    required this.questionId,
    required this.label,
  });

  factory EvidenceRequirementKey.fromRequirement(
    EvidenceRequirement requirement,
  ) {
    return EvidenceRequirementKey(
      questionId: requirement.questionId,
      label: requirement.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceRequirementKey &&
        other.questionId == questionId &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(
        questionId,
        label,
      );
}