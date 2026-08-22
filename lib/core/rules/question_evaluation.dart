import '../../models/property_health/property_risk.dart';
import '../../models/property_health/recommendation.dart';

/// Result produced after evaluating a single assessment question.
class QuestionEvaluation {
  /// Score earned for this question.
  final double score;

  /// Maximum possible score.
  final double maxScore;

  /// Risk generated (if any).
  final PropertyRisk? risk;

  /// Recommendation generated (if any).
  final Recommendation? recommendation;

  const QuestionEvaluation({
    required this.score,
    required this.maxScore,
    this.risk,
    this.recommendation,
  });
}