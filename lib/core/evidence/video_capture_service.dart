import 'evidence_capture_service.dart';
import 'evidence_content.dart';
import 'image_picker_gateway.dart';

/// Captures video evidence using the platform image picker.
///
/// This implementation handles video capture only.
/// Document, photograph, and manual capture remain the responsibility of
/// other [EvidenceCaptureService] implementations.
class VideoCaptureService implements EvidenceCaptureService {
  const VideoCaptureService({
    required this._imagePicker,
  });

  final ImagePickerGateway _imagePicker;

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) async {
    if (!request.isVideo) {
      throw UnsupportedError(
        'VideoCaptureService supports video capture only.',
      );
    }

    final video = await _imagePicker.captureVideo();

    if (video == null) {
      return null;
    }

    final locator = video.path;

    if (locator == null || locator.trim().isEmpty) {
      throw StateError(
        'The captured video does not expose a usable file path.',
      );
    }

    return EvidenceContent(
      kind: EvidenceContentKind.video,
      locator: locator,
      label: video.name,
    );
  }
}