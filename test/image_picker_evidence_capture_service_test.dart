import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/evidence/image_picker_evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/image_picker_gateway.dart';
import 'package:homesure_ai/core/evidence/image_picker_selection.dart';

class _FakeImagePickerGateway implements ImagePickerGateway {
  ImagePickerSelection? photographResult;
  bool photographCalled = false;

  @override
  Future<ImagePickerSelection?> pickPhotograph() async {
    photographCalled = true;
    return photographResult;
  }

  @override
  Future<ImagePickerSelection?> captureVideo() async {
    throw UnimplementedError();
  }
}

void main() {
  group(
    'ImagePickerEvidenceCaptureService',
    () {
      test(
        'captures photograph evidence successfully',
        () async {
          final gateway = _FakeImagePickerGateway()
            ..photographResult = const ImagePickerSelection(
              path: '/tmp/property-photo.jpg',
              name: 'property-photo.jpg',
            );

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          final result = await service.capture(
            const EvidenceCaptureRequest.photograph(),
          );

          expect(gateway.photographCalled, isTrue);
          expect(result, isNotNull);
          expect(
            result!.kind,
            EvidenceContentKind.image,
          );
          expect(
            result.locator,
            '/tmp/property-photo.jpg',
          );
          expect(
            result.label,
            'property-photo.jpg',
          );
        },
      );

      test(
        'returns null when photograph capture is cancelled',
        () async {
          final gateway =
              _FakeImagePickerGateway();

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          final result = await service.capture(
            const EvidenceCaptureRequest.photograph(),
          );

          expect(gateway.photographCalled, isTrue);
          expect(result, isNull);
        },
      );

      test(
        'rejects document capture requests',
        () async {
          final gateway =
              _FakeImagePickerGateway();

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          expect(
            () => service.capture(
              const EvidenceCaptureRequest.document(),
            ),
            throwsUnsupportedError,
          );
        },
      );

      test(
        'rejects video capture requests',
        () async {
          final gateway =
              _FakeImagePickerGateway();

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          expect(
            () => service.capture(
              const EvidenceCaptureRequest.video(),
            ),
            throwsUnsupportedError,
          );
        },
      );

      test(
        'throws when captured photograph has no usable path',
        () async {
          final gateway = _FakeImagePickerGateway()
            ..photographResult = const ImagePickerSelection(
              path: null,
              name: 'property-photo.jpg',
            );

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          expect(
            () => service.capture(
              const EvidenceCaptureRequest.photograph(),
            ),
            throwsStateError,
          );
        },
      );

      test(
        'throws when captured photograph path is blank',
        () async {
          final gateway = _FakeImagePickerGateway()
            ..photographResult = const ImagePickerSelection(
              path: '   ',
              name: 'property-photo.jpg',
            );

          final service =
              ImagePickerEvidenceCaptureService(
            imagePicker: gateway,
          );

          expect(
            () => service.capture(
              const EvidenceCaptureRequest.photograph(),
            ),
            throwsStateError,
          );
        },
      );
    },
  );
}