import '../models/report_component.dart';

class ExecutiveSummaryComponent extends ReportComponent {
  final int propertyHealthIndex;

  final int potentialPropertyHealthIndex;

  final String propertyStatus;

  final String riskLevel;

  final String nextBestAction;

  final String sureBotInsight;

  final String summary;

  final String strongestArea;

  final String weakestArea;

  final int estimatedImprovement;

  const ExecutiveSummaryComponent({
    required this.propertyHealthIndex,
    required this.potentialPropertyHealthIndex,
    required this.propertyStatus,
    required this.riskLevel,
    required this.nextBestAction,
    required this.sureBotInsight,
    required this.summary,
    required this.strongestArea,
    required this.weakestArea,
    required this.estimatedImprovement,
  });
}