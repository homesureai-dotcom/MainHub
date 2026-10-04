import '../../../../core/phs/phs_answer.dart';
import '../../../../core/phs/phs_categories.dart';
import '../../../../models/property_health/recommendation.dart';
import '../../../../models/property_health/property_risk.dart';
import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Maintenance Manuals Documentation rule.
///
/// DOCUMENTATION_MANUALS contributes to the
/// Documentation PHS category.
const QuestionRuleConfig documentationManualsRule =
    QuestionRuleConfig(
  questionId: 'DOCUMENTATION_MANUALS',
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
        title: 'Maintenance Records Need Verification',
        description:
            'O&M manuals, asset registers, handover documents, or equipment service records have not been fully verified.',
        severity: RiskSeverity.low,
        phiImpact: -1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Maintenance Documentation',
        description:
            'Verify the availability and completeness of O&M manuals, asset records, handover documents, and equipment service records.',
        estimatedPHIGain: 1,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'O&M manuals',
          'Asset register',
          'Handover documentation',
          'Equipment service records',
        ],
      ),
    ),
    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Maintenance Manuals Missing',
        description:
            'Required maintenance, O&M, handover, or equipment service documentation has not been provided or verified.',
        severity: RiskSeverity.medium,
        phiImpact: -2,
      ),
      recommendation: RecommendationConfig(
        title: 'Collect Maintenance and Handover Records',
        description:
            'Collect the applicable O&M manuals, asset register, handover documentation, and equipment service records.',
        estimatedPHIGain: 2,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'O&M manuals',
          'Asset register',
          'Handover documentation',
          'Equipment service records',
        ],
      ),
    ),
  },
);