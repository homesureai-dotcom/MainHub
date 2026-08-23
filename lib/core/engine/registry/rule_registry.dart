import '../config/question_rule_config.dart';
import '../config/rules/legal_oc_config.dart';

/// Central registry for all Property Intelligence rules.
///
/// The engine never knows about individual rules.
/// It simply requests the configuration for a question.
class RuleRegistry {
  const RuleRegistry();

  QuestionRuleConfig? getRule(String questionId) {
    switch (questionId) {
      case "LEGAL_OC":
        return legalOcRule;

      default:
        return null;
    }
  }
}