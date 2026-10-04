import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/evidence/file_picker_evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/file_picker_gateway.dart';
import 'package:homesure_ai/core/evidence/file_picker_selection.dart';

class _FakeFilePickerGateway implements FilePickerGateway {
  final FilePickerSelection? result;

  const _FakeFilePickerGateway({
    required this.result,
  });

  @override
  Future<FilePickerSelection?> pickDocument() async {
    return result;
  }
}

void main() {
  group('FilePickerEvidenceCaptureService', () {
    test('returns file evidence content when a document is selected', () async {
      const gateway = _FakeFilePickerGateway(
        result: FilePickerSelection(
          name: 'fire_noc.pdf',
          path: '/documents/fire_noc.pdf',
        ),
      );

      const service = FilePickerEvidenceCaptureService(
        filePicker: gateway,
      );

      final result = await service.capture(
        const EvidenceCaptureRequest.document(),
      );

      expect(result, isNotNull);
      expect(result!.kind, EvidenceContentKind.file);
      expect(result.locator, '/documents/fire_noc.pdf');
      expect(result.label, 'fire_noc.pdf');
    });

    test('returns null when the user cancels document selection', () async {
      const gateway = _FakeFilePickerGateway(
        result: null,
      );

      const service = FilePickerEvidenceCaptureService(
        filePicker: gateway,
      );

      final result = await service.capture(
        const EvidenceCaptureRequest.document(),
      );

      expect(result, isNull);
    });

    test('rejects non-document capture requests', () async {
      const gateway = _FakeFilePickerGateway(
        result: FilePickerSelection(
          name: 'photo.jpg',
          path: '/documents/photo.jpg',
        ),
      );

      const service = FilePickerEvidenceCaptureService(
        filePicker: gateway,
      );

      expect(
        () => service.capture(
          const EvidenceCaptureRequest.photograph(),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects a selected file without a usable path', () async {
      const gateway = _FakeFilePickerGateway(
        result: FilePickerSelection(
          name: 'fire_noc.pdf',
          path: null,
        ),
      );

      const service = FilePickerEvidenceCaptureService(
        filePicker: gateway,
      );

      expect(
        () => service.capture(
          const EvidenceCaptureRequest.document(),
        ),
        throwsStateError,
      );
    });
  });
}