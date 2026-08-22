/// Severity of a Property Health risk.
enum RiskSeverity {
  critical,
  high,
  medium,
  low,
}

/// Represents a risk identified during the assessment.
class PropertyRisk {
  /// Unique identifier.
  final String id;

  /// Risk title.
  final String title;

  /// Detailed description.
  final String description;

  /// Severity of the risk.
  final RiskSeverity severity;

  /// Estimated Property Health impact.
  final int phiImpact;

  /// Category this risk belongs to.
  final String category;

  const PropertyRisk({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.phiImpact,
    required this.category,
  });

  bool get isCritical => severity == RiskSeverity.critical;

  bool get isHigh => severity == RiskSeverity.high;

  @override
  String toString() {
    return 'PropertyRisk(title: $title, severity: $severity)';
  }
}