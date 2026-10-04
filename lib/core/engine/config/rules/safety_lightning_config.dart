import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Lightning Protection rule.
///
/// SAFETY_LIGHTNING contributes to the Safety & Compliance
/// PHS category.
const QuestionRuleConfig safetyLightningRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_LIGHTNING',
  category: PHSCategory.safetyCompliance,
  weight: 10.0,
  version: 1,
  enabled: true,
  answers: {
    PHSResponse.yes: AnswerConfig(
      score: 10.0,
    ),

    PHSResponse.unsure: AnswerConfig(
      score: 5.0,
      risk: RiskConfig(
        title: 'Lightning protection could not be verified',
        description:
            'The applicable lightning protection system should be checked for installation, operational condition and maintenance.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Lightning Protection',
        description:
            'Verify that the lightning protection system is installed, maintained and covered by the appropriate inspection records.',
        estimatedPHIGain: 5,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Lightning protection inspection record',
          'Maintenance records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Lightning Protection Issue Identified',
        description:
            'Missing or poorly maintained lightning protection can increase safety risk to the building and its occupants.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Install or Restore Lightning Protection',
        description:
            'Arrange the required inspection, installation or corrective work and verify that the lightning protection system is operational.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Lightning protection inspection record',
          'Maintenance records',
          'Corrective action records',
        ],
      ),
    ),
  },
);