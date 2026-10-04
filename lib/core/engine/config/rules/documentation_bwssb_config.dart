import '../../../../core/phs/phs_answer.dart';
import '../../../../core/phs/phs_categories.dart';
import '../../../../models/property_health/recommendation.dart';
import '../../../../models/property_health/property_risk.dart';
import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the BWSSB Documentation rule.
///
/// DOCUMENTATION_BWSSB contributes to the
/// Documentation PHS category.
const QuestionRuleConfig documentationBwssbRule =
    QuestionRuleConfig(
  questionId: 'DOCUMENTATION_BWSSB',
  category: PHSCategory.documentation,
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
        title: 'BWSSB Documentation Needs Verification',
        description:
            'Water and sewerage connection, billing, approval, demand, or payment records have not been fully verified.',
        severity: RiskSeverity.medium,
        phiImpact: -1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify BWSSB Records',
        description:
            'Verify the applicable BWSSB water and sewerage connection, billing, approval, demand, and payment documentation.',
        estimatedPHIGain: 1,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'BWSSB connection records',
          'Latest BWSSB bill or demand/payment record',
          'Applicable BWSSB approval/supporting records',
        ],
      ),
    ),
    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'BWSSB Documentation Missing',
        description:
            'Required BWSSB water and sewerage documentation has not been provided or verified.',
        severity: RiskSeverity.high,
        phiImpact: -2,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain BWSSB Documentation',
        description:
            'Obtain and verify the applicable BWSSB water and sewerage connection, billing, approval, demand, and payment records.',
        estimatedPHIGain: 2,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'BWSSB connection records',
          'Latest BWSSB bill or demand/payment record',
          'Applicable BWSSB approval/supporting records',
        ],
      ),
    ),
  },
);