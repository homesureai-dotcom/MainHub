import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Dampness rule.
///
/// CONSTRUCTION_DAMPNESS contributes to the Construction Quality
/// PHS category.
const QuestionRuleConfig constructionDampnessRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_DAMPNESS',
  category: PHSCategory.constructionQuality,
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
        title: 'Dampness could not be verified',
        description:
            'The property should be inspected for persistent moisture, damp patches or related surface deterioration.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Inspect for Dampness',
        description:
            'Inspect affected areas and identify the source of any persistent dampness before carrying out repairs.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Dampness photographs',
          'Inspection report',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Significant Dampness Reported',
        description:
            'Persistent dampness can damage walls and finishes and may indicate an unresolved moisture or waterproofing issue.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Resolve Dampness',
        description:
            'Identify the source of the moisture, complete the required corrective work and verify that the dampness has been resolved.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Dampness photographs',
          'Repair records',
          'Inspection report',
        ],
      ),
    ),
  },
);