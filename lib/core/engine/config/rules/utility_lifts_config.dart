import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the lift operational readiness rule.
///
/// UTILITY_LIFTS contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityLiftsRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_LIFTS',
  category: PHSCategory.utilitiesInfrastructure,
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
        title: 'Lift operational status could not be verified',
        description:
            'The available lifts should be verified for operational readiness and appropriate maintenance documentation.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Lift Maintenance',
        description:
            'Verify that the lifts are operational and review the applicable maintenance and inspection records.',
        estimatedPHIGain: 5,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Lift maintenance records',
          'Lift inspection certificate',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Lift Operational Issue Reported',
        description:
            'One or more lifts are not currently confirmed as operational, which may affect accessibility and day-to-day convenience.',
        severity: RiskSeverity.high,
        phiImpact: 4,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore Lift Operation',
        description:
            'Identify the lift issue, complete the required repair or maintenance work and verify that the lift is operational.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Lift maintenance records',
          'Lift inspection certificate',
          'Repair records',
        ],
      ),
    ),
  },
);