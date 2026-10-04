import 'evidence_validation_result.dart';

/// Describes the attention level associated with an evidence gap.
enum EvidenceRiskLevel {
  none,
  low,
  medium,
  high,
}

/// Represents an evidence-related risk signal.
///
/// Risk signals describe evidence quality or completeness only.
/// They do not modify or contribute to the Property Health Score.
class EvidenceRiskSignal {
  /// The PHS question associated with the evidence requirement.
  final String questionId;

  /// The evidence requirement label.
  final String requirementLabel;

  /// The validation state that produced this signal.
  final EvidenceValidationStatus validationStatus;

  /// The attention level associated with the evidence state.
  final EvidenceRiskLevel level;

  /// Human-readable explanation of the signal.
  final String message;

  const EvidenceRiskSignal({
    required this.questionId,
    required this.requirementLabel,
    required this.validationStatus,
    required this.level,
    required this.message,
  });

  /// Whether this signal represents an evidence risk.
  bool get hasRisk => level != EvidenceRiskLevel.none;

  /// Creates a risk signal from an evidence validation result.
  factory EvidenceRiskSignal.fromValidationResult(
    EvidenceValidationResult result,
  ) {
    final level = _levelForStatus(result.status);

    return EvidenceRiskSignal(
      questionId: result.requirement.questionId,
      requirementLabel: result.requirement.label,
      validationStatus: result.status,
      level: level,
      message: _messageForStatus(result.status),
    );
  }

  static EvidenceRiskLevel _levelForStatus(
    EvidenceValidationStatus status,
  ) {
    switch (status) {
      case EvidenceValidationStatus.satisfied:
        return EvidenceRiskLevel.none;

      case EvidenceValidationStatus.provided:
        return EvidenceRiskLevel.low;

      case EvidenceValidationStatus.needsReview:
        return EvidenceRiskLevel.medium;

      case EvidenceValidationStatus.missing:
      case EvidenceValidationStatus.rejected:
        return EvidenceRiskLevel.high;
    }
  }

  static String _messageForStatus(
    EvidenceValidationStatus status,
  ) {
    switch (status) {
      case EvidenceValidationStatus.satisfied:
        return 'Evidence requirement is satisfied.';

      case EvidenceValidationStatus.provided:
        return 'Evidence has been provided but is not verified.';

      case EvidenceValidationStatus.needsReview:
        return 'Evidence requires review.';

      case EvidenceValidationStatus.missing:
        return 'Required evidence has not been provided.';

      case EvidenceValidationStatus.rejected:
        return 'Evidence was rejected.';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceRiskSignal &&
        other.questionId == questionId &&
        other.requirementLabel == requirementLabel &&
        other.validationStatus == validationStatus &&
        other.level == level &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        questionId,
        requirementLabel,
        validationStatus,
        level,
        message,
      );

  @override
  String toString() {
    return 'EvidenceRiskSignal('
        'questionId: $questionId, '
        'requirementLabel: $requirementLabel, '
        'validationStatus: ${validationStatus.name}, '
        'level: ${level.name}, '
        'message: $message'
        ')';
  }
}