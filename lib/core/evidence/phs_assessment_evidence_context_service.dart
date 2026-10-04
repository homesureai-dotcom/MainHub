import '../phs/phs_question.dart';
import 'phs_assessment_evidence_context.dart';
import 'phs_assessment_evidence_context_builder.dart';
import 'phs_question_evidence_context.dart';
import 'phs_question_evidence_context_service.dart';

/// Builds assessment-level evidence context by coordinating the
/// already-established question-level evidence contexts.
///
/// This service does not perform evidence validation itself and does not
/// calculate or modify PHS scoring.
class PHSAssessmentEvidenceContextService {
  final PHSQuestionEvidenceContextService _questionContextService;
  final PHSAssessmentEvidenceContextBuilder _builder;

    const PHSAssessmentEvidenceContextService({
    required this._questionContextService,
    required this._builder,
  });

  /// Builds evidence context for all supplied PHS questions.
  Future<PHSAssessmentEvidenceContext> buildForQuestions(
    List<PHSQuestion> questions,
  ) async {
    final questionContexts = <PHSQuestionEvidenceContext>[];

    for (final question in questions) {
      final context =
          await _questionContextService.buildForQuestion(question);

      questionContexts.add(context);
    }

    return _builder.build(questionContexts);
  }

  /// Builds evidence context for a single question and wraps it at
  /// assessment level.
  Future<PHSAssessmentEvidenceContext> buildForQuestion(
    PHSQuestion question,
  ) async {
    final context =
        await _questionContextService.buildForQuestion(question);

    return _builder.build([context]);
  }

  /// Loads question-level evidence contexts without building the
  /// assessment-level aggregate.
  Future<List<PHSQuestionEvidenceContext>> buildQuestionContexts(
    List<PHSQuestion> questions,
  ) async {
    final contexts = <PHSQuestionEvidenceContext>[];

    for (final question in questions) {
      final context =
          await _questionContextService.buildForQuestion(question);

      contexts.add(context);
    }

    return List.unmodifiable(contexts);
  }
}