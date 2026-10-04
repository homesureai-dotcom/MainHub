import 'evidence.dart';
import 'evidence_category_coverage.dart';
import 'evidence_coverage.dart';
import 'evidence_requirement.dart';
import 'evidence_requirement_matcher.dart';
import 'evidence_risk_signal.dart';
import 'evidence_validation_result.dart';
import 'evidence_validator.dart';

/// Provides assessment-level evidence validation and coverage.
///
/// This service coordinates the existing evidence domain components.
/// It does not modify PHS scoring and does not persist evidence.
class AssessmentEvidenceValidationService {
  final EvidenceValidator _validator;
  final EvidenceRequirementMatcher _matcher;

  const AssessmentEvidenceValidationService({
    required this._validator,
    required this._matcher,
  });

  /// Validates all evidence requirements against supplied evidence.
  List<EvidenceValidationResult> validate(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return _validator.validateAll(
      requirements,
      evidence,
    );
  }

  /// Calculates overall evidence coverage for an assessment.
  EvidenceCoverage calculateCoverage(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    final results = validate(
      requirements,
      evidence,
    );

    return EvidenceCoverage.calculate(results);
  }

  /// Calculates evidence coverage for a specific category.
  ///
  /// Only requirements belonging to [requirements] are included.
  EvidenceCategoryCoverage calculateCategoryCoverage({
    required String categoryId,
    required List<EvidenceRequirement> requirements,
    required List<Evidence> evidence,
  }) {
    final results = validate(
      requirements,
      evidence,
    );

    return EvidenceCategoryCoverage.calculate(
      categoryId: categoryId,
      results: results,
    );
  }

  /// Creates evidence risk signals for all supplied requirements.
  ///
  /// Satisfied requirements produce signals with [EvidenceRiskLevel.none].
  List<EvidenceRiskSignal> generateRiskSignals(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    final results = validate(
      requirements,
      evidence,
    );

    return results
        .map(EvidenceRiskSignal.fromValidationResult)
        .toList(growable: false);
  }

  /// Returns only requirements that currently have no matching evidence.
  List<EvidenceRequirement> getMissingRequirements(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return requirements
        .where(
          (requirement) => !_matcher.hasMatch(
            requirement,
            evidence,
          ),
        )
        .toList(growable: false);
  }

  /// Returns whether every supplied evidence requirement has a matching
  /// evidence item.
  ///
  /// This checks evidence presence/matching only. It does not determine
  /// whether the evidence is verified or otherwise satisfied.
  bool hasEvidenceForAllRequirements(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return requirements.every(
      (requirement) => _matcher.hasMatch(
        requirement,
        evidence,
      ),
    );
  }

  /// Returns all evidence items matching a specific requirement.
  List<Evidence> getMatchingEvidence(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    return _matcher.matchingEvidence(
      requirement,
      evidence,
    );
  }

  /// Returns only validation results that represent evidence gaps.
  List<EvidenceValidationResult> getEvidenceGaps(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return validate(
      requirements,
      evidence,
    ).where(
      (result) => !result.isSatisfied,
    ).toList(growable: false);
  }
}