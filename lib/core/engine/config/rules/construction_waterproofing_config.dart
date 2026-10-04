import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Waterproofing rule.
///
/// CONSTRUCTION_WATERPROOFING contributes to the Construction
/// Quality PHS category.
const QuestionRuleConfig constructionWaterproofingRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_WATERPROOFING',
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
        title: 'Waterproofing performance could not be verified',
        description:
            "The property's waterproofing should be inspected, particularly in exposed or moisture-prone areas such as terraces and bathrooms.",
        severity: RiskSeverity.medium,
        phiImpact: 4,
      ),
      recommendation: RecommendationConfig(
        title: 'Inspect Waterproofing',
        description:
            "Inspect waterproofing in relevant areas and verify that previous waterproofing work is performing satisfactorily.",
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Waterproofing records',
          'Inspection report',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Waterproofing Issue Reported',
        description:
            'Waterproofing failure can result in water penetration, '
            'leakage and recurring dampness or maintenance problems.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Rectify Waterproofing',
        description:
            'Identify affected areas, repair the waterproofing system '
            'and verify that the issue has been resolved.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Waterproofing records',
          'Inspection report',
          'Repair records',
        ],
      ),
    ),
  },
);