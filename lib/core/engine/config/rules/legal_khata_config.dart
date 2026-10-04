import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the e-Khata rule.
///
/// LEGAL_KHATA contributes to the Legal & Ownership PHS category.
const QuestionRuleConfig legalKhataRule = QuestionRuleConfig(
  questionId: 'LEGAL_KHATA',
  category: PHSCategory.legalOwnership,
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
        title: 'e-Khata could not be verified',
        description:
            'The municipal property record should be verified to confirm the current property details.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify e-Khata',
        description:
            'Verify the current e-Khata record and confirm that the property details are accurate.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'e-Khata',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'e-Khata Missing',
        description:
            'The absence of an e-Khata may create difficulties with municipal records, registration and property transactions.',
        severity: RiskSeverity.high,
        phiImpact: 6,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain e-Khata',
        description:
            'Initiate the process to obtain or rectify the property e-Khata record.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'e-Khata',
        ],
      ),
    ),
  },
);