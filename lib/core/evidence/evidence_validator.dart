import 'evidence.dart';
import 'evidence_requirement.dart';
import 'evidence_requirement_matcher.dart';
import 'evidence_validation_result.dart';

/// Validates whether supplied evidence satisfies a specific
/// PHS evidence requirement.
///
/// The validator is intentionally separate from:
/// - evidence matching, which identifies relevant evidence;
/// - evidence completeness, which measures coverage;
/// - PHS scoring, which calculates the Property Health Score.
///
/// Validation is based on the lifecycle state of the matching evidence.
class EvidenceValidator {
  final EvidenceRequirementMatcher _matcher;

  const EvidenceValidator({
    EvidenceRequirementMatcher matcher =
        const EvidenceRequirementMatcher(),
  }) : _matcher = matcher;

  /// Validates one evidence requirement against supplied evidence.
  EvidenceValidationResult validate(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    final matchingEvidence = _matcher.matchingEvidence(
      requirement,
      evidence,
    );

    if (matchingEvidence.isEmpty) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.missing,
        message: 'Required evidence has not been provided.',
      );
    }

    if (matchingEvidence.any(
      (item) => item.status == EvidenceStatus.verified,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );
    }

    if (matchingEvidence.any(
      (item) => item.status == EvidenceStatus.needsReview,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.needsReview,
        message: 'Evidence requires review.',
      );
    }

    if (matchingEvidence.any(
      (item) => item.status == EvidenceStatus.provided,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.provided,
        message: 'Evidence has been provided but is not verified.',
      );
    }

    if (matchingEvidence.any(
      (item) => item.status == EvidenceStatus.rejected,
    )) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.rejected,
        message: 'Evidence was rejected.',
      );
    }

    return EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.missing,
      message: 'Required evidence has not been provided.',
    );
  }

  /// Validates every requirement against supplied evidence.
  List<EvidenceValidationResult> validateAll(
    List<EvidenceRequirement> requirements,
    List<Evidence> evidence,
  ) {
    return requirements
        .map(
          (requirement) => validate(
            requirement,
            evidence,
          ),
        )
        .toList(growable: false);
  }
}