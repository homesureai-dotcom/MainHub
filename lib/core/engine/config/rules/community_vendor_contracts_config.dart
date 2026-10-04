import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Community Vendor Contracts rule.
///
/// COMMUNITY_VENDOR_CONTRACTS contributes to the Community & Maintenance
/// PHS category.
const QuestionRuleConfig communityVendorContractsRule = QuestionRuleConfig(
  questionId: 'COMMUNITY_VENDOR_CONTRACTS',
  category: PHSCategory.communityMaintenance,
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
        title: 'Vendor Contract Status Unclear',
        description:
            'The availability, scope, or documentation of contracts with key community service vendors could not be confirmed.',
        severity: RiskSeverity.medium,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Vendor Contracts',
        description:
            'Obtain and review contracts with key community service providers and confirm the documented scope, responsibilities, service levels, and validity periods.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Vendor contracts',
          'Service agreements',
          'Maintenance records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Vendor Contracts Not Established',
        description:
            'Contracts with key community service providers could not be confirmed.',
        severity: RiskSeverity.high,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Establish Key Vendor Contracts',
        description:
            'Identify essential community services and establish documented contracts with appropriate vendors covering responsibilities, service scope, and applicable service terms.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Vendor contracts',
          'Service agreements',
          'Maintenance records',
        ],
      ),
    ),
  },
);