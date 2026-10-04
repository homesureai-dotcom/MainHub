import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Registered Sale Deed rule.
///
/// LEGAL_SD contributes to the Legal & Ownership PHS category.
const QuestionRuleConfig legalSdRule = QuestionRuleConfig(
  questionId: 'LEGAL_SD',
  category: PHSCategory.legalOwnership,
  weight: 25.0,
  version: 1,
  enabled: true,
  answers: {
    PHSResponse.yes: AnswerConfig(
      score: 25.0,
    ),

    PHSResponse.unsure: AnswerConfig(
      score: 12.5,
      risk: RiskConfig(
        title: 'Registered Sale Deed could not be verified',
        description:
            'The registered Sale Deed should be verified to establish legal ownership of the property.',
        severity: RiskSeverity.medium,
        phiImpact: 4,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Registered Sale Deed',
        description:
            'Locate and verify the registered Sale Deed and confirm that it matches the property and owner details.',
        estimatedPHIGain: 12,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Registered Sale Deed',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Registered Sale Deed Missing',
        description:
            'A missing registered Sale Deed creates a significant ownership verification risk.',
        severity: RiskSeverity.critical,
        phiImpact: 8,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain Registered Sale Deed',
        description:
            'Obtain and verify the registered Sale Deed for the property.',
        estimatedPHIGain: 25,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Registered Sale Deed',
        ],
      ),
    ),
  },
);