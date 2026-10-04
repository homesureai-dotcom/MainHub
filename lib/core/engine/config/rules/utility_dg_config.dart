import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the DG backup power rule.
///
/// UTILITY_DG contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityDgRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_DG',
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
        title: 'DG backup power could not be verified',
        description:
            'The backup power system should be verified for operational readiness, maintenance and applicable coverage.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify DG Backup Readiness',
        description:
            'Verify that the DG backup system is operational and review its maintenance and operating records.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'DG operation records',
          'Maintenance records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'DG Backup Power Not Operational',
        description:
            'The backup power system is not currently confirmed as operational, reducing resilience during electricity interruptions.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore DG Backup Readiness',
        description:
            'Resolve the DG backup issue, complete the necessary maintenance or repair and verify operational readiness.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'DG operation records',
          'Maintenance records',
          'Repair records',
        ],
      ),
    ),
  },
);