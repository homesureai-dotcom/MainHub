import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Emergency Exits rule.
///
/// SAFETY_EMERGENCY_EXITS contributes to the Safety & Compliance
/// PHS category.
const QuestionRuleConfig safetyEmergencyExitsRule =
    QuestionRuleConfig(
  questionId: 'SAFETY_EMERGENCY_EXITS',
  category: PHSCategory.safetyCompliance,
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
        title: 'Emergency exit readiness could not be verified',
        description:
            'Emergency exits should be checked to confirm that they are accessible, clearly identified and available for emergency evacuation.',
        severity: RiskSeverity.high,
        phiImpact: 5,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Emergency Exits',
        description:
            'Inspect emergency exits and confirm that they are accessible, clearly marked and free from obstruction.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Emergency exit inspection record',
          'Photographs of emergency exits',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Emergency Exit Issue Reported',
        description:
            'Blocked, inaccessible or poorly identified emergency exits can create a serious evacuation and resident-safety risk.',
        severity: RiskSeverity.critical,
        phiImpact: 10,
      ),
      recommendation: RecommendationConfig(
        title: 'Restore Emergency Exit Readiness',
        description:
            'Remove obstructions, restore accessibility and ensure emergency exits are clearly identified and available for evacuation.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.critical,
        requiredDocuments: [
          'Emergency exit inspection record',
          'Photographs of emergency exits',
          'Corrective action records',
        ],
      ),
    ),
  },
);