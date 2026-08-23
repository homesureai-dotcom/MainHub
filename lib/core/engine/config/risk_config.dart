import '../../../models/property_health/property_risk.dart';

/// Configuration describing the risk generated
/// when a particular answer is selected.
class RiskConfig {
  /// Risk title.
  final String title;

  /// Detailed explanation.
  final String description;

  /// Risk severity.
  final RiskSeverity severity;

  /// Estimated impact on the Property Health Index.
  final int phiImpact;

  const RiskConfig({
    required this.title,
    required this.description,
    required this.severity,
    required this.phiImpact,
  });
}