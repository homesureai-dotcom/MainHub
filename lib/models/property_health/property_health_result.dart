import 'category_score.dart';
import 'property_risk.dart';
import 'recommendation.dart';

/// Final outcome produced by the Property Health Engine.
///
/// This object represents the complete health assessment
/// of a property and is the primary source of truth
/// for the rest of the application.
class PropertyHealthResult {
  /// Overall Property Health Index (0–100).
  final double overallScore;

  /// Category-wise Property Health scores.
  final List<CategoryScore> categoryScores;

  /// Identified property risks.
  final List<PropertyRisk> risks;

  /// Recommended next actions.
  final List<Recommendation> recommendations;

  const PropertyHealthResult({
    required this.overallScore,
    required this.categoryScores,
    required this.risks,
    required this.recommendations,
  });

  /// Rounded score used throughout the UI.
  int get roundedScore => overallScore.round();

  /// Overall rating derived from the score.
  String get rating {
    if (overallScore >= 90) {
      return "Excellent";
    }

    if (overallScore >= 75) {
      return "Good";
    }

    if (overallScore >= 60) {
      return "Fair";
    }

    return "Needs Attention";
  }

  /// Whether the property is considered healthy.
  bool get isHealthy => overallScore >= 80;

  /// Number of critical risks.
  int get criticalRiskCount =>
      risks.where((r) => r.severity == RiskSeverity.critical).length;

  /// Number of high risks.
  int get highRiskCount =>
      risks.where((r) => r.severity == RiskSeverity.high).length;

  /// Total recommendations.
  int get recommendationCount => recommendations.length;

  @override
  String toString() {
    return '''
PropertyHealthResult(
  score: $roundedScore,
  rating: $rating,
  risks: ${risks.length},
  recommendations: ${recommendations.length}
)
''';
  }
}