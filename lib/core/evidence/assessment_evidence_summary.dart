import 'evidence_category_coverage.dart';
import 'evidence_coverage.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validation_result.dart';

/// Provides a UI/report-friendly summary of evidence for an assessment.
///
/// This model contains derived evidence information only.
/// It does not contain or modify the Property Health Score.
class AssessmentEvidenceSummary {
  final EvidenceCoverage overallCoverage;
  final List<EvidenceValidationResult> validationResults;
  final List<EvidenceRiskSignal> riskSignals;
  final List<EvidenceCategoryCoverage> categoryCoverage;

  const AssessmentEvidenceSummary({
    required this.overallCoverage,
    required this.validationResults,
    required this.riskSignals,
    required this.categoryCoverage,
  });

  /// Number of evidence requirements in the assessment.
  int get totalRequirements =>
      overallCoverage.totalRequirements;

  /// Number of evidence requirements that are fully satisfied.
  int get satisfiedRequirements =>
      overallCoverage.satisfiedRequirements;

  /// Number of requirements with evidence that is provided but not verified.
  int get providedRequirements =>
      overallCoverage.providedRequirements;

  /// Number of requirements whose evidence needs review.
  int get needsReviewRequirements =>
      overallCoverage.needsReviewRequirements;

  /// Number of requirements with no matching evidence.
  int get missingRequirements =>
      overallCoverage.missingRequirements;

  /// Number of requirements whose evidence was rejected.
  int get rejectedRequirements =>
      overallCoverage.rejectedRequirements;

  /// Overall percentage of satisfied evidence requirements.
  double get coveragePercentage =>
      overallCoverage.coveragePercentage;

  /// Whether every evidence requirement is satisfied.
  bool get isComplete =>
      overallCoverage.isComplete;

  /// Whether the assessment contains any evidence gaps.
  bool get hasEvidenceGaps =>
      overallCoverage.hasEvidenceGaps;

  /// Number of risk signals generated for the assessment.
  int get riskSignalCount => riskSignals.length;

  /// Number of risk signals that represent an actual evidence risk.
  int get activeRiskSignalCount =>
      riskSignals.where((signal) => signal.hasRisk).length;

  /// Whether any evidence risk requires attention.
  bool get hasEvidenceRisk =>
      riskSignals.any((signal) => signal.hasRisk);

  /// Returns an immutable copy of the validation results.
  List<EvidenceValidationResult> get results =>
      List.unmodifiable(validationResults);

  /// Returns an immutable copy of the risk signals.
  List<EvidenceRiskSignal> get risks =>
      List.unmodifiable(riskSignals);

  /// Returns an immutable copy of the category coverage.
  List<EvidenceCategoryCoverage> get categories =>
      List.unmodifiable(categoryCoverage);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AssessmentEvidenceSummary &&
        other.overallCoverage == overallCoverage &&
        _listEquals(
          other.validationResults,
          validationResults,
        ) &&
        _listEquals(
          other.riskSignals,
          riskSignals,
        ) &&
        _listEquals(
          other.categoryCoverage,
          categoryCoverage,
        );
  }

  @override
  int get hashCode => Object.hash(
        overallCoverage,
        Object.hashAll(validationResults),
        Object.hashAll(riskSignals),
        Object.hashAll(categoryCoverage),
      );

  @override
  String toString() {
    return 'AssessmentEvidenceSummary('
        'totalRequirements: $totalRequirements, '
        'satisfiedRequirements: $satisfiedRequirements, '
        'providedRequirements: $providedRequirements, '
        'needsReviewRequirements: $needsReviewRequirements, '
        'missingRequirements: $missingRequirements, '
        'rejectedRequirements: $rejectedRequirements, '
        'coveragePercentage: $coveragePercentage, '
        'riskSignalCount: $riskSignalCount, '
        'activeRiskSignalCount: $activeRiskSignalCount'
        ')';
  }

  static bool _listEquals<T>(
    List<T> first,
    List<T> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}