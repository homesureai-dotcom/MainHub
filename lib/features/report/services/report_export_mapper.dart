import '../../../core/phs/phs_categories.dart';
import '../models/property_health_report.dart';
import '../models/report_export_model.dart';

class ReportExportMapper {
  const ReportExportMapper._();

  static ReportExportModel fromReport(
    PropertyHealthReport report, {
    String languageCode = 'en',
  }) {
    final date = report.assessmentDate;
    final formattedDate =
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";

    final reportId =
        "HS-${date.year}"
        "${date.month.toString().padLeft(2, '0')}"
        "${date.day.toString().padLeft(2, '0')}-"
        "${report.assessment.overallScore.round()}";

    return ReportExportModel(
      reportId: reportId,
      propertyName: report.propertyName,
      builderName: report.builderName,
      ownerName: report.ownerName,
      address: report.address,
      city: report.city,
      state: report.state,
      pincode: report.pincode,
      assessmentDate: formattedDate,
      overallScore: report.assessment.overallScore.round(),
      grade: report.assessment.grade,
      summary: report.assessment.summary,
      categories: report.assessment.categoryResults.map((category) {
        return ReportExportCategory(
          name: category.category.displayName,
          percentage: category.percentage,
          weight: category.weight,
          weightedContribution: category.weightedContribution,
        );
      }).toList(),
      risks: report.risks.map((risk) {
        return ReportExportRisk(
          title: risk.title,
          description: risk.description,
          severity: risk.severity.name,
        );
      }).toList(),
      recommendations: report.recommendations.map((item) {
        return ReportExportRecommendation(
          title: item.title,
          description: item.description,
          expectedScoreIncrease: item.expectedScoreIncrease,
          estimatedTimeline: item.estimatedTimeline,
        );
      }).toList(),
      missingDocuments: report.missingDocuments.map((item) {
        return ReportExportDocument(name: item.name, mandatory: item.mandatory);
      }).toList(),
      aiInsights: List<String>.unmodifiable(report.aiInsights),
      languageCode:
          const {'en', 'kn', 'hi', 'te', 'ta', 'ml'}.contains(languageCode)
          ? languageCode
          : 'en',
    );
  }
}
