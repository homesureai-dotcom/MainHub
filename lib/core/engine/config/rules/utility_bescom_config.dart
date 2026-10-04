import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the BESCOM utility rule.
///
/// UTILITY_BESCOM contributes to the Utilities & Infrastructure
/// PHS category.
const QuestionRuleConfig utilityBescomRule =
    QuestionRuleConfig(
  questionId: 'UTILITY_BESCOM',
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
        title: 'BESCOM electricity connection could not be verified',
        description:
            'The electricity connection should be verified to confirm that the property has a functioning and appropriately documented BESCOM connection.',
        severity: RiskSeverity.medium,
        phiImpact: 3,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify BESCOM Connection',
        description:
            'Verify the BESCOM connection details and confirm that the applicable electricity documentation is available.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'BESCOM connection details',
          'Electricity bill',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'BESCOM Electricity Connection Issue',
        description:
            'The property does not currently have a confirmed functioning BESCOM electricity connection.',
        severity: RiskSeverity.high,
        phiImpact: 7,
      ),
      recommendation: RecommendationConfig(
        title: 'Resolve BESCOM Connection',
        description:
            'Obtain or resolve the required BESCOM electricity connection and verify the supporting documentation.',
        estimatedPHIGain: 15,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'BESCOM connection details',
          'Electricity bill',
        ],
      ),
    ),
  },
);