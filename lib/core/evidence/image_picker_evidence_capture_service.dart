import 'evidence_capture_service.dart';
import 'evidence_content.dart';
import 'image_picker_gateway.dart';

/// Captures photograph evidence using the platform image picker.
///
/// This implementation handles photograph capture only.
/// Document, video, and manual capture remain the responsibility of
/// other [EvidenceCaptureService] implementations.
class ImagePickerEvidenceCaptureService
    implements EvidenceCaptureService {
  const ImagePickerEvidenceCaptureService({
    required this._imagePicker,
  });

  final ImagePickerGateway _imagePicker;

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) async {
    if (!request.isPhotograph) {
      throw UnsupportedError(
        'ImagePickerEvidenceCaptureService supports photograph capture only.',
      );
    }

    final image = await _imagePicker.pickPhotograph();

    if (image == null) {
      return null;
    }

    final locator = image.path;

    if (locator == null || locator.trim().isEmpty) {
      throw StateError(
        'The captured photograph does not expose a usable file path.',
      );
    }

    return EvidenceContent(
      kind: EvidenceContentKind.image,
      locator: locator,
      label: image.name,
    );
  }
}