import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the BWSSB utility rule.
///
/// UTILITY_BWSSB contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityBwssbRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_BWSSB',
  category: PHSCategory.utilitiesInfrastructure,
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
        title: 'Water and sewerage connection could not be verified',
        description:
            "The property's water and sewerage connectivity should be verified, including the applicable BWSSB documentation.",
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify BWSSB Connectivity',
        description:
            'Verify the applicable water and sewerage connections and confirm that the supporting BWSSB documentation is available.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'BWSSB connection details',
          'BWSSB documentation',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'BWSSB Water or Sewerage Connectivity Issue',
        description:
            'The property does not currently have a confirmed operational water and sewerage connection.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Resolve BWSSB Connectivity',
        description:
            'Resolve the applicable water or sewerage connectivity issue and verify the supporting BWSSB documentation.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'BWSSB connection details',
          'BWSSB documentation',
        ],
      ),
    ),
  },
);