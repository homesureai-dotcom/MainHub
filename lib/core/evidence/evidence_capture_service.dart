import 'evidence_content.dart';

/// Defines the application boundary for capturing evidence content.
///
/// Implementations are responsible for deciding how content is captured,
/// selected, or entered. The assessment and evidence domain layers should
/// depend only on this contract and must not depend on platform-specific
/// capture plugins.
abstract interface class EvidenceCaptureService {
  /// Captures or selects evidence content for the supplied request.
  ///
  /// Returns the captured content when successful.
  ///
  /// Returns `null` when the user cancels the capture operation.
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  );
}

/// Describes what kind of evidence content should be captured.
class EvidenceCaptureRequest {
  final EvidenceCaptureRequestType type;

  const EvidenceCaptureRequest({
    required this.type,
  });

  /// Creates a request for document/file evidence.
  const EvidenceCaptureRequest.document()
      : type = EvidenceCaptureRequestType.document;

  /// Creates a request for photograph evidence.
  const EvidenceCaptureRequest.photograph()
      : type = EvidenceCaptureRequestType.photograph;

  /// Creates a request for video evidence.
  const EvidenceCaptureRequest.video()
      : type = EvidenceCaptureRequestType.video;

  /// Creates a request for manually entered evidence.
  const EvidenceCaptureRequest.manual()
      : type = EvidenceCaptureRequestType.manual;

  /// Whether this request expects document content.
  bool get isDocument =>
      type == EvidenceCaptureRequestType.document;

  /// Whether this request expects photograph content.
  bool get isPhotograph =>
      type == EvidenceCaptureRequestType.photograph;

  /// Whether this request expects video content.
  bool get isVideo =>
      type == EvidenceCaptureRequestType.video;

  /// Whether this request expects manual evidence.
  bool get isManual =>
      type == EvidenceCaptureRequestType.manual;
}

/// Capture request types supported by HomeSure AI.
enum EvidenceCaptureRequestType {
  document,
  photograph,
  video,
  manual,
}