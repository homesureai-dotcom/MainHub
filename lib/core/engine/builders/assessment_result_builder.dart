import '../../../core/phs/phs_categories.dart';
import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';
import '../models/property_health_result.dart';
import '../models/question_evaluation.dart';
import '../weighted_phs_calculator.dart';

/// Builds the final PropertyHealthResult from individual
/// question evaluations.
class AssessmentResultBuilder {
  const AssessmentResultBuilder();

  PropertyHealthResult build({
    required List<QuestionEvaluation> evaluations,
    required int totalQuestionCount,
  }) {
    final Map<PHSCategory, double> categoryEarned = {};
    final Map<PHSCategory, double> categoryPossible = {};

    final List<PropertyRisk> risks = [];
    final List<Recommendation> recommendations = [];

    for (final evaluation in evaluations) {
      categoryEarned.update(
        evaluation.category,
        (value) => value + evaluation.score,
        ifAbsent: () => evaluation.score,
      );

      categoryPossible.update(
        evaluation.category,
        (value) => value + evaluation.maxScore,
        ifAbsent: () => evaluation.maxScore,
      );

      if (evaluation.risk != null) {
        risks.add(evaluation.risk!);
      }

      if (evaluation.recommendation != null) {
        recommendations.add(evaluation.recommendation!);
      }
    }

    final Map<PHSCategory, double> categoryScores = {};

    for (final category in categoryEarned.keys) {
      final earned = categoryEarned[category] ?? 0.0;
      final possible = categoryPossible[category] ?? 0.0;

      categoryScores[category] = possible == 0.0
          ? 0.0
          : (earned / possible) * 100.0;
    }

    const calculator = WeightedPHScalculator();

    final double weightedScore = calculator.calculate(
      categoryScores,
    );

    return PropertyHealthResult(
      overallScore: weightedScore,
      categoryScores: Map.unmodifiable(categoryScores),
      risks: List.unmodifiable(risks),
      recommendations: List.unmodifiable(recommendations),
      evaluatedQuestionCount: evaluations.length,
      totalQuestionCount: totalQuestionCount,
      evaluatedCategoryCount: categoryScores.length,
      totalCategoryCount: PHSCategory.values.length,
      evaluatedAt: DateTime.now(),
    );
  }
}