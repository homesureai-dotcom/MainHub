import '../../../core/assessment/assessment_result.dart';

class AssessmentSummary {
  final AssessmentResult? latestAssessment;

  final DateTime? lastAssessmentDate;

  const AssessmentSummary({
    this.latestAssessment,
    this.lastAssessmentDate,
  });

  bool get hasAssessment =>
      latestAssessment != null;

  int get propertyHealthScore =>
      latestAssessment?.overallScore.round() ?? 0;

  String get grade =>
      latestAssessment?.grade ?? "Not Assessed";

  String get summary =>
      latestAssessment?.summary ??
      "No assessment completed.";
}