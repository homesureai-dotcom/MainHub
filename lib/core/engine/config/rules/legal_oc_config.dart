import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Occupancy Certificate rule.
///
/// LEGAL_OC contributes to the Legal & Ownership PHS category.
const QuestionRuleConfig legalOcRule = QuestionRuleConfig(
  questionId: 'LEGAL_OC',
  category: PHSCategory.legalOwnership,
  weight: 40.0,
  version: 1,
  enabled: true,
  answers: {
    PHSResponse.yes: AnswerConfig(
      score: 40.0,
    ),

    PHSResponse.unsure: AnswerConfig(
      score: 20.0,
      risk: RiskConfig(
        title: 'Occupancy Certificate could not be verified',
        description:
            'The Occupancy Certificate should be verified before purchase.',
        severity: RiskSeverity.medium,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Occupancy Certificate',
        description:
            'Request and verify the Occupancy Certificate from the builder.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Occupancy Certificate',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Occupancy Certificate Missing',
        description:
            'The property may not be legally fit for occupation.',
        severity: RiskSeverity.critical,
        phiImpact: 10,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain Occupancy Certificate',
        description:
            'Obtain the Occupancy Certificate from the builder or local authority.',
        estimatedPHIGain: 40,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Occupancy Certificate',
        ],
      ),
    ),
  },
);