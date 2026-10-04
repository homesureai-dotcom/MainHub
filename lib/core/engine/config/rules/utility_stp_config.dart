import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Sewage Treatment Plant (STP) rule.
///
/// UTILITY_STP contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityStpRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_STP',
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
        title: 'STP operational status could not be verified',
        description:
            'The Sewage Treatment Plant should be verified for operational status, maintenance and supporting records.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify STP Operation',
        description:
            'Verify that the STP is operational and review its maintenance and operating records.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'STP operation records',
          'STP maintenance records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'STP Not Operational',
        description:
            'The Sewage Treatment Plant is not currently confirmed as operational, creating a wastewater management and operational readiness concern.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore STP Operation',
        description:
            'Identify the reason for the STP outage, complete the required corrective work and verify that the plant is operating properly.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'STP operation records',
          'STP maintenance records',
          'Repair records',
        ],
      ),
    ),
  },
);