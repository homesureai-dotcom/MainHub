import 'evidence_capture_service.dart';
import 'evidence_content.dart';

/// Routes evidence capture requests to the appropriate capture service.
///
/// This keeps the application/UI layer dependent on a single
/// [EvidenceCaptureService] while allowing each capture type to have its
/// own platform-specific implementation.
class CompositeEvidenceCaptureService
    implements EvidenceCaptureService {
  const CompositeEvidenceCaptureService({
    required this._documentCaptureService,
    required this._photographCaptureService,
    required this._videoCaptureService,
  });

  final EvidenceCaptureService _documentCaptureService;
  final EvidenceCaptureService _photographCaptureService;
  final EvidenceCaptureService _videoCaptureService;

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) {
    if (request.isDocument) {
      return _documentCaptureService.capture(request);
    }

    if (request.isPhotograph) {
      return _photographCaptureService.capture(request);
    }

    if (request.isVideo) {
      return _videoCaptureService.capture(request);
    }

    throw UnsupportedError(
      'CompositeEvidenceCaptureService does not support '
      '${request.type.name} capture.',
    );
  }
}