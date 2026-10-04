import 'evidence_content.dart';

/// Represents evidence associated with a PHS assessment question.
///
/// Evidence is intentionally kept independent of the scoring engine.
/// Sprint 9 progressively adds evidence validation, storage,
/// verification, and coverage calculations.
class Evidence {
  final String id;

  /// The PHS question this evidence supports.
  final String questionId;

  /// Optional specific evidence requirement this item supports.
  ///
  /// When supplied, this should use the requirement key generated from
  /// the owning question ID and requirement label.
  final String? requirementId;

  /// The type of evidence supplied.
  final EvidenceType type;

  /// User-facing name of the evidence item.
  final String name;

  /// Optional description supplied by the user.
  final String? description;

  /// Optional captured content associated with this evidence item.
  ///
  /// This remains optional so existing evidence entries that have not yet
  /// been captured continue to work without modification.
  final EvidenceContent? content;

  /// Current lifecycle state of the evidence.
  final EvidenceStatus status;

  /// Where the evidence came from.
  final EvidenceSource source;

  /// When the evidence was added to the assessment.
  final DateTime addedAt;

  const Evidence({
    required this.id,
    required this.questionId,
    this.requirementId,
    required this.type,
    required this.name,
    this.description,
    this.content,
    required this.status,
    required this.source,
    required this.addedAt,
  });

  /// Creates a copy of this evidence with selected fields changed.
  Evidence copyWith({
    String? id,
    String? questionId,
    String? requirementId,
    EvidenceType? type,
    String? name,
    String? description,
    EvidenceContent? content,
    EvidenceStatus? status,
    EvidenceSource? source,
    DateTime? addedAt,
  }) {
    return Evidence(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      requirementId: requirementId ?? this.requirementId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      status: status ?? this.status,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Creates the canonical identifier for a PHS evidence requirement.
  static String requirementKey({
    required String questionId,
    required String label,
  }) {
    return '$questionId::$label';
  }

  /// Returns the canonical identifier for the requirement referenced
  /// by this evidence item, when available.
  String? get canonicalRequirementId => requirementId;

  /// Whether the evidence has been verified.
  bool get isVerified => status == EvidenceStatus.verified;

  /// Whether the evidence still requires user or system review.
  bool get needsReview => status == EvidenceStatus.needsReview;

  /// Whether the evidence has been rejected.
  bool get isRejected => status == EvidenceStatus.rejected;
}

/// Types of evidence that HomeSure AI can associate with a PHS question.
///
/// This is intentionally broader than documents because later sprints
/// may support photographs, videos, manual confirmations, and other
/// evidence sources.
enum EvidenceType {
  document,
  photograph,
  video,
  manual,
}

/// Lifecycle state of evidence.
enum EvidenceStatus {
  notProvided,
  provided,
  verified,
  needsReview,
  rejected,
}

/// Origin of the evidence.
enum EvidenceSource {
  userUpload,
  userEntry,
  systemGenerated,
}