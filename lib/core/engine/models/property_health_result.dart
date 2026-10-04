import '../../../core/phs/phs_categories.dart';
import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';

/// Final output produced by the Property Intelligence Engine.
///
/// The result distinguishes between:
/// - evaluated assessment questions
/// - evaluated PHS categories
/// - category scores
/// - final six-pillar PHS availability
class PropertyHealthResult {
  /// Weighted PHS score.
  ///
  /// This value is meaningful as the final HomeSure PHS only when
  /// [isComplete] is true.
  final double overallScore;

  /// Category-wise scores.
  final Map<PHSCategory, double> categoryScores;

  /// Risks identified during evaluation.
  final List<PropertyRisk> risks;

  /// Recommendations generated during evaluation.
  final List<Recommendation> recommendations;

  /// Number of questions evaluated.
  final int evaluatedQuestionCount;

  /// Total number of questions required by the current assessment.
  final int totalQuestionCount;

  /// Number of PHS categories for which we have evaluated questions.
  final int evaluatedCategoryCount;

  /// Total number of PHS categories.
  final int totalCategoryCount;

  /// Assessment timestamp.
  final DateTime evaluatedAt;

  /// Property Health Standard version.
  final String phsVersion;

  const PropertyHealthResult({
    required this.overallScore,
    required this.categoryScores,
    required this.risks,
    required this.recommendations,
    required this.evaluatedQuestionCount,
    required this.totalQuestionCount,
    required this.evaluatedCategoryCount,
    required this.totalCategoryCount,
    required this.evaluatedAt,
    this.phsVersion = '1.0',
  });

  int get riskCount => risks.length;

  int get recommendationCount => recommendations.length;

  /// Whether all PHS categories have been evaluated.
  bool get isComplete {
    if (totalCategoryCount <= 0) {
      return false;
    }

    return evaluatedCategoryCount >= totalCategoryCount;
  }

  /// Percentage of PHS categories evaluated.
  double get categoryCompletionPercentage {
    if (totalCategoryCount <= 0) {
      return 0.0;
    }

    return ((evaluatedCategoryCount / totalCategoryCount) * 100.0)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  /// Percentage of assessment questions evaluated.
  double get questionCompletionPercentage {
    if (totalQuestionCount <= 0) {
      return 0.0;
    }

    return ((evaluatedQuestionCount / totalQuestionCount) * 100.0)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double get highestCategoryScore {
    if (categoryScores.isEmpty) {
      return 0.0;
    }

    return categoryScores.values.reduce(
      (a, b) => a > b ? a : b,
    );
  }

  double get lowestCategoryScore {
    if (categoryScores.isEmpty) {
      return 0.0;
    }

    return categoryScores.values.reduce(
      (a, b) => a < b ? a : b,
    );
  }

  /// Whether the final six-pillar PHS is available.
  bool get hasFinalScore => isComplete;

  bool get isHealthy => isComplete && overallScore >= 80.0;

  bool get needsAttention => isComplete && overallScore < 80.0;
}