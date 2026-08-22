class ReportExportModel {
  final String reportId;

  final String propertyName;
  final String builderName;
  final String ownerName;

  final String address;
  final String city;
  final String state;
  final String pincode;

  final String assessmentDate;

  final int overallScore;
  final String grade;

  const ReportExportModel({
    required this.reportId,
    required this.propertyName,
    required this.builderName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.assessmentDate,
    required this.overallScore,
    required this.grade,
  });
}