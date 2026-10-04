import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Fire-Fighting System rule.
///
/// SAFETY_FIRE_SYSTEM contributes to the Safety & Compliance
/// PHS category.
const QuestionRuleConfig safetyFireSystemRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_FIRE_SYSTEM',
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
        title: 'Fire-fighting system readiness could not be verified',
        description:
            'The applicable fire-fighting systems should be checked for operational readiness and appropriate maintenance records.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Fire-Fighting System',
        description:
            'Inspect the applicable fire-fighting systems and verify their operational status and maintenance records.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Fire-fighting system inspection record',
          'Maintenance records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Fire-Fighting System Not Operational',
        description:
            'A non-operational or inadequately maintained fire-fighting system creates a significant resident-safety risk.',
        severity: RiskSeverity.critical,
        phiImpact: 10,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore Fire-Fighting System',
        description:
            'Identify and correct the fire-fighting system issue and verify that the applicable systems are operational.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Fire-fighting system inspection record',
          'Maintenance records',
          'Corrective action records',
        ],
      ),
    ),
  },
);