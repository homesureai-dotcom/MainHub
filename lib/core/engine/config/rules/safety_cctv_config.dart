import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the CCTV rule.
///
/// SAFETY_CCTV contributes to the Safety & Compliance PHS category.
const QuestionRuleConfig safetyCctvRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_CCTV',
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
        title: 'CCTV system readiness could not be verified',
        description:
            'The applicable CCTV system should be checked to confirm that cameras, recording and monitoring are operational in the relevant common areas.',
        severity: RiskSeverity.medium,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify CCTV System',
        description:
            'Check the CCTV system and verify operational coverage, recording capability and maintenance arrangements.',
        estimatedPHIGain: 7,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'CCTV maintenance records',
          'CCTV system inspection record',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'CCTV System Not Operational',
        description:
            'A non-operational CCTV system can reduce monitoring capability and incident visibility in common areas.',
        severity: RiskSeverity.medium,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore CCTV System',
        description:
            'Identify the CCTV system issue, restore the required coverage and recording capability, and verify ongoing operation.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'CCTV maintenance records',
          'CCTV system inspection record',
          'Repair records',
        ],
      ),
    ),
  },
);