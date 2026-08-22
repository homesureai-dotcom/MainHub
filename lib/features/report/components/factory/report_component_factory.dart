import '../../models/property_health_report.dart';
import '../executive_summary/executive_summary_component.dart';
import '../../../../core/phs/phs_categories.dart';


class ReportComponentFactory {
  const ReportComponentFactory._();

  static ExecutiveSummaryComponent buildExecutiveSummary(
    PropertyHealthReport report,
  ) {
    final currentPHI = report.assessment.overallScore.round();

    final estimatedImprovement = report.recommendations.fold<int>(
      0,
      (sum, recommendation) =>
          sum + recommendation.expectedScoreIncrease,
    );

    final potentialPHI =
        (currentPHI + estimatedImprovement).clamp(0, 100);

    final strongestCategory =
        report.assessment.categoryResults.reduce(
      (a, b) => a.percentage > b.percentage ? a : b,
    );

    final weakestCategory =
        report.assessment.categoryResults.reduce(
      (a, b) => a.percentage < b.percentage ? a : b,
    );

    return ExecutiveSummaryComponent(
      propertyHealthIndex: currentPHI,
      potentialPropertyHealthIndex: potentialPHI,
      propertyStatus: _propertyStatus(currentPHI),
      riskLevel: _riskLevel(report),
      nextBestAction: report.recommendations.isEmpty
          ? "No action required"
          : report.recommendations.first.title,
      sureBotInsight: report.aiInsights.isEmpty
          ? "No AI insight available."
          : report.aiInsights.first,
      summary: report.assessment.summary,
      strongestArea: strongestCategory.category.displayName,
      weakestArea: weakestCategory.category.displayName,
      estimatedImprovement: estimatedImprovement,
    );
  }

  static String _propertyStatus(int phi) {
    if (phi >= 90) return "Certified Healthy";
    if (phi >= 75) return "Healthy";
    if (phi >= 60) return "Needs Attention";
    if (phi >= 40) return "High Risk";
    return "Critical";
  }

  static String _riskLevel(PropertyHealthReport report) {
    if (report.risks.any(
      (risk) => risk.severity == RiskSeverity.critical,
    )) {
      return "Critical";
    }

    if (report.risks.any(
      (risk) => risk.severity == RiskSeverity.high,
    )) {
      return "High";
    }

    if (report.risks.any(
      (risk) => risk.severity == RiskSeverity.medium,
    )) {
      return "Medium";
    }

    return "Low";
  }
}