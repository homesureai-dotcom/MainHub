import 'evidence_capture_service.dart';
import 'evidence_content.dart';
import 'file_picker_gateway.dart';

/// Captures evidence content using the platform file picker.
///
/// This implementation currently handles document capture only.
/// Photograph, video, and manual capture remain the responsibility of
/// other [EvidenceCaptureService] implementations.
class FilePickerEvidenceCaptureService implements EvidenceCaptureService {
  final FilePickerGateway _filePicker;

  const FilePickerEvidenceCaptureService({
    required this._filePicker,
  });

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) async {
    if (!request.isDocument) {
      throw UnsupportedError(
        'FilePickerEvidenceCaptureService supports document capture only.',
      );
    }

    final file = await _filePicker.pickDocument();

    if (file == null) {
      return null;
    }

    final locator = file.path;

    if (locator == null || locator.trim().isEmpty) {
      throw StateError(
        'The selected document does not expose a usable file path.',
      );
    }

    return EvidenceContent(
      kind: EvidenceContentKind.file,
      locator: locator,
      label: file.name,
    );
  }
}