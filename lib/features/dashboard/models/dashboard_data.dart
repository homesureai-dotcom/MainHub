import '../../../core/evidence/assessment_evidence_summary.dart';
import '../../../core/engine/models/property_health_result.dart';
import '../../property/models/property.dart';
import 'dashboard_priority.dart';

class DashboardData {
  final Property property;
  final PropertyHealthResult? healthResult;
  final AssessmentEvidenceSummary? evidenceSummary;
  final List<DashboardPriority> priorities;

  const DashboardData({
    required this.property,
    this.healthResult,
    this.evidenceSummary,
    this.priorities = const [],
  });

  bool get hasAssessment => healthResult != null;

  bool get isAssessmentComplete =>
      healthResult?.isComplete ?? false;

  bool get hasFinalScore =>
      healthResult?.hasFinalScore ?? false;

  double? get healthScore =>
      healthResult?.hasFinalScore == true
          ? healthResult!.overallScore
          : null;

  String? get healthGrade {
    final score = healthScore;

    if (score == null) return null;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';

    return 'Needs Immediate Attention';
  }

  int get evaluatedQuestionCount =>
      healthResult?.evaluatedQuestionCount ?? 0;

  int get totalQuestionCount =>
      healthResult?.totalQuestionCount ?? 0;

  double get questionCompletionPercentage =>
      healthResult?.questionCompletionPercentage ?? 0.0;

  int get evaluatedCategoryCount =>
      healthResult?.evaluatedCategoryCount ?? 0;

  int get totalCategoryCount =>
      healthResult?.totalCategoryCount ?? 0;

  double get categoryCompletionPercentage =>
      healthResult?.categoryCompletionPercentage ?? 0.0;

  int get riskCount =>
      healthResult?.riskCount ?? 0;

  int get recommendationCount =>
      healthResult?.recommendationCount ?? 0;

  bool get hasPriorities =>
      priorities.isNotEmpty;

  int get criticalPriorityCount =>
      priorities.where((priority) => priority.isCritical).length;

  int get highPriorityCount =>
      priorities.where((priority) => priority.isHigh).length;

  bool get hasCriticalPriorities =>
      criticalPriorityCount > 0;

  bool get hasHighPriorities =>
      highPriorityCount > 0;

  /// Whether the assessment contains any actual evidence.
  ///
  /// An AssessmentEvidenceSummary can exist even when no evidence
  /// has been uploaded because the summary is also responsible for
  /// representing the evidence requirements themselves.
  ///
  /// Evidence is considered present when at least one requirement
  /// has evidence associated with it, regardless of whether that
  /// evidence is satisfied, pending review, provided but unverified,
  /// or rejected.
  bool get hasEvidenceSummary {
    final summary = evidenceSummary;

    if (summary == null) {
      return false;
    }

    return summary.satisfiedRequirements > 0 ||
        summary.providedRequirements > 0 ||
        summary.needsReviewRequirements > 0 ||
        summary.rejectedRequirements > 0;
  }

  double get evidenceCoveragePercentage =>
      evidenceSummary?.coveragePercentage ?? 0.0;

  int get satisfiedEvidenceRequirements =>
      evidenceSummary?.satisfiedRequirements ?? 0;

  int get totalEvidenceRequirements =>
      evidenceSummary?.totalRequirements ?? 0;

  int get evidenceNeedsReviewCount =>
      evidenceSummary?.needsReviewRequirements ?? 0;

  int get missingEvidenceCount =>
      evidenceSummary?.missingRequirements ?? 0;

  int get rejectedEvidenceCount =>
      evidenceSummary?.rejectedRequirements ?? 0;

  int get activeEvidenceRiskCount =>
      evidenceSummary?.activeRiskSignalCount ?? 0;

  bool get hasEvidenceGaps =>
      evidenceSummary?.hasEvidenceGaps ?? false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DashboardData &&
        other.property == property &&
        other.healthResult == healthResult &&
        other.evidenceSummary == evidenceSummary &&
        _listEquals(other.priorities, priorities);
  }

  @override
  int get hashCode => Object.hash(
        property,
        healthResult,
        evidenceSummary,
        Object.hashAll(priorities),
      );

  @override
  String toString() {
    return 'DashboardData('
        'property: ${property.name}, '
        'hasAssessment: $hasAssessment, '
        'healthScore: $healthScore, '
        'evidenceSummary: $evidenceSummary, '
        'priorities: $priorities'
        ')';
  }

  static bool _listEquals(
    List<DashboardPriority> first,
    List<DashboardPriority> second,
  ) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}