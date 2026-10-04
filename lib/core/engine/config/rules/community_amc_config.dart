import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Community AMC rule.
///
/// COMMUNITY_AMC contributes to the Community & Maintenance
/// PHS category.
const QuestionRuleConfig communityAmcRule = QuestionRuleConfig(
  questionId: 'COMMUNITY_AMC',
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
        title: 'AMC Coverage Status Unclear',
        description:
            'The availability, scope, or documentation of applicable annual maintenance contracts could not be confirmed.',
        severity: RiskSeverity.medium,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify AMC Coverage',
        description:
            'Obtain and review the active annual maintenance contracts and confirm that critical community systems and services are covered.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'AMC agreements',
          'Active vendor contracts',
          'Maintenance service records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'AMC Coverage Not Established',
        description:
            'Required annual maintenance contracts for community systems or services could not be confirmed.',
        severity: RiskSeverity.high,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Establish Required AMC Contracts',
        description:
            'Identify critical community systems and establish appropriate annual maintenance contracts with documented service coverage and responsibilities.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'AMC agreements',
          'Vendor contracts',
          'Maintenance service records',
        ],
      ),
    ),
  },
);