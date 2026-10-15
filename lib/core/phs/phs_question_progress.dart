import 'phs_categories.dart';
import 'phs_question.dart';

/// Position and completion information for a question within the
/// Property Health Assessment and its PHS category.
class PHSQuestionProgress {
  final PHSQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final int categoryQuestionIndex;
  final int categoryQuestionCount;
  final int categoryAnsweredQuestionCount;

  const PHSQuestionProgress({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.categoryQuestionIndex,
    required this.categoryQuestionCount,
    required this.categoryAnsweredQuestionCount,
  });

  /// The PHS category containing the current question.
  PHSCategory get category => question.category;

  /// One-based question number within the complete assessment.
  int get questionNumber => questionIndex + 1;

  /// One-based question number within the current PHS pillar.
  int get categoryQuestionNumber => categoryQuestionIndex + 1;

  /// Number of questions actually answered within the current PHS pillar.
  int get categoryAnsweredQuestions =>
      categoryAnsweredQuestionCount.clamp(0, categoryQuestionCount);

  /// Number of unanswered questions remaining within the current pillar.
  int get categoryRemainingQuestions {
    final remaining = categoryQuestionCount - categoryAnsweredQuestions;

    return remaining < 0 ? 0 : remaining;
  }

  /// Overall assessment position represented by the current question.
  ///
  /// Example:
  /// Question 14 of 33 = approximately 42%.
  double get overallCompletion {
    if (totalQuestions <= 0) {
      return 0.0;
    }

    return (questionNumber / totalQuestions).clamp(0.0, 1.0);
  }

  /// Overall assessment position as a percentage.
  int get overallCompletionPercentage => (overallCompletion * 100).round();

  /// Position within the current pillar represented by the current question.
  ///
  /// Example:
  /// Question 4 of 8 in Construction Quality = 50%.
  double get categoryCompletion {
    if (categoryQuestionCount <= 0) {
      return 0.0;
    }

    return (categoryQuestionNumber / categoryQuestionCount).clamp(0.0, 1.0);
  }

  /// Current pillar position as a percentage.
  int get categoryCompletionPercentage => (categoryCompletion * 100).round();

  /// Actual answered progress within the current pillar.
  ///
  /// Example:
  /// 3 answered out of 8 = 37.5%.
  double get categoryAnsweredCompletion {
    if (categoryQuestionCount <= 0) {
      return 0.0;
    }

    return (categoryAnsweredQuestions / categoryQuestionCount).clamp(0.0, 1.0);
  }

  /// Actual answered progress within the current pillar as a percentage.
  int get categoryAnsweredCompletionPercentage =>
      (categoryAnsweredCompletion * 100).round();

  /// Whether every question in the current pillar has been answered.
  bool get isCategoryComplete =>
      categoryQuestionCount > 0 &&
      categoryAnsweredQuestions >= categoryQuestionCount;

  /// Whether the current pillar has started.
  bool get hasCategoryStarted => categoryAnsweredQuestions > 0;

  /// Display name of the current PHS pillar.
  String get categoryDisplayName => category.displayName;

  /// Description of the current PHS pillar.
  String get categoryDescription => category.description;

  /// Icon identifier configured for the current PHS pillar.
  String get categoryIcon => category.icon;

  /// Weight of the current PHS pillar in the Property Health Standard.
  double get categoryWeight => category.weight;

  /// Human-readable overall question position.
  String get positionLabel =>
      'Question $questionNumber of '
      '$totalQuestions';

  /// Human-readable position within the current pillar.
  String get categoryPositionLabel =>
      '$categoryQuestionNumber of '
      '$categoryQuestionCount questions';

  /// Human-readable actual answered progress within the pillar.
  String get categoryAnsweredLabel =>
      '$categoryAnsweredQuestions of '
      '$categoryQuestionCount answered';

  /// Combined position label useful for compact UI.
  ///
  /// Example:
  /// "Construction Quality · 4 of 8 questions"
  String get categoryProgressLabel =>
      '$categoryDisplayName · '
      '$categoryPositionLabel';

  /// Combined answer-progress label.
  ///
  /// Example:
  /// "3 of 8 answered"
  String get categoryAnsweredProgressLabel => categoryAnsweredLabel;

  /// Whether the current question is the first question
  /// in the complete assessment.
  bool get isFirstQuestion => questionIndex == 0;

  /// Whether the current question is the final question
  /// in the complete assessment.
  bool get isLastQuestion =>
      totalQuestions > 0 && questionIndex == totalQuestions - 1;

  /// Whether the current question is the first question
  /// within its PHS pillar.
  bool get isFirstQuestionInCategory => categoryQuestionIndex == 0;

  /// Whether the current question is the final question
  /// within its PHS pillar.
  bool get isLastQuestionInCategory =>
      categoryQuestionCount > 0 &&
      categoryQuestionIndex == categoryQuestionCount - 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PHSQuestionProgress &&
        other.question == question &&
        other.questionIndex == questionIndex &&
        other.totalQuestions == totalQuestions &&
        other.categoryQuestionIndex == categoryQuestionIndex &&
        other.categoryQuestionCount == categoryQuestionCount &&
        other.categoryAnsweredQuestionCount == categoryAnsweredQuestionCount;
  }

  @override
  int get hashCode => Object.hash(
    question,
    questionIndex,
    totalQuestions,
    categoryQuestionIndex,
    categoryQuestionCount,
    categoryAnsweredQuestionCount,
  );

  @override
  String toString() {
    return 'PHSQuestionProgress('
        'question: ${question.id}, '
        'questionNumber: $questionNumber/$totalQuestions, '
        'category: $category, '
        'categoryQuestionNumber: '
        '$categoryQuestionNumber/$categoryQuestionCount, '
        'categoryAnsweredQuestions: '
        '$categoryAnsweredQuestions'
        ')';
  }
}
