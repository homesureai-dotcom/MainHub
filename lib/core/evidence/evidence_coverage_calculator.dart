import 'evidence.dart';
import 'evidence_coverage.dart';
import 'evidence_requirement.dart';
import 'evidence_validator.dart';
import 'evidence_validation_result.dart';

/// Calculates evidence coverage from PHS evidence requirements and
/// supplied evidence.
///
/// This class coordinates the existing evidence components:
/// - EvidenceValidator determines the state of each requirement.
/// - EvidenceCoverage aggregates those validation results.
///
/// It does not modify PHS scoring.
class EvidenceCoverageCalculator {
  final EvidenceValidator _validator;

  const EvidenceCoverageCalculator({
    EvidenceValidator validator = const EvidenceValidator(),
  }) : _validator = validator;

  /// Validates all [requirements] and calculates their overall
  /// evidence coverage.
  EvidenceCoverage calculate({
    required List<EvidenceRequirement> requirements,
    required List<Evidence> evidence,
  }) {
    final results = _validator.validateAll(
      requirements,
      evidence,
    );

    return EvidenceCoverage.calculate(results);
  }

  /// Calculates coverage directly from already validated results.
  ///
  /// This is useful when validation has already been performed and
  /// callers want to aggregate the results without validating again.
  EvidenceCoverage calculateFromResults(
    List<EvidenceValidationResult> results,
  ) {
    return EvidenceCoverage.calculate(results);
  }

  /// Returns the validation results used to calculate coverage.
  ///
  /// This allows callers to display requirement-level evidence states
  /// alongside the aggregate coverage summary.
  List<EvidenceValidationResult> validate(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return _validator.validateAll(
      requirements,
      evidence,
    );
  }
}