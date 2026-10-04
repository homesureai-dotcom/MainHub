import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Flooring Quality rule.
///
/// CONSTRUCTION_FLOORING contributes to the Construction Quality
/// PHS category.
const QuestionRuleConfig constructionFlooringRule =
    QuestionRuleConfig(
  questionId: 'CONSTRUCTION_FLOORING',
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
        title: 'Flooring quality could not be verified',
        description:
            'The flooring should be inspected for alignment, visible defects, damage or other workmanship concerns.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Inspect Flooring Quality',
        description:
            'Inspect the flooring for workmanship defects and document any areas requiring repair or replacement.',
        estimatedPHIGain: 7,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Flooring photographs',
          'Snagging report',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Poor Flooring Quality Reported',
        description:
            'Poor flooring workmanship or visible defects may affect usability, appearance and long-term maintenance.',
        severity: RiskSeverity.medium,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Rectify Flooring Defects',
        description:
            'Document the flooring defects and have the affected areas repaired or replaced as appropriate.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Flooring photographs',
          'Snagging report',
          'Repair records',
        ],
      ),
    ),
  },
);