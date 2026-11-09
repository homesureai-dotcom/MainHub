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
  final String summary;
  final List<ReportExportCategory> categories;
  final List<ReportExportRisk> risks;
  final List<ReportExportRecommendation> recommendations;
  final List<ReportExportDocument> missingDocuments;
  final List<String> aiInsights;
  final String languageCode;

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
    required this.summary,
    required this.categories,
    required this.risks,
    required this.recommendations,
    required this.missingDocuments,
    required this.aiInsights,
    this.languageCode = 'en',
  });
}

class ReportExportCategory {
  final String name;
  final double percentage;
  final double weight;
  final double weightedContribution;

  const ReportExportCategory({
    required this.name,
    required this.percentage,
    required this.weight,
    required this.weightedContribution,
  });
}

class ReportExportRisk {
  final String title;
  final String description;
  final String severity;

  const ReportExportRisk({
    required this.title,
    required this.description,
    required this.severity,
  });
}

class ReportExportRecommendation {
  final String title;
  final String description;
  final int expectedScoreIncrease;
  final String estimatedTimeline;

  const ReportExportRecommendation({
    required this.title,
    required this.description,
    required this.expectedScoreIncrease,
    required this.estimatedTimeline,
  });
}

class ReportExportDocument {
  final String name;
  final bool mandatory;

  const ReportExportDocument({required this.name, required this.mandatory});
}
