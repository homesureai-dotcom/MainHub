import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Structural Cracks rule.
///
/// CONSTRUCTION_CRACKS contributes to the Construction Quality
/// PHS category.
const QuestionRuleConfig constructionCracksRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_CRACKS',
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
        title: 'Structural cracks could not be verified',
        description:
            'The property should be inspected to determine whether visible cracks are structural or superficial.',
        severity: RiskSeverity.medium,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain a Structural Inspection',
        description:
            'Have the property inspected by a qualified structural professional and document any significant cracks.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Structural inspection report',
          'Photographs of cracks',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Significant Structural Cracks Reported',
        description:
            'Significant structural cracks may indicate a construction or structural condition that requires professional assessment.',
        severity: RiskSeverity.critical,
        phiImpact: 10,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain a Structural Inspection',
        description:
            'Arrange a professional structural inspection and resolve any identified structural defects.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Structural inspection report',
          'Repair records',
        ],
      ),
    ),
  },
);