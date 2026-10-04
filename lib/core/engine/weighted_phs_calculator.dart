import '../phs/phs_categories.dart';

/// Calculates the weighted Property Health Score (PHS)
/// from category-level scores.
///
/// Each PHS category has a configured weight defined by
/// [PHSCategory.weight].
///
/// The calculator is deliberately independent of:
/// - UI
/// - assessment screens
/// - rules
/// - risks
/// - recommendations
///
/// It only performs the mathematical calculation.
class WeightedPHScalculator {
  const WeightedPHScalculator();

  /// Calculates the weighted PHS across all six categories.
  ///
  /// Category scores are expected to be percentages from 0 to 100.
  ///
  /// Categories missing from [categoryScores] contribute 0 to the
  /// weighted result. This is intentional: a partial assessment must
  /// not be presented as a complete PHS.
  double calculate(
    Map<PHSCategory, double> categoryScores,
  ) {
    double weightedScore = 0.0;

    for (final category in PHSCategory.values) {
      final score = _clampScore(
        categoryScores[category] ?? 0.0,
      );

      final weight = category.weight / 100.0;

      weightedScore += score * weight;
    }

    return _clampScore(weightedScore);
  }

  /// Returns the weighted contribution of one category.
  double contribution({
    required PHSCategory category,
    required double score,
  }) {
    final safeScore = _clampScore(score);
    final weight = category.weight / 100.0;

    return safeScore * weight;
  }

  double _clampScore(double score) {
    return score.clamp(0.0, 100.0).toDouble();
  }
}