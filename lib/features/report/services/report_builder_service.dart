import '../../../core/assessment/assessment_result.dart';
import '../../../core/phs/phs_categories.dart';
import '../../property/models/property.dart';

import '../models/property_health_report.dart';

class ReportBuilderService {
  const ReportBuilderService();

  PropertyHealthReport build({
    required Property property,
    required AssessmentResult assessment,
  }) {
    return PropertyHealthReport(
      propertyName: property.name,
      builderName: property.builderName,
      ownerName: property.ownerName,
      address: property.address.line1,
      city: property.address.city,
      state: property.address.state,
      pincode: property.address.pincode,
      assessmentDate: DateTime.now(),
      assessment: assessment,
      risks: _generateRisks(assessment),
      recommendations: _generateRecommendations(assessment),
      missingDocuments: _generateMissingDocuments(assessment),
      aiInsights: _generateInsights(assessment),
    );
  }

  List<ReportRisk> _generateRisks(
    AssessmentResult result,
  ) {
    final risks = <ReportRisk>[];

    if (result.overallScore < 60) {
      risks.add(
        const ReportRisk(
          title: "Overall Property Health",
          description:
              "The property has significant compliance gaps requiring immediate attention.",
          severity: RiskSeverity.critical,
        ),
      );
    }

    for (final category in result.categoryResults) {
      if (category.percentage < 50) {
        risks.add(
          ReportRisk(
            title: category.category.displayName,
            description:
                "This category requires immediate attention.",
            severity: RiskSeverity.high,
          ),
        );
      }
    }

    return risks;
  }

  List<ReportRecommendation> _generateRecommendations(
    AssessmentResult result,
  ) {
    final recommendations = <ReportRecommendation>[];

    for (final category in result.categoryResults) {
      if (category.percentage < 70) {
        recommendations.add(
          ReportRecommendation(
            title: "Improve ${category.category.displayName}",
            description:
                "Complete the pending compliance activities for this category.",
            expectedScoreIncrease: 5,
            estimatedTimeline: "30 Days",
          ),
        );
      }
    }

    return recommendations;
  }

  List<MissingDocument> _generateMissingDocuments(
    AssessmentResult result,
  ) {
    return const [
      MissingDocument(
        name: "Fire NOC",
        mandatory: true,
      ),
      MissingDocument(
        name: "BESCOM RR Number",
        mandatory: true,
      ),
      MissingDocument(
        name: "BWSSB Connection",
        mandatory: false,
      ),
    ];
  }

  List<String> _generateInsights(
    AssessmentResult result,
  ) {
    final insights = <String>[];

    if (result.overallScore >= 90) {
      insights.add(
        "Your property demonstrates excellent overall health with very few compliance risks.",
      );
    } else if (result.overallScore >= 75) {
      insights.add(
        "Your property is generally healthy, but addressing a few compliance gaps will further improve its value.",
      );
    } else if (result.overallScore >= 60) {
      insights.add(
        "The property has moderate compliance gaps that should be addressed before resale or financing.",
      );
    } else {
      insights.add(
        "Your property has significant compliance risks that should be resolved as soon as possible.",
      );
    }

    insights.add(
      "Improving the lowest scoring category will have the greatest impact on your Property Health Score.",
    );

    return insights;
  }
}