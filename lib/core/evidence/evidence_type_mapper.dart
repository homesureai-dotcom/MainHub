import 'evidence.dart';

/// Maps the existing PHS required-evidence labels to the
/// evidence types supported by the Sprint 9 evidence model.
///
/// The PHS question definitions remain the source of truth for
/// the evidence names themselves. This mapper only classifies
/// those names for downstream evidence workflows.
class EvidenceTypeMapper {
  const EvidenceTypeMapper();

  /// Determines the evidence type for an existing PHS
  /// `requiredEvidence` label.
  ///
  /// The mapping is intentionally conservative:
  /// - Explicit photographs/inspection photographs -> photograph
  /// - Explicit video evidence -> video
  /// - Everything else -> document
  ///
  /// This means we do not invent a new evidence type when the
  /// PHS question does not explicitly require one.
  EvidenceType map(String evidenceLabel) {
    final normalized = evidenceLabel.trim().toLowerCase();

    if (normalized.contains('photograph') ||
        normalized.contains('photo')) {
      return EvidenceType.photograph;
    }

    if (normalized.contains('video')) {
      return EvidenceType.video;
    }

    return EvidenceType.document;
  }

  /// Returns the mapped type for every required-evidence item.
  List<EvidenceType> mapAll(List<String> evidenceLabels) {
    return evidenceLabels.map(map).toList(growable: false);
  }
}