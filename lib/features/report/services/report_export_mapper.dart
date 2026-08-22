import '../models/property_health_report.dart';
import '../models/report_export_model.dart';

class ReportExportMapper {
  const ReportExportMapper._();

  static ReportExportModel fromReport(
    PropertyHealthReport report,
  ) {
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
    );
  }
}