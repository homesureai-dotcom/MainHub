import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validation_result.dart';

/// Provides a question-level view of evidence for a PHS question.
///
/// This model contains evidence information only and does not modify
/// or contribute to the Property Health Score.
class QuestionEvidenceSummary {
  final String questionId;
  final List<EvidenceRequirement> requirements;
  final List<Evidence> evidence;
  final List<EvidenceValidationResult> validationResults;
  final List<EvidenceRiskSignal> riskSignals;

  const QuestionEvidenceSummary({
    required this.questionId,
    required this.requirements,
    required this.evidence,
    required this.validationResults,
    required this.riskSignals,
  });

  /// Number of evidence requirements for this question.
  int get totalRequirements => requirements.length;

  /// Number of requirements that are fully satisfied.
  int get satisfiedRequirements => validationResults
      .where((result) => result.isSatisfied)
      .length;

  /// Number of requirements that have no matching evidence.
  int get missingRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.missing,
      )
      .length;

  /// Number of requirements with evidence that has been provided
  /// but is not yet verified.
  int get providedRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.provided,
      )
      .length;

  /// Number of requirements whose evidence needs review.
  int get needsReviewRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.needsReview,
      )
      .length;

  /// Number of requirements whose evidence was rejected.
  int get rejectedRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.rejected,
      )
      .length;

  /// Whether every requirement for this question is satisfied.
  bool get isComplete =>
      totalRequirements > 0 &&
      satisfiedRequirements == totalRequirements;

  /// Whether this question has any evidence gap.
  bool get hasEvidenceGaps =>
      missingRequirements > 0 ||
      providedRequirements > 0 ||
      needsReviewRequirements > 0 ||
      rejectedRequirements > 0;

  /// Number of risk signals associated with this question.
  int get riskSignalCount => riskSignals.length;

  /// Number of active evidence risks.
  int get activeRiskSignalCount =>
      riskSignals.where((signal) => signal.hasRisk).length;

  /// Whether this question has an evidence risk requiring attention.
  bool get hasEvidenceRisk =>
      riskSignals.any((signal) => signal.hasRisk);

  /// Returns an immutable copy of the requirements.
  List<EvidenceRequirement> get evidenceRequirements =>
      List.unmodifiable(requirements);

  /// Returns an immutable copy of the evidence.
  List<Evidence> get suppliedEvidence =>
      List.unmodifiable(evidence);

  /// Returns an immutable copy of the validation results.
  List<EvidenceValidationResult> get validations =>
      List.unmodifiable(validationResults);

  /// Returns an immutable copy of the risk signals.
  List<EvidenceRiskSignal> get risks =>
      List.unmodifiable(riskSignals);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is QuestionEvidenceSummary &&
        other.questionId == questionId &&
        _listEquals(
          other.requirements,
          requirements,
        ) &&
        _listEquals(
          other.evidence,
          evidence,
        ) &&
        _listEquals(
          other.validationResults,
          validationResults,
        ) &&
        _listEquals(
          other.riskSignals,
          riskSignals,
        );
  }

  @override
  int get hashCode => Object.hash(
        questionId,
        Object.hashAll(requirements),
        Object.hashAll(evidence),
        Object.hashAll(validationResults),
        Object.hashAll(riskSignals),
      );

  @override
  String toString() {
    return 'QuestionEvidenceSummary('
        'questionId: $questionId, '
        'totalRequirements: $totalRequirements, '
        'satisfiedRequirements: $satisfiedRequirements, '
        'providedRequirements: $providedRequirements, '
        'needsReviewRequirements: $needsReviewRequirements, '
        'missingRequirements: $missingRequirements, '
        'rejectedRequirements: $rejectedRequirements, '
        'evidenceCount: ${evidence.length}, '
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