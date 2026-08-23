import '../config/question_rule_config.dart';
import '../models/question_evaluation.dart';
import '../../../core/phs/phs_answer.dart';
import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';

/// Executes a QuestionRuleConfig against a user's answer.
///
/// The evaluator contains no business rules.
/// It simply interprets configuration.
class RuleEvaluator {
  const RuleEvaluator();

  QuestionEvaluation evaluate({
    required QuestionRuleConfig rule,
    required PHSAnswer answer,
  }) {
    final answerConfig = rule.configFor(answer.response);

    PropertyRisk? risk;

    if (answerConfig.hasRisk) {
      final config = answerConfig.risk!;

      risk = PropertyRisk(
        id: '${rule.questionId}_${answer.response.name}',
        title: config.title,
        description: config.description,
        severity: config.severity,
        phiImpact: config.phiImpact,
        category: "General",
      );
    }

    Recommendation? recommendation;

    if (answerConfig.hasRecommendation) {
      final config = answerConfig.recommendation!;

      recommendation = Recommendation(
        id: '${rule.questionId}_${answer.response.name}',
        title: config.title,
        description: config.description,
        estimatedPHIGain: config.estimatedPHIGain,
        priority: RecommendationPriority.medium,
        requiredDocuments: config.requiredDocuments,
      );
    }

    return QuestionEvaluation(
      score: answerConfig.score,
      maxScore: rule.weight,
      risk: risk,
      recommendation: recommendation,
    );
  }
}