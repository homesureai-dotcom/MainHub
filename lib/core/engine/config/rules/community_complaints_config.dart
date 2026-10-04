import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Community Complaints rule.
///
/// COMMUNITY_COMPLAINTS contributes to the Community & Maintenance
/// PHS category.
const QuestionRuleConfig communityComplaintsRule = QuestionRuleConfig(
  questionId: 'COMMUNITY_COMPLAINTS',
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
        title: 'Complaint Resolution Process Unclear',
        description:
            'The availability or effectiveness of a documented process for recording and resolving community complaints could not be confirmed.',
        severity: RiskSeverity.medium,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Complaint Resolution Process',
        description:
            'Review the community complaint register or management process and confirm how resident complaints are recorded, assigned, tracked, and resolved.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Complaint register',
          'Complaint resolution records',
          'Community management procedures',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Complaint Resolution Process Not Established',
        description:
            'A documented and functioning process for recording and resolving community complaints could not be confirmed.',
        severity: RiskSeverity.high,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Establish Complaint Resolution Process',
        description:
            'Establish a documented process for residents to submit complaints and ensure that issues are assigned, tracked, resolved, and recorded.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Complaint register',
          'Complaint resolution records',
          'Community management procedures',
        ],
      ),
    ),
  },
);