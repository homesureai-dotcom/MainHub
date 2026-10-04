import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Fire NOC rule.
///
/// SAFETY_FIRE_NOC contributes to the Safety & Compliance
/// PHS category.
const QuestionRuleConfig safetyFireNocRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_FIRE_NOC',
  category: PHSCategory.safetyCompliance,
  weight: 20.0,
  version: 1,
  enabled: true,
  answers: {
    PHSResponse.yes: AnswerConfig(
      score: 20.0,
    ),

    PHSResponse.unsure: AnswerConfig(
      score: 10.0,
      risk: RiskConfig(
        title: 'Fire NOC could not be verified',
        description:
            'The applicable Fire NOC should be verified along with the supporting fire-safety documentation.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Fire NOC',
        description:
            'Obtain and verify the applicable Fire NOC and supporting fire-safety documentation.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Fire NOC',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Fire NOC Missing',
        description:
            'The applicable Fire NOC has not been confirmed, creating a significant statutory safety and compliance concern.',
        severity: RiskSeverity.critical,
        phiImpact: 10,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain Fire NOC',
        description:
            'Obtain the applicable Fire NOC and verify compliance with the required fire-safety provisions.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Fire NOC',
          'Fire-safety compliance records',
        ],
      ),
    ),
  },
);