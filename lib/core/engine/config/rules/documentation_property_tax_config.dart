import '../../../../core/phs/phs_answer.dart';
import '../../../../core/phs/phs_categories.dart';
import '../../../../models/property_health/recommendation.dart';
import '../../../../models/property_health/property_risk.dart';
import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Property Tax Documentation rule.
///
/// DOCUMENTATION_PROPERTY_TAX contributes to the
/// Documentation PHS category.
const QuestionRuleConfig documentationPropertyTaxRule =
    QuestionRuleConfig(
  questionId: 'DOCUMENTATION_PROPERTY_TAX',
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
        title: 'Property Tax Records Need Verification',
        description:
            'The property tax records have not been fully verified and should be checked for completeness and currency.',
        severity: RiskSeverity.medium,
        phiImpact: -1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Property Tax Records',
        description:
            'Verify the latest property tax receipt, payment status, and applicable property tax assessment records.',
        estimatedPHIGain: 1,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Latest property tax receipt',
          'Property tax assessment details',
        ],
      ),
    ),
    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Property Tax Records Missing',
        description:
            'Current property tax records have not been provided or verified.',
        severity: RiskSeverity.high,
        phiImpact: -2,
      ),
      recommendation: RecommendationConfig(
        title: 'Obtain and Update Property Tax Records',
        description:
            'Obtain the latest property tax records and verify that applicable property taxes are paid and up to date.',
        estimatedPHIGain: 2,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Latest property tax receipt',
          'Property tax assessment details',
        ],
      ),
    ),
  },
);