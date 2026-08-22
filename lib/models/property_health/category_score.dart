import '../../core/phs/phs_categories.dart';

/// Represents the calculated score for a Property Health category.
class CategoryScore {
  /// Property Health category.
  final PHSCategory category;

  /// Percentage score (0–100).
  final double score;

  /// Maximum possible weight for this category.
  final double maxScore;

  /// Total questions in this category.
  final int totalQuestions;

  /// Number of questions answered positively.
  final int passedQuestions;

  const CategoryScore({
    required this.category,
    required this.score,
    this.maxScore = 100,
    this.totalQuestions = 0,
    this.passedQuestions = 0,
  });

  /// Convenience getter used by the UI.
  bool get isHealthy => score >= 80;

  /// Percentage rounded for display.
  int get roundedScore => score.round();

  @override
  String toString() {
    return 'CategoryScore(category: ${category.displayName}, score: $roundedScore)';
  }
}