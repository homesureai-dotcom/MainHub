import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Encumbrance Certificate rule.
///
/// LEGAL_EC contributes to the Legal & Ownership PHS category.
const QuestionRuleConfig legalEcRule = QuestionRuleConfig(
  questionId: 'LEGAL_EC',
  category: PHSCategory.legalOwnership,
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
        title: 'Recent Encumbrance Certificate could not be verified',
        description:
            'A recent Encumbrance Certificate should be reviewed to identify registered encumbrances on the property.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain a Recent Encumbrance Certificate',
        description:
            'Obtain and review a recent Encumbrance Certificate for the property.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Encumbrance Certificate',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Encumbrance Certificate Not Available',
        description:
            'The absence of a recent Encumbrance Certificate means registered encumbrances have not been adequately verified.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain a Recent Encumbrance Certificate',
        description:
            'Obtain a recent Encumbrance Certificate and review it for registered encumbrances.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Encumbrance Certificate',
        ],
      ),
    ),
  },
);