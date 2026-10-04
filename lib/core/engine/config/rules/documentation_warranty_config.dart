import '../../../../core/phs/phs_answer.dart';
import '../../../../core/phs/phs_categories.dart';
import '../../../../models/property_health/recommendation.dart';
import '../../../../models/property_health/property_risk.dart';
import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Warranty Documentation rule.
///
/// DOCUMENTATION_WARRANTY contributes to the
/// Documentation PHS category.
const QuestionRuleConfig documentationWarrantyRule =
    QuestionRuleConfig(
  questionId: 'DOCUMENTATION_WARRANTY',
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
        title: 'Warranty Documents Need Verification',
        description:
            'Applicable builder, equipment, appliance, waterproofing, or system warranty coverage has not been fully verified.',
        severity: RiskSeverity.low,
        phiImpact: -1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Warranty Coverage',
        description:
            'Verify the applicable warranty documents, coverage periods, exclusions, and claim procedures.',
        estimatedPHIGain: 1,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Builder warranty documents',
          'Equipment/appliance warranty documents',
          'Waterproofing/system warranty records',
        ],
      ),
    ),
    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Warranty Documents Missing',
        description:
            'Applicable warranty documentation has not been provided or verified.',
        severity: RiskSeverity.medium,
        phiImpact: -2,
      ),
      recommendation: RecommendationConfig(
        title: 'Collect Warranty Documents',
        description:
            'Collect and retain applicable builder, equipment, appliance, waterproofing, and system warranty documentation.',
        estimatedPHIGain: 2,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Builder warranty documents',
          'Equipment/appliance warranty documents',
          'Waterproofing/system warranty records',
        ],
      ),
    ),
  },
);