import '../../core/phs/phs_answer.dart';
import '../../models/property_health/property_risk.dart';

/// Generates Property Health risks from assessment answers.
///
/// This engine is responsible ONLY for identifying risks.
/// It does not calculate scores or generate recommendations.
class RiskEngine {
  const RiskEngine();

  /// Evaluates the assessment answers and returns the
  /// identified property risks.
  ///
  /// Currently this returns an empty list.
  /// Business rules will be implemented incrementally.
  List<PropertyRisk> evaluate(
    List<PHSAnswer> answers,
  ) {
    // TODO: Implement risk evaluation rules.
    return const <PropertyRisk>[];
  }
}