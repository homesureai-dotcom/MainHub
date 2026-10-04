import '../../../phs/phs_answer.dart';
import '../../../phs/phs_categories.dart';
import '../../../../models/property_health/property_risk.dart';
import '../../../../models/property_health/recommendation.dart';

import '../answer_config.dart';
import '../question_rule_config.dart';
import '../recommendation_config.dart';
import '../risk_config.dart';

/// Configuration for the Community Corpus rule.
///
/// COMMUNITY_CORPUS contributes to the Community & Maintenance
/// PHS category.
const QuestionRuleConfig communityCorpusRule = QuestionRuleConfig(
  questionId: 'COMMUNITY_CORPUS',
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
        title: 'Corpus Fund Status Unclear',
        description:
            'The existence, amount, or documentation of the community corpus or sinking fund could not be confirmed.',
        severity: RiskSeverity.medium,
        phiImpact: 1,
      ),
      recommendation: RecommendationConfig(
        title: 'Verify Corpus Fund Records',
        description:
            'Obtain and review the relevant financial and handover records to confirm whether the corpus or sinking fund has been established and documented.',
        estimatedPHIGain: 10,
        priority: RecommendationPriority.medium,
        requiredDocuments: [
          'Corpus fund statement',
          'Association financial records',
          'Builder handover or collection records',
        ],
      ),
    ),

    PHSResponse.no: AnswerConfig(
      score: 0.0,
      risk: RiskConfig(
        title: 'Corpus Fund Not Established',
        description:
            'A documented community corpus or sinking fund could not be confirmed.',
        severity: RiskSeverity.high,
        phiImpact: 2,
      ),
      recommendation: RecommendationConfig(
        title: 'Establish and Document Corpus Fund',
        description:
            'Verify the corpus or sinking fund arrangement and maintain clear records showing the fund amount, purpose, and applicable financial records.',
        estimatedPHIGain: 20,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Corpus fund statement',
          'Association financial records',
          'Builder handover or collection records',
        ],
      ),
    ),
  },
);