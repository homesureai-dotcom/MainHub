import 'phs_answer.dart';
import 'phs_categories.dart';
import 'phs_category_progress.dart';
import 'phs_question.dart';

/// Aggregated progress for the complete Property Health Assessment.
///
/// This is the single domain-level source of truth for:
/// - overall assessment completion
/// - question completion
/// - six-pillar completion
/// - current/active pillar
/// - completed pillars
class PHSAssessmentProgress {
  final List<PHSCategoryProgress> categories;
  final int totalQuestions;
  final int answeredQuestions;

  const PHSAssessmentProgress({
    required this.categories,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  int get remainingQuestions {
    final remaining = totalQuestions - answeredQuestions;

    return remaining < 0 ? 0 : remaining;
  }

  double get completion {
    if (totalQuestions <= 0) {
      return 0.0;
    }

    return (answeredQuestions / totalQuestions).clamp(0.0, 1.0);
  }

  int get completionPercentage => (completion * 100).round();

  bool get isComplete =>
      totalQuestions > 0 && answeredQuestions >= totalQuestions;

  bool get hasStarted => answeredQuestions > 0;

  bool get isNotStarted => answeredQuestions == 0;

  /// Number of PHS pillars represented by this progress model.
  ///
  /// The assessment always exposes the six canonical PHS pillars,
  /// even when a test fixture or future assessment configuration
  /// contains zero questions for one of those pillars.
  int get totalCategoryCount => categories.length;

  /// Number of pillars whose available questions are complete.
  ///
  /// A zero-question pillar is not counted as completed because
  /// there is no assessment work to complete for that pillar.
  int get completedCategoryCount => categories
      .where((category) => category.totalQuestions > 0 && category.isComplete)
      .length;

  /// Number of pillars where at least one question has been answered.
  int get startedCategoryCount =>
      categories.where((category) => category.hasStarted).length;

  /// Number of pillars that have not yet received an answer.
  ///
  /// This includes zero-question pillars because the dashboard
  /// represents progress across the six canonical PHS pillars.
  int get notStartedCategoryCount =>
      categories.where((category) => category.isNotStarted).length;

  /// Percentage of the six PHS pillars that are complete.
  ///
  /// This is intentionally different from question completion.
  double get categoryCompletion {
    if (categories.isEmpty) {
      return 0.0;
    }

    return (completedCategoryCount / categories.length).clamp(0.0, 1.0);
  }

  int get categoryCompletionPercentage => (categoryCompletion * 100).round();

  /// Returns the first category that contains questions
  /// but is not yet complete.
  ///
  /// Categories with zero questions are ignored when identifying
  /// the current assessment work.
  PHSCategory? get currentCategory {
    for (final category in categories) {
      if (category.totalQuestions <= 0) {
        continue;
      }

      if (!category.isComplete) {
        return category.category;
      }
    }

    return null;
  }

  /// Returns the first category that has started but is not complete.
  ///
  /// If there is no partially completed category, this falls back
  /// to the first incomplete category.
  PHSCategory? get activeCategory {
    for (final category in categories) {
      if (category.totalQuestions <= 0) {
        continue;
      }

      if (category.hasStarted && !category.isComplete) {
        return category.category;
      }
    }

    return currentCategory;
  }

  PHSCategoryProgress? progressFor(PHSCategory category) {
    for (final progress in categories) {
      if (progress.category == category) {
        return progress;
      }
    }

    return null;
  }

  bool isCategoryComplete(PHSCategory category) {
    return progressFor(category)?.isComplete ?? false;
  }

  static PHSAssessmentProgress fromQuestions({
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
  }) {
    final answeredQuestionIds = answers
        .map((answer) => answer.questionId)
        .toSet();

    final questionIds = questions.map((question) => question.id).toSet();

    final categoryProgress = PHSCategory.values
        .map(
          (category) => PHSCategoryProgress.fromQuestions(
            category: category,
            questions: questions,
            answeredQuestionIds: answeredQuestionIds,
          ),
        )
        .toList();

    return PHSAssessmentProgress(
      categories: List.unmodifiable(categoryProgress),
      totalQuestions: questions.length,
      answeredQuestions: answeredQuestionIds.where(questionIds.contains).length,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PHSAssessmentProgress &&
        other.totalQuestions == totalQuestions &&
        other.answeredQuestions == answeredQuestions &&
        _listEquals(other.categories, categories);
  }

  @override
  int get hashCode => Object.hash(
    totalQuestions,
    answeredQuestions,
    Object.hashAll(categories),
  );

  @override
  String toString() {
    return 'PHSAssessmentProgress('
        'totalQuestions: $totalQuestions, '
        'answeredQuestions: $answeredQuestions, '
        'completion: $completionPercentage%, '
        'completedCategories: '
        '$completedCategoryCount/$totalCategoryCount, '
        'currentCategory: $currentCategory'
        ')';
  }

  static bool _listEquals<T>(List<T> first, List<T> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
