import 'phs_question_evidence_context.dart';

/// Represents the evidence state of an entire PHS assessment.
///
/// Each entry is keyed by the canonical PHS question ID.
///
/// This aggregate is intentionally focused on evidence state. It does not
/// calculate or modify the Property Health Score.
class PHSAssessmentEvidenceContext {
  final Map<String, PHSQuestionEvidenceContext> questionContexts;

  PHSAssessmentEvidenceContext({
    required Map<String, PHSQuestionEvidenceContext> questionContexts,
  }) : questionContexts = Map.unmodifiable(questionContexts);

  /// Number of PHS questions represented by this context.
  int get questionCount => questionContexts.length;

  /// Number of questions whose evidence requirements are completely
  /// satisfied.
  int get completeQuestionCount =>
      questionContexts.values.where((context) => context.isComplete).length;

  /// Number of questions that contain unresolved evidence gaps.
  int get questionsWithEvidenceGaps => questionContexts.values
      .where((context) => context.hasEvidenceGaps)
      .length;

  /// Number of questions that currently have evidence risk.
  int get questionsWithEvidenceRisk => questionContexts.values
      .where((context) => context.hasEvidenceRisk)
      .length;

  /// Returns whether every represented question has complete evidence.
  ///
  /// An empty assessment is not considered complete.
  bool get isComplete =>
      questionCount > 0 &&
      completeQuestionCount == questionCount;

  /// Returns whether at least one question has an evidence gap.
  bool get hasEvidenceGaps => questionsWithEvidenceGaps > 0;

  /// Returns whether at least one question has evidence risk.
  bool get hasEvidenceRisk => questionsWithEvidenceRisk > 0;

  /// Returns the context for a canonical PHS question ID.
  PHSQuestionEvidenceContext? getForQuestion(String questionId) {
    return questionContexts[questionId];
  }

  /// Returns whether a context exists for the supplied question ID.
  bool containsQuestion(String questionId) {
    return questionContexts.containsKey(questionId);
  }

  /// Immutable view of all question evidence contexts.
  Map<String, PHSQuestionEvidenceContext> get contexts =>
      Map.unmodifiable(questionContexts);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PHSAssessmentEvidenceContext &&
        _mapsEqual(other.questionContexts, questionContexts);
  }

  @override
  int get hashCode => Object.hashAll(
        questionContexts.entries.map(
          (entry) => Object.hash(entry.key, entry.value),
        ),
      );

  @override
  String toString() {
    return 'PHSAssessmentEvidenceContext('
        'questionCount: $questionCount, '
        'completeQuestionCount: $completeQuestionCount, '
        'questionsWithEvidenceGaps: $questionsWithEvidenceGaps, '
        'questionsWithEvidenceRisk: $questionsWithEvidenceRisk'
        ')';
  }

  static bool _mapsEqual(
    Map<String, PHSQuestionEvidenceContext> first,
    Map<String, PHSQuestionEvidenceContext> second,
  ) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;

    for (final entry in first.entries) {
      if (second[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}