import '../../../models/property_health/property_risk.dart';
import '../../../models/property_health/recommendation.dart';
import '../../phs/phs_answer.dart';
import '../question_evaluation.dart';
import 'question_rule.dart';

class OccupancyCertificateRule extends QuestionRule {
  const OccupancyCertificateRule();

  @override
  QuestionEvaluation evaluate(
    PHSAnswer answer,
  ) {
    switch (answer.response) {
      case PHSResponse.yes:
        return const QuestionEvaluation(
          score: 40,
          maxScore: 40,
        );

      case PHSResponse.unsure:
        return QuestionEvaluation(
          score: 20,
          maxScore: 40,
          risk: PropertyRisk(
            id: "LEGAL_OC_UNSURE",
            title: "Occupancy Certificate could not be verified",
            description:
                "The Occupancy Certificate should be verified to confirm legal occupancy.",
            severity: RiskSeverity.medium,
            phiImpact: 5,
            category: "Legal",
          ),
          recommendation: Recommendation(
            id: "UPLOAD_OC",
            title: "Upload Occupancy Certificate",
            description:
                "Upload the Occupancy Certificate to improve your Property Health Score.",
            estimatedPHIGain: 20,
            priority: RecommendationPriority.medium,
            requiredDocuments: [
              "Occupancy Certificate",
            ],
          ),
        );

      case PHSResponse.no:
        return QuestionEvaluation(
          score: 0,
          maxScore: 40,
          risk: PropertyRisk(
            id: "LEGAL_OC_MISSING",
            title: "Missing Occupancy Certificate",
            description:
                "Without an Occupancy Certificate the property may not be legally fit for occupation.",
            severity: RiskSeverity.critical,
            phiImpact: 10,
            category: "Legal",
          ),
          recommendation: Recommendation(
            id: "GET_OC",
            title: "Obtain Occupancy Certificate",
            description:
                "Contact the builder or local authority to obtain the Occupancy Certificate.",
            estimatedPHIGain: 40,
            priority: RecommendationPriority.critical,
            requiredDocuments: [
              "Occupancy Certificate",
            ],
          ),
        );
    }
  }
}