import 'evidence.dart';
import 'evidence_capture_service.dart';
import 'evidence_repository.dart';

/// Coordinates evidence capture and persistence.
///
/// This class sits between the assessment/application layer and the
/// platform-neutral [EvidenceCaptureService]. It is responsible for:
///
/// 1. Requesting captured content.
/// 2. Handling user cancellation.
/// 3. Creating the corresponding [Evidence] domain object.
/// 4. Persisting the evidence.
///
/// Platform-specific capture implementations remain outside this class.
class EvidenceCaptureCoordinator {
  final EvidenceCaptureService _captureService;
  final EvidenceRepository _repository;

  const EvidenceCaptureCoordinator({
    required this._captureService,
    required this._repository,
  });

  /// Captures content and persists it as an evidence item.
  ///
  /// Returns the created [Evidence] when capture succeeds.
  ///
  /// Returns `null` when the user cancels the capture operation.
  Future<Evidence?> captureEvidence({
    required String id,
    required String questionId,
    String? requirementId,
    required EvidenceType type,
    required String name,
    required EvidenceCaptureRequest request,
    required EvidenceSource source,
    required DateTime addedAt,
  }) async {
    final content = await _captureService.capture(request);

    if (content == null) {
      return null;
    }

    final evidence = Evidence(
      id: id,
      questionId: questionId,
      requirementId: requirementId,
      type: type,
      name: name,
      content: content,
      status: EvidenceStatus.provided,
      source: source,
      addedAt: addedAt,
    );

    await _repository.add(evidence);

    return evidence;
  }
}