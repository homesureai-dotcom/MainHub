import 'evidence.dart';

/// Represents one piece of evidence required by a PHS question.
///
/// The requirement is derived directly from the PHS question's
/// existing `requiredEvidence` value. It does not replace or
/// duplicate the PHS question definition.
class EvidenceRequirement {
  /// The PHS question that owns this requirement.
  final String questionId;

  /// The original evidence label defined by the PHS question.
  final String label;

  /// The evidence type inferred from the existing PHS evidence label.
  final EvidenceType type;

  const EvidenceRequirement({
    required this.questionId,
    required this.label,
    required this.type,
  });

  /// Whether this requirement expects a document.
  bool get isDocument => type == EvidenceType.document;

  /// Whether this requirement expects a photograph.
  bool get isPhotograph => type == EvidenceType.photograph;

  /// Whether this requirement expects a video.
  bool get isVideo => type == EvidenceType.video;

  /// Whether this requirement is satisfied by manual evidence.
  bool get isManual => type == EvidenceType.manual;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EvidenceRequirement &&
        other.questionId == questionId &&
        other.label == label &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(
        questionId,
        label,
        type,
      );

  @override
  String toString() {
    return 'EvidenceRequirement('
        'questionId: $questionId, '
        'label: $label, '
        'type: $type'
        ')';
  }
}