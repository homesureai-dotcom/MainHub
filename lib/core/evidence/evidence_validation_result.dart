import 'evidence_requirement.dart';

/// Describes the validation state of a single evidence requirement.
enum EvidenceValidationStatus {
  /// No evidence has been supplied for the requirement.
  missing,

  /// Evidence has been supplied but has not yet been verified.
  provided,

  /// Evidence has been verified and satisfies the requirement.
  satisfied,

  /// Evidence has been supplied but requires additional review.
  needsReview,

  /// Evidence was supplied but rejected.
  rejected,
}

/// Represents the validation result for one evidence requirement.
///
/// This model is intentionally independent of the PHS scoring engine.
/// Evidence validation answers whether a required piece of evidence
/// has been adequately supplied; it does not change the PHS score.
class EvidenceValidationResult {
  /// The evidence requirement being evaluated.
  final EvidenceRequirement requirement;

  /// The validation status assigned to the requirement.
  final EvidenceValidationStatus status;

  /// Human-readable explanation of the validation result.
  final String message;

  const EvidenceValidationResult({
    required this.requirement,
    required this.status,
    required this.message,
  });

  /// Whether the evidence requirement is fully satisfied.
  bool get isSatisfied =>
      status == EvidenceValidationStatus.satisfied;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceValidationResult &&
        other.requirement == requirement &&
        other.status == status &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        requirement,
        status,
        message,
      );

  @override
  String toString() {
    return 'EvidenceValidationResult('
        'requirement: ${requirement.questionId}, '
        'label: ${requirement.label}, '
        'status: ${status.name}, '
        'message: $message'
        ')';
  }
}