import 'phs_question.dart';
import 'phs_question_progress.dart';

/// Resolves the position and completion state of a question within the
/// complete Property Health Assessment and its PHS category.
class PHSQuestionProgressResolver {
  const PHSQuestionProgressResolver();

  /// Resolves [questionId] into its overall assessment position,
  /// position within its PHS category, and actual answered progress.
  ///
  /// [answeredQuestionIds] contains the IDs of questions that have
  /// already been answered.
  ///
  /// Returns null when the question ID does not exist in [questions].
  PHSQuestionProgress? resolve({
    required String questionId,
    required List<PHSQuestion> questions,
    Set<String> answeredQuestionIds = const {},
  }) {
    final questionIndex = questions.indexWhere(
      (question) => question.id == questionId,
    );

    if (questionIndex < 0) {
      return null;
    }

    final question = questions[questionIndex];

    final categoryQuestionIndexes = <int>[];

    for (var index = 0; index < questions.length; index++) {
      if (questions[index].category == question.category) {
        categoryQuestionIndexes.add(index);
      }
    }

    final categoryQuestionIndex = categoryQuestionIndexes.indexOf(
      questionIndex,
    );

    if (categoryQuestionIndex < 0) {
      return null;
    }

    final categoryQuestionCount = categoryQuestionIndexes.length;

    final categoryAnsweredQuestionCount = categoryQuestionIndexes
        .where((index) => answeredQuestionIds.contains(questions[index].id))
        .length;

    return PHSQuestionProgress(
      question: question,
      questionIndex: questionIndex,
      totalQuestions: questions.length,
      categoryQuestionIndex: categoryQuestionIndex,
      categoryQuestionCount: categoryQuestionCount,
      categoryAnsweredQuestionCount: categoryAnsweredQuestionCount,
    );
  }
}
