import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';
import '../models/property_health_result.dart';
import '../models/question_evaluation.dart';

/// Builds the final PropertyHealthResult from
/// individual QuestionEvaluation objects.
///
/// Responsibilities:
/// - Calculate the overall Property Health Index (PHI)
/// - Aggregate risks
/// - Aggregate recommendations
/// - (Future) Calculate category-wise scores
class AssessmentResultBuilder {
  const AssessmentResultBuilder();

  PropertyHealthResult build({
    required List<QuestionEvaluation> evaluations,
  }) {
    // Empty assessment
    if (evaluations.isEmpty) {
      return PropertyHealthResult(
        overallScore: 0.0,
        categoryScores: const {},
        risks: const [],
        recommendations: const [],
        evaluatedAt: DateTime.now(),
      );
    }

    double earnedScore = 0.0;
    double maximumScore = 0.0;

    final List<PropertyRisk> risks = [];
    final List<Recommendation> recommendations = [];

    for (final evaluation in evaluations) {
      earnedScore += evaluation.score;
      maximumScore += evaluation.maxScore;

      if (evaluation.hasRisk) {
        risks.add(evaluation.risk!);
      }

      if (evaluation.hasRecommendation) {
        recommendations.add(evaluation.recommendation!);
      }
    }

    final double overallScore = maximumScore == 0.0
        ? 0.0
        : (earnedScore / maximumScore) * 100.0;

    return PropertyHealthResult(
      overallScore: overallScore,
      categoryScores: const {}, // Category scoring in next sprint
      risks: risks,
      recommendations: recommendations,
      evaluatedAt: DateTime.now(),
    );
  }
}