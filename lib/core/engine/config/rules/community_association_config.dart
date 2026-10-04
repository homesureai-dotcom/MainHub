import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Community Association rule.
///
/// COMMUNITY_ASSOCIATION contributes to the Community & Maintenance
/// PHS category.
const QuestionRuleConfig communityAssociationRule = QuestionRuleConfig(
  questionId: 'COMMUNITY_ASSOCIATION',
  category: PHSCategory.communityMaintenance,
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
        title: 'Association Formation Status Unclear',
        description:
            'The status of the apartment association formation could not be confirmed from the available information.',
        severity: RiskSeverity.medium,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Association Formation',
        description:
            'Obtain and review the relevant association formation and handover records to confirm the current status of the community association.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Association formation documents',
          'Association registration records',
          'Builder handover records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Apartment Association Not Formed',
        description:
            'A functioning apartment association could not be confirmed for the community.',
        severity: RiskSeverity.high,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Complete Association Formation',
        description:
            'Complete the association formation process and maintain the relevant registration, governance, and handover records.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Association formation documents',
          'Association registration records',
          'Builder handover records',
        ],
      ),
    ),
  },
);