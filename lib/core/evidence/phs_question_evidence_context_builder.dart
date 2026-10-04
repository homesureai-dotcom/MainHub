import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validator.dart';
import 'phs_question_evidence_context.dart';

/// Builds a complete evidence context for a single PHS question.
///
/// The builder centralizes the transformation from:
/// - evidence requirements
/// - supplied evidence
///
/// into the validation and risk information required by
/// [PHSQuestionEvidenceContext].
///
/// This builder does not modify PHS scoring.
class PHSQuestionEvidenceContextBuilder {
  final EvidenceValidator _validator;

  const PHSQuestionEvidenceContextBuilder({
    required EvidenceValidator validator,
  }) : _validator = validator;

  /// Builds the evidence context for one PHS question.
  ///
  /// The supplied [requirements] should belong to [questionId].
  /// The supplied [evidence] should represent evidence associated with
  /// that question.
  PHSQuestionEvidenceContext build({
    required String questionId,
    required List<EvidenceRequirement> requirements,
    required List<Evidence> evidence,
  }) {
    final validationResults = _validator.validateAll(
      requirements,
      evidence,
    );

    final riskSignals = validationResults
        .map(EvidenceRiskSignal.fromValidationResult)
        .toList(growable: false);

    return PHSQuestionEvidenceContext(
      questionId: questionId,
      requirements: requirements,
      evidence: evidence,
      validationResults: validationResults,
      riskSignals: riskSignals,
    );
  }
}