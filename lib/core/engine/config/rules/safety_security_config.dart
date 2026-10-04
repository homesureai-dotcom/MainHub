import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Security rule.
///
/// SAFETY_SECURITY contributes to the Safety & Compliance
/// PHS category.
const QuestionRuleConfig safetySecurityRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_SECURITY',
  category: PHSCategory.safetyCompliance,
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
        title: 'Security arrangements could not be verified',
        description:
            'The property security arrangements should be reviewed, including access control, visitor management and security personnel where applicable.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Security Arrangements',
        description:
            'Review the current security arrangements and verify that appropriate access control and visitor management measures are in place.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Security service records',
          'Access-control records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Security Arrangements Inadequate',
        description:
            'Weak or unavailable security arrangements can reduce resident safety and protection of common property.',
        severity: RiskSeverity.high,
        phiImpact: 6,
      ),
      recommendation: RecommendationConfig(
        title: 'Improve Security Arrangements',
        description:
            'Review and strengthen security arrangements, access controls and visitor management as appropriate for the property.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Security service records',
          'Access-control records',
          'Corrective action records',
        ],
      ),
    ),
  },
);