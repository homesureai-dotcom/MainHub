/// Describes the captured content associated with an evidence item.
///
/// This model deliberately remains independent of Flutter plugins and
/// platform-specific storage implementations. The [locator] identifies
/// where the captured content can be retrieved, while [kind] describes
/// the content format.
class EvidenceContent {
  /// The kind of content captured for the evidence item.
  final EvidenceContentKind kind;

  /// A storage-neutral locator for the captured content.
  ///
  /// Examples may include a local file URI, application-managed storage
  /// reference, or another future content identifier.
  final String locator;

  /// Optional user-facing label for the captured content.
  final String? label;

  EvidenceContent({
    required this.kind,
    required this.locator,
    this.label,
  }) {
    if (locator.trim().isEmpty) {
      throw ArgumentError.value(
        locator,
        'locator',
        'Evidence content locator cannot be empty.',
      );
    }
  }

  /// Creates a copy of this content with selected fields changed.
  EvidenceContent copyWith({
    EvidenceContentKind? kind,
    String? locator,
    String? label,
  }) {
    return EvidenceContent(
      kind: kind ?? this.kind,
      locator: locator ?? this.locator,
      label: label ?? this.label,
    );
  }
}

/// Supported captured-content formats for evidence.
///
/// This is intentionally separate from [EvidenceType].
///
/// [EvidenceType] describes the semantic evidence requirement, while this
/// enum describes the physical content captured or attached to satisfy it.
enum EvidenceContentKind {
  file,
  image,
  video,
  manual,
}