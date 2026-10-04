import 'phs_assessment_evidence_context.dart';
import 'phs_question_evidence_context.dart';

/// Builds an assessment-level evidence context from the already-built
/// evidence contexts for individual PHS questions.
///
/// This builder only aggregates question contexts. It does not perform
/// evidence validation and does not modify or calculate the PHS score.
class PHSAssessmentEvidenceContextBuilder {
  const PHSAssessmentEvidenceContextBuilder();

  /// Builds an assessment evidence context from the supplied question
  /// evidence contexts.
  ///
  /// The resulting map is keyed by each question context's canonical
  /// question ID.
  PHSAssessmentEvidenceContext build(
    List<PHSQuestionEvidenceContext> questionContexts,
  ) {
    return PHSAssessmentEvidenceContext(
      questionContexts: {
        for (final context in questionContexts)
          context.questionId: context,
      },
    );
  }
}