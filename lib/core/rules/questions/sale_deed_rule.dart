import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';
import '../../phs/phs_answer.dart';
import '../question_evaluation.dart';
import 'question_rule.dart';

class SaleDeedRule extends QuestionRule {
  const SaleDeedRule();

  @override
  QuestionEvaluation evaluate(PHSAnswer answer) {
    switch (answer.response) {
      case PHSResponse.yes:
        return const QuestionEvaluation(
          score: 25,
          maxScore: 25,
        );

      case PHSResponse.unsure:
        return QuestionEvaluation(
          score: 12.5,
          maxScore: 25,
          risk: PropertyRisk(
            id: "LEGAL_SD_UNSURE",
            title: "Sale Deed could not be verified",
            description:
                "The registered Sale Deed should be verified to establish ownership.",
            severity: RiskSeverity.medium,
            phiImpact: 4,
            category: "Legal",
          ),
          recommendation: Recommendation(
            id: "VERIFY_SD",
            title: "Verify Registered Sale Deed",
            description:
                "Locate and verify the registered Sale Deed.",
            estimatedPHIGain: 12,
            priority: RecommendationPriority.medium,
          ),
        );

      case PHSResponse.no:
        return QuestionEvaluation(
          score: 0,
          maxScore: 25,
          risk: PropertyRisk(
            id: "LEGAL_SD_MISSING",
            title: "Registered Sale Deed Missing",
            description:
                "Ownership cannot be established without a registered Sale Deed.",
            severity: RiskSeverity.critical,
            phiImpact: 8,
            category: "Legal",
          ),
          recommendation: Recommendation(
            id: "OBTAIN_SD",
            title: "Obtain Registered Sale Deed",
            description:
                "Complete registration and obtain the Sale Deed.",
            estimatedPHIGain: 25,
            priority: RecommendationPriority.critical,
          ),
        );
    }
  }
}