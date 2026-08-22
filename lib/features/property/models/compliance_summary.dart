class ComplianceSummary {
  final int verifiedCount;

  final int pendingCount;

  final int issueCount;

  final double compliancePercentage;

  const ComplianceSummary({
    required this.verifiedCount,
    required this.pendingCount,
    required this.issueCount,
    required this.compliancePercentage,
  });

  int get totalItems =>
      verifiedCount + pendingCount + issueCount;

  bool get hasIssues => issueCount > 0;

  bool get isFullyCompliant =>
      pendingCount == 0 && issueCount == 0;
}