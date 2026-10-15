import 'phs_categories.dart';
import 'phs_question.dart';

/// Progress information for one Property Health Standard category.
///
/// This model is intentionally independent of Flutter so it can be reused
/// by the assessment screen, dashboard, reports and future AI experiences.
class PHSCategoryProgress {
  final PHSCategory category;
  final int totalQuestions;
  final int answeredQuestions;

  const PHSCategoryProgress({
    required this.category,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  /// Number of unanswered questions in this category.
  int get remainingQuestions {
    final remaining = totalQuestions - answeredQuestions;

    return remaining < 0 ? 0 : remaining;
  }

  /// Completion percentage as a value between 0.0 and 1.0.
  double get completion {
    if (totalQuestions <= 0) {
      return 0.0;
    }

    return (answeredQuestions / totalQuestions).clamp(0.0, 1.0);
  }

  /// Completion percentage as a whole number.
  int get completionPercentage => (completion * 100).round();

  /// Whether every question in this category has been answered.
  bool get isComplete =>
      totalQuestions > 0 && answeredQuestions >= totalQuestions;

  /// Whether this category has at least one answered question.
  bool get hasStarted => answeredQuestions > 0;

  /// Whether this category has not been started.
  bool get isNotStarted => answeredQuestions == 0;

  /// PHS weight for this category.
  double get weight => category.weight;

  /// Display name provided by the canonical PHS category definition.
  String get displayName => category.displayName;

  /// Description provided by the canonical PHS category definition.
  String get description => category.description;

  /// Icon provided by the canonical PHS category definition.
  String get icon => category.icon;

  /// Creates category progress from the complete question catalogue
  /// and the set of answered question IDs.
  static PHSCategoryProgress fromQuestions({
    required PHSCategory category,
    required List<PHSQuestion> questions,
    required Set<String> answeredQuestionIds,
  }) {
    final categoryQuestions = questions
        .where((question) => question.category == category)
        .toList();

    final answeredQuestions = categoryQuestions
        .where((question) => answeredQuestionIds.contains(question.id))
        .length;

    return PHSCategoryProgress(
      category: category,
      totalQuestions: categoryQuestions.length,
      answeredQuestions: answeredQuestions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PHSCategoryProgress &&
        other.category == category &&
        other.totalQuestions == totalQuestions &&
        other.answeredQuestions == answeredQuestions;
  }

  @override
  int get hashCode => Object.hash(category, totalQuestions, answeredQuestions);

  @override
  String toString() {
    return 'PHSCategoryProgress('
        'category: $category, '
        'totalQuestions: $totalQuestions, '
        'answeredQuestions: $answeredQuestions, '
        'completion: $completionPercentage%'
        ')';
  }
}
