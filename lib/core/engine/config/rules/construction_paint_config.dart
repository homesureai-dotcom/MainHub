import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Paint & Surface Finish rule.
///
/// CONSTRUCTION_PAINT contributes to the Construction Quality
/// PHS category.
const QuestionRuleConfig constructionPaintRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_PAINT',
  category: PHSCategory.constructionQuality,
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
        title: 'Paint and surface finish quality could not be verified',
        description:
            'The property should be inspected for peeling, patchiness, cracks or other visible surface defects.',
        severity: RiskSeverity.low,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Inspect Paint and Surface Finishes',
        description:
            'Inspect visible paint and surface finishes and document areas that require corrective work.',
        estimatedPHIGain: 5,
        priority: RecommendationPriority.low,
        requiredDocuments: [
          'Paint finish photographs',
          'Snagging report',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Poor Paint or Surface Finish Reported',
        description:
            'Poor paint or surface finishing may indicate workmanship defects and can increase maintenance requirements.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Rectify Paint and Surface Defects',
        description:
            'Document the affected areas and complete the required painting or surface-finishing work.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Paint finish photographs',
          'Snagging report',
          'Repair records',
        ],
      ),
    ),
  },
);