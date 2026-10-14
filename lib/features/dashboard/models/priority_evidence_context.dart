import '../../../core/evidence/evidence.dart';
import '../../../core/evidence/evidence_requirement.dart';
import '../../../core/evidence/evidence_validation_result.dart';

/// Evidence context associated with one dashboard priority.
///
/// This model keeps dashboard presentation concerns separate from the
/// underlying evidence repository and validation implementation.
///
/// A priority may reference one or more evidence requirements. Each
/// requirement has its persisted evidence and the validation result
/// produced by the canonical EvidenceValidator.
class PriorityEvidenceContext {
  final EvidenceRequirement requirement;
  final List<Evidence> evidence;
  final EvidenceValidationResult validation;

  const PriorityEvidenceContext({
    required this.requirement,
    required this.evidence,
    required this.validation,
  });

  /// The canonical PHS question ID owning this requirement.
  String get questionId => requirement.questionId;

  /// The user-facing evidence requirement label.
  String get label => requirement.label;

  /// The current validation status.
  EvidenceValidationStatus get status => validation.status;

  /// Human-readable validation message.
  String get message => validation.message;

  /// Whether the requirement is fully satisfied.
  bool get isSatisfied => validation.isSatisfied;

  /// Whether evidence is missing.
  bool get isMissing =>
      status == EvidenceValidationStatus.missing;

  /// Whether evidence has been supplied but is not verified.
  bool get isProvided =>
      status == EvidenceValidationStatus.provided;

  /// Whether evidence requires review.
  bool get needsReview =>
      status == EvidenceValidationStatus.needsReview;

  /// Whether supplied evidence has been rejected.
  bool get isRejected =>
      status == EvidenceValidationStatus.rejected;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PriorityEvidenceContext &&
        other.requirement == requirement &&
        _listEquals(other.evidence, evidence) &&
        other.validation == validation;
  }

  @override
  int get hashCode => Object.hash(
        requirement,
        Object.hashAll(evidence),
        validation,
      );

  @override
  String toString() {
    return 'PriorityEvidenceContext('
        'questionId: $questionId, '
        'label: $label, '
        'status: ${status.name}'
        ')';
  }

  static bool _listEquals(
    List<Evidence> first,
    List<Evidence> second,
  ) {
    if (identical(first, second)) {
      return true;
    }

    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}