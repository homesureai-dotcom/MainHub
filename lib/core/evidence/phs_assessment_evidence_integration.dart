import '../engine/models/property_health_result.dart';
import 'phs_assessment_evidence_context.dart';

/// Combines the existing PHS assessment result with its evidence context.
///
/// This is the application-facing boundary between the PHS assessment
/// engine and the evidence subsystem.
///
/// The class intentionally does not calculate, modify, or reinterpret
/// either the PHS result or evidence state.
class PHSAssessmentEvidenceIntegration {
  final PropertyHealthResult healthResult;
  final PHSAssessmentEvidenceContext evidenceContext;

  const PHSAssessmentEvidenceIntegration({
    required this.healthResult,
    required this.evidenceContext,
  });

  bool get hasEvidenceGaps => evidenceContext.hasEvidenceGaps;

  bool get hasEvidenceRisk => evidenceContext.hasEvidenceRisk;

  bool get isEvidenceComplete => evidenceContext.isComplete;

  int get questionCount => evidenceContext.questionCount;

  int get completeQuestionCount =>
      evidenceContext.completeQuestionCount;

  int get questionsWithEvidenceGaps =>
      evidenceContext.questionsWithEvidenceGaps;

  int get questionsWithEvidenceRisk =>
      evidenceContext.questionsWithEvidenceRisk;

  PHSAssessmentEvidenceIntegration copyWith({
    PropertyHealthResult? healthResult,
    PHSAssessmentEvidenceContext? evidenceContext,
  }) {
    return PHSAssessmentEvidenceIntegration(
      healthResult: healthResult ?? this.healthResult,
      evidenceContext: evidenceContext ?? this.evidenceContext,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PHSAssessmentEvidenceIntegration &&
        other.healthResult == healthResult &&
        other.evidenceContext == evidenceContext;
  }

  @override
  int get hashCode => Object.hash(
        healthResult,
        evidenceContext,
      );

  @override
  String toString() {
    return 'PHSAssessmentEvidenceIntegration('
        'healthResult: $healthResult, '
        'questionCount: $questionCount, '
        'completeQuestionCount: $completeQuestionCount, '
        'questionsWithEvidenceGaps: '
        '$questionsWithEvidenceGaps, '
        'questionsWithEvidenceRisk: '
        '$questionsWithEvidenceRisk'
        ')';
  }
}