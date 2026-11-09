import '../../../core/assessment/assessment_result.dart';
import '../../../core/assessment/category_result.dart';
import '../../../core/engine/models/property_health_result.dart';
import '../../../core/phs/phs_categories.dart';
import '../../../models/property_health/property_risk.dart'
    as engine_risk;
import '../../property/models/property.dart';
import '../models/property_health_report.dart';

/// Adapts the current engine result to the existing report model.
///
/// The overall score is copied from the current engine. No second scoring
/// engine is invoked here.
class CurrentEngineReportAdapter {
  const CurrentEngineReportAdapter._();

  static PropertyHealthReport build({
    required Property property,
    required PropertyHealthResult result,
  }) {
    final categories = PHSCategory.values.map((category) {
      final percentage = result.categoryScores[category] ?? 0.0;
      final maximumScore = category.weight;
      final earnedScore = (percentage / 100.0) * maximumScore;

      return CategoryResult(
        category: category,
        earnedScore: earnedScore,
        maximumScore: maximumScore,
        weight: category.weight,
      );
    }).toList();

    final strongest = categories.reduce(
      (a, b) => a.percentage >= b.percentage ? a : b,
    );
    final weakest = categories.reduce(
      (a, b) => a.percentage <= b.percentage ? a : b,
    );

    final isFinal = result.hasFinalScore;
    final score = result.overallScore;

    final assessment = AssessmentResult(
      overallScore: score,
      grade: isFinal ? _grade(score) : 'Provisional',
      summary: isFinal
          ? _summary(score)
          : 'This assessment is incomplete. Complete all six categories before treating the score as final.',
      categoryResults: categories,
      recommendations: result.recommendations
          .map((recommendation) => recommendation.title)
          .toList(),
    );

    final reportRisks = result.risks.map((risk) {
      return ReportRisk(
        title: risk.title,
        description: risk.description,
        severity: _mapRiskSeverity(risk.severity),
      );
    }).toList();

    final reportRecommendations =
        result.recommendations.map((recommendation) {
      return ReportRecommendation(
        title: recommendation.title,
        description: recommendation.description,
        expectedScoreIncrease: recommendation.estimatedPHIGain,
        estimatedTimeline: 'Review with the relevant professional',
      );
    }).toList();

    return PropertyHealthReport(
      propertyName: property.name,
      builderName: property.builderName,
      ownerName: property.ownerName,
      address: property.address.line1,
      city: property.address.city,
      state: property.address.state,
      pincode: property.address.pincode,
      assessmentDate: result.evaluatedAt,
      assessment: assessment,
      risks: reportRisks,
      recommendations: reportRecommendations,
      missingDocuments: const [],
      aiInsights: [
        if (!isFinal)
          'Partial assessment: the score is provisional and must not be treated as a final Property Health Score.',
        'Strongest category in this assessment: ${strongest.category.displayName} (${strongest.percentage.round()}%).',
        'Lowest category in this assessment: ${weakest.category.displayName} (${weakest.percentage.round()}%).',
        'This report reflects the answers provided. It is not a legal certification or independent verification of the property.',
      ],
    );
  }

  static String _grade(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Attention';
  }

  static String _summary(double score) {
    if (score >= 90) {
      return 'The assessment indicates a strong result. Review supporting evidence and documents before making a property decision.';
    }
    if (score >= 75) {
      return 'The assessment identified areas that may benefit from further review.';
    }
    if (score >= 60) {
      return 'The assessment identified gaps that should be reviewed and addressed.';
    }
    return 'The assessment identified significant gaps that warrant further investigation.';
  }

  static RiskSeverity _mapRiskSeverity(
    engine_risk.RiskSeverity severity,
  ) {
    switch (severity) {
      case engine_risk.RiskSeverity.critical:
        return RiskSeverity.critical;
      case engine_risk.RiskSeverity.high:
        return RiskSeverity.high;
      case engine_risk.RiskSeverity.medium:
        return RiskSeverity.medium;
      case engine_risk.RiskSeverity.low:
        return RiskSeverity.low;
    }
  }
}
