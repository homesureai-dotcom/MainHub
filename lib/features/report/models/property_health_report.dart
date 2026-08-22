import '../../../core/assessment/assessment_result.dart';

class PropertyHealthReport {
  /// Property Information
  final String propertyName;
  final String builderName;
  final String ownerName;
  final String address;
  final String city;
  final String state;
  final String pincode;

  /// Assessment Information
  final DateTime assessmentDate;
  final AssessmentResult assessment;

  /// Report Sections
  final List<ReportRisk> risks;
  final List<ReportRecommendation> recommendations;
  final List<MissingDocument> missingDocuments;
  final List<String> aiInsights;

  const PropertyHealthReport({
    required this.propertyName,
    required this.builderName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.assessmentDate,
    required this.assessment,
    required this.risks,
    required this.recommendations,
    required this.missingDocuments,
    required this.aiInsights,
  });
}

enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

class ReportRisk {
  final String title;
  final String description;
  final RiskSeverity severity;

  const ReportRisk({
    required this.title,
    required this.description,
    required this.severity,
  });
}

class ReportRecommendation {
  final String title;
  final String description;

  /// Expected score improvement
  final int expectedScoreIncrease;

  /// Estimated completion time
  final String estimatedTimeline;

  const ReportRecommendation({
    required this.title,
    required this.description,
    required this.expectedScoreIncrease,
    required this.estimatedTimeline,
  });
}

class MissingDocument {
  final String name;
  final bool mandatory;

  const MissingDocument({
    required this.name,
    required this.mandatory,
  });
}