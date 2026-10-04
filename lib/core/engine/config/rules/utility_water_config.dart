import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Water Availability rule.
///
/// UTILITY_WATER contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityWaterRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_WATER',
  category: PHSCategory.utilitiesInfrastructure,
  weight: 15.0,
  version: 1,
  enabled: true,
  answers: {
    PHSResponse.yes: AnswerConfig(
      score: 15.0,
    ),

    PHSResponse.unsure: AnswerConfig(
      score: 7.5,
      risk: RiskConfig(
        title: 'Reliable water availability could not be verified',
        description:
            'The property should be checked for reliable water availability and any recurring supply interruptions.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Water Availability',
        description:
            'Review the property water supply arrangements and confirm that water is reliably available for normal residential needs.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Water supply records',
          'Water availability records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Water Availability Issue Reported',
        description:
            'Frequent or unresolved water shortages can affect the usability and operational readiness of the property.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Resolve Water Availability Issue',
        description:
            'Identify the cause of the water supply issue and work with the applicable service provider or property management to restore reliable availability.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Water supply records',
          'Water availability records',
          'Repair or complaint records',
        ],
      ),
    ),
  },
);