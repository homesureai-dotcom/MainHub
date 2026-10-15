import 'phs_answer.dart';
import 'phs_categories.dart';
import 'phs_question.dart';

/// Resolves which question should be opened when a user
/// selects a PHS category.
///
/// The resolver intentionally works only with PHS domain models.
/// It does not depend on Flutter or navigation.
class PHSCategoryQuestionResolver {
  const PHSCategoryQuestionResolver();

  /// Returns the first unanswered question belonging to [category].
  ///
  /// If every question in the category has already been answered,
  /// the first question in the category is returned.
  ///
  /// If the category contains no questions, returns null.
  PHSQuestion? resolve({
    required PHSCategory category,
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
  }) {
    final categoryQuestions = questions
        .where((question) => question.category == category)
        .toList();

    if (categoryQuestions.isEmpty) {
      return null;
    }

    final answeredQuestionIds = answers
        .map((answer) => answer.questionId)
        .toSet();

    for (final question in categoryQuestions) {
      if (!answeredQuestionIds.contains(question.id)) {
        return question;
      }
    }

    return categoryQuestions.first;
  }

  /// Returns the index of the resolved question
  /// within the original [questions] list.
  ///
  /// Returns null when the category has no questions.
  int? resolveIndex({
    required PHSCategory category,
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
  }) {
    final question = resolve(
      category: category,
      questions: questions,
      answers: answers,
    );

    if (question == null) {
      return null;
    }

    final index = questions.indexWhere(
      (candidate) => candidate.id == question.id,
    );

    return index >= 0 ? index : null;
  }
}
