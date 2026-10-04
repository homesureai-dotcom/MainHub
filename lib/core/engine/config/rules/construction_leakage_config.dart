import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Water Leakage rule.
///
/// CONSTRUCTION_LEAKAGE contributes to the Construction Quality
/// PHS category.
const QuestionRuleConfig constructionLeakageRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_LEAKAGE',
  category: PHSCategory.constructionQuality,
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
        title: 'Water leakage could not be verified',
        description:
            'The property should be inspected for active or recurring leakage through walls, ceilings, plumbing areas or external surfaces.',
        severity: RiskSeverity.medium,
        phiImpact: 4,
      ),
      recommendation: RecommendationConfig(
        title: 'Inspect for Water Leakage',
        description:
            'Inspect the property for active or recurring leakage and document any required repairs.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Leakage photographs',
          'Repair records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Significant Water Leakage Reported',
        description:
            'Significant water leakage can damage finishes and building components and may indicate an unresolved construction or waterproofing issue.',
        severity: RiskSeverity.high,
        phiImpact: 8,
      ),
      recommendation: RecommendationConfig(
        title: 'Resolve Water Leakage',
        description:
            'Identify the source of the leakage, complete the necessary repair and verify that the issue has been resolved.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Leakage photographs',
          'Repair records',
        ],
      ),
    ),
  },
);