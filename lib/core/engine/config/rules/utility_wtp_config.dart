import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Water Treatment Plant (WTP) rule.
///
/// UTILITY_WTP contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityWtpRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_WTP',
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
        title: 'WTP operational status could not be verified',
        description:
            "The property's Water Treatment Plant should be verified for operational status and supporting records.",
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify WTP Operation',
        description:
            'Verify that the WTP is operational and review the available operating and water quality records.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'WTP operation records',
          'Water quality test reports',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'WTP Not Operational',
        description:
            'The Water Treatment Plant is not currently confirmed as operational, which may affect treated water quality and availability.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore WTP Operation',
        description:
            'Identify the reason for the WTP issue, complete the required corrective work and verify that the plant is operating properly.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'WTP operation records',
          'Water quality test reports',
          'Repair records',
        ],
      ),
    ),
  },
);