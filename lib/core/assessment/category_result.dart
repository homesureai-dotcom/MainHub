import '../phs/phs_categories.dart';

class CategoryResult {
  /// PHS category
  final PHSCategory category;

  /// Score earned by the user
  final double earnedScore;

  /// Maximum possible score
  final double maximumScore;

  /// Weight of this category in the HomeSure Score
  final double weight;

  const CategoryResult({
    required this.category,
    required this.earnedScore,
    required this.maximumScore,
    required this.weight,
  });

  /// Percentage achieved within this category.
  double get percentage {
    if (maximumScore == 0) {
      return 0;
    }

    return (earnedScore / maximumScore) * 100;
  }

  /// Contribution of this category to the final HomeSure Score.
  ///
  /// Example:
  /// Category Weight = 25%
  /// Category Percentage = 80%
  ///
  /// Contribution = 20
  double get weightedContribution {
    return (percentage / 100) * weight;
  }
}