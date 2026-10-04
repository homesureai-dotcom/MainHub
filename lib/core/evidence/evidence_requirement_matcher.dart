import 'evidence.dart';
import 'evidence_requirement.dart';

/// Determines whether supplied evidence corresponds to a specific
/// PHS evidence requirement.
///
/// Matching is requirement-specific:
/// - The evidence must belong to the same PHS question.
/// - The evidence type must match the requirement type.
/// - When an explicit requirement ID is available, it must match exactly.
/// - Otherwise the evidence is matched using the requirement type and
///   evidence naming information where appropriate.
///
/// This class does not determine whether evidence is verified,
/// sufficient, authentic, or acceptable. Those decisions belong
/// to the validation layer.
class EvidenceRequirementMatcher {
  const EvidenceRequirementMatcher();

  /// Returns true when [evidence] matches [requirement].
  bool matches(
    Evidence evidence,
    EvidenceRequirement requirement,
  ) {
    if (evidence.questionId != requirement.questionId) {
      return false;
    }

    if (evidence.type != requirement.type) {
      return false;
    }

    final expectedRequirementId = Evidence.requirementKey(
      questionId: requirement.questionId,
      label: requirement.label,
    );

    if (evidence.requirementId != null) {
      return evidence.requirementId == expectedRequirementId;
    }

    return _matchesWithoutExplicitRequirementId(
      evidence,
      requirement,
    );
  }

  /// Returns all supplied evidence that matches [requirement].
  List<Evidence> matchingEvidence(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    return evidence
        .where(
          (item) => matches(item, requirement),
        )
        .toList(growable: false);
  }

  /// Returns true when at least one supplied evidence item matches
  /// [requirement].
  bool hasMatch(
    EvidenceRequirement requirement,
    List<Evidence> evidence,
  ) {
    return evidence.any(
      (item) => matches(item, requirement),
    );
  }

  bool _matchesWithoutExplicitRequirementId(
    Evidence evidence,
    EvidenceRequirement requirement,
  ) {
    final normalizedLabel = _normalize(requirement.label);
    final normalizedName = _normalize(evidence.name);
    final normalizedDescription =
        _normalize(evidence.description ?? '');

    // An exact or contained textual match is sufficient when available.
    if (normalizedLabel.isNotEmpty &&
        (normalizedName.contains(normalizedLabel) ||
            normalizedDescription.contains(normalizedLabel))) {
      return true;
    }

    // Photograph, video, and manual evidence can legitimately use
    // descriptive filenames that do not repeat the requirement label.
    //
    // For these evidence types, question identity + evidence type is
    // sufficient unless an explicit requirement ID says otherwise.
    if (requirement.type == EvidenceType.photograph ||
        requirement.type == EvidenceType.video ||
        requirement.type == EvidenceType.manual) {
      return true;
    }

    // Documents remain conservative because a single PHS question can
    // contain multiple document requirements. Without an explicit
    // requirement ID or textual match, do not assume that one document
    // satisfies every document requirement.
    return false;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\.[a-z0-9]+$'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}