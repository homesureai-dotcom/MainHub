import 'assessment_evidence_summary.dart';
import 'evidence.dart';
import 'evidence_category_coverage.dart';
import 'evidence_coverage.dart';
import 'evidence_requirement.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validation_result.dart';
import 'evidence_validator.dart';

/// Builds an [AssessmentEvidenceSummary] from evidence requirements
/// and supplied evidence.
///
/// This builder centralizes the construction of assessment-level
/// evidence summaries. It does not modify PHS scoring and does not
/// persist evidence.
class AssessmentEvidenceSummaryBuilder {
  final EvidenceValidator _validator;

  const AssessmentEvidenceSummaryBuilder({
    required this._validator,
  });

  /// Builds an assessment-level evidence summary.
  ///
  /// [requirements] contains all evidence requirements for the
  /// assessment.
  ///
  /// [evidence] contains all evidence currently associated with
  /// the assessment.
  ///
  /// [categoryRequirements] optionally maps category IDs to the
  /// requirements belonging to each category.
  AssessmentEvidenceSummary build({
    required List<EvidenceRequirement> requirements,
    required List<Evidence> evidence,
    Map<String, List<EvidenceRequirement>> categoryRequirements =
        const {},
  }) {
    final validationResults = _validator.validateAll(
      requirements,
      evidence,
    );

    final overallCoverage = EvidenceCoverage.calculate(
      validationResults,
    );

    final riskSignals = validationResults
        .map(EvidenceRiskSignal.fromValidationResult)
        .toList(growable: false);

    final categoryCoverage = _buildCategoryCoverage(
      categoryRequirements,
      validationResults,
    );

    return AssessmentEvidenceSummary(
      overallCoverage: overallCoverage,
      validationResults: validationResults,
      riskSignals: riskSignals,
      categoryCoverage: categoryCoverage,
    );
  }

  List<EvidenceCategoryCoverage> _buildCategoryCoverage(
    Map<String, List<EvidenceRequirement>> categoryRequirements,
    List<EvidenceValidationResult> validationResults,
  ) {
    if (categoryRequirements.isEmpty) {
      return const [];
    }

    return categoryRequirements.entries
        .map(
          (entry) => EvidenceCategoryCoverage.calculateForRequirements(
            categoryId: entry.key,
            requirements: entry.value,
            results: validationResults,
          ),
        )
        .toList(growable: false);
  }
}