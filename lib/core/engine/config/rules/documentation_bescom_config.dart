import '../../../../core/phs/phs_answer.dart';
import '../../../../core/phs/phs_categories.dart';
import '../../../../models/property_health/recommendation.dart';
import '../../../../models/property_health/property_risk.dart';
import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the BESCOM Documentation rule.
///
/// DOCUMENTATION_BESCOM contributes to the
/// Documentation PHS category.
const QuestionRuleConfig documentationBescomRule =
    QuestionRuleConfig(
  questionId: 'DOCUMENTATION_BESCOM',
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
        title: 'BESCOM Documentation Needs Verification',
        description:
            'Electricity connection, metering, billing, or supporting BESCOM records have not been fully verified.',
        severity: RiskSeverity.medium,
        phiImpact: -1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify BESCOM Records',
        description:
            'Verify the BESCOM electricity connection, meter details, billing records, and applicable supporting documentation.',
        estimatedPHIGain: 1,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'BESCOM connection details',
          'Latest BESCOM bill',
          'Applicable BESCOM supporting records',
        ],
      ),
    ),
    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'BESCOM Documentation Missing',
        description:
            'Required BESCOM electricity connection, metering, billing, or supporting records have not been provided or verified.',
        severity: RiskSeverity.high,
        phiImpact: -2,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain BESCOM Documentation',
        description:
            'Obtain and verify the applicable BESCOM electricity connection, meter, billing, and supporting documentation.',
        estimatedPHIGain: 2,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'BESCOM connection details',
          'Latest BESCOM bill',
          'Applicable BESCOM supporting records',
        ],
      ),
    ),
  },
);