import '../../phs/phs_answer.dart';
import '../../phs/phs_categories.dart';
import '../config/question_rule_config.dart';
import '../models/question_evaluation.dart';
import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';

/// Executes a QuestionRuleConfig against a user's answer.
///
/// The evaluator contains no question-specific business rules.
/// It interprets the supplied configuration and produces a
/// runtime QuestionEvaluation.
class RuleEvaluator {
  const RuleEvaluator();

  QuestionEvaluation evaluate({
    required QuestionRuleConfig rule,
    required PHSAnswer answer,
  }) {
    final answerConfig = rule.configFor(answer.response);

    PropertyRisk? risk;

    if (answerConfig.risk != null) {
      final riskConfig = answerConfig.risk!;

      risk = PropertyRisk(
        id: '${rule.questionId}_${answer.response.name}',
        title: riskConfig.title,
        description: riskConfig.description,
        severity: riskConfig.severity,
        phiImpact: riskConfig.phiImpact,
        category: rule.category.displayName,
      );
    }

    Recommendation? recommendation;

    if (answerConfig.recommendation != null) {
      final recommendationConfig = answerConfig.recommendation!;

      recommendation = Recommendation(
        id: '${rule.questionId}_${answer.response.name}',
        title: recommendationConfig.title,
        description: recommendationConfig.description,
        estimatedPHIGain: recommendationConfig.estimatedPHIGain,
        priority: recommendationConfig.priority,
        requiredDocuments:
            recommendationConfig.requiredDocuments,
      );
    }

    return QuestionEvaluation(
      category: rule.category,
      score: answerConfig.score,
      maxScore: rule.weight,
      risk: risk,
      recommendation: recommendation,
    );
  }
}