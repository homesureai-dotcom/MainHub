import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validation_result.dart';

/// Represents the complete evidence state for a single PHS question.
///
/// This context brings together the canonical evidence requirements,
/// supplied evidence, validation results, and evidence risk signals for
/// one PHS question.
///
/// It is intentionally independent of PHS scoring. Evidence may inform
/// assessment completeness and risk, but it does not modify the existing
/// PHS score calculation.
class PHSQuestionEvidenceContext {
  final String questionId;
  final List<EvidenceRequirement> requirements;
  final List<Evidence> evidence;
  final List<EvidenceValidationResult> validationResults;
  final List<EvidenceRiskSignal> riskSignals;

  const PHSQuestionEvidenceContext({
    required this.questionId,
    required this.requirements,
    required this.evidence,
    required this.validationResults,
    required this.riskSignals,
  });

  /// Number of evidence requirements defined for the question.
  int get totalRequirements => requirements.length;

  /// Number of evidence requirements that are satisfied.
  int get satisfiedRequirements =>
      validationResults.where((result) => result.isSatisfied).length;

  /// Number of requirements that are still missing.
  int get missingRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.missing,
      )
      .length;

  /// Number of requirements that have been provided but are not yet
  /// satisfied.
  int get providedRequirements => validationResults
      .where(
        (result) =>
            result.status == EvidenceValidationStatus.provided,
      )
      .length;

  /// Number of requirements that require review.
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

  /// Returns whether every evidence requirement is satisfied.
  bool get isComplete =>
      totalRequirements > 0 &&
      satisfiedRequirements == totalRequirements;

  /// Returns whether the question has any unresolved evidence gaps.
  bool get hasEvidenceGaps =>
      missingRequirements > 0 ||
      providedRequirements > 0 ||
      needsReviewRequirements > 0 ||
      rejectedRequirements > 0;

  /// Number of active evidence risk signals.
  int get activeRiskSignalCount =>
      riskSignals.where((signal) => signal.hasRisk).length;

  /// Returns whether the question currently has evidence risk.
  bool get hasEvidenceRisk => activeRiskSignalCount > 0;

  /// Immutable view of the evidence requirements.
  List<EvidenceRequirement> get evidenceRequirements =>
      List.unmodifiable(requirements);

  /// Immutable view of supplied evidence.
  List<Evidence> get suppliedEvidence => List.unmodifiable(evidence);

  /// Immutable view of validation results.
  List<EvidenceValidationResult> get validations =>
      List.unmodifiable(validationResults);

  /// Immutable view of evidence risk signals.
  List<EvidenceRiskSignal> get risks =>
      List.unmodifiable(riskSignals);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PHSQuestionEvidenceContext &&
        other.questionId == questionId &&
        _listEquals(other.requirements, requirements) &&
        _listEquals(other.evidence, evidence) &&
        _listEquals(other.validationResults, validationResults) &&
        _listEquals(other.riskSignals, riskSignals);
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
    return 'PHSQuestionEvidenceContext('
        'questionId: $questionId, '
        'requirements: ${requirements.length}, '
        'evidence: ${evidence.length}, '
        'validations: ${validationResults.length}, '
        'riskSignals: ${riskSignals.length}'
        ')';
  }

  static bool _listEquals<T>(List<T> first, List<T> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }

    return true;
  }
}