import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/evidence/image_picker_gateway.dart';
import 'package:homesure_ai/core/evidence/image_picker_selection.dart';
import 'package:homesure_ai/core/evidence/video_capture_service.dart';

class _FakeImagePickerGateway implements ImagePickerGateway {
  final ImagePickerSelection? result;

  const _FakeImagePickerGateway({
    required this.result,
  });

  @override
  Future<ImagePickerSelection?> pickPhotograph() async {
    return null;
  }

  @override
  Future<ImagePickerSelection?> captureVideo() async {
    return result;
  }
}

void main() {
  group('VideoCaptureService', () {
    test(
      'returns video evidence content when a video is captured',
      () async {
        const gateway = _FakeImagePickerGateway(
          result: ImagePickerSelection(
            path: '/videos/fire_system.mp4',
            name: 'fire_system.mp4',
          ),
        );

        const service = VideoCaptureService(
          imagePicker: gateway,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.video(),
        );

        expect(result, isNotNull);
        expect(result!.kind, EvidenceContentKind.video);
        expect(result.locator, '/videos/fire_system.mp4');
        expect(result.label, 'fire_system.mp4');
      },
    );

    test(
      'returns null when the user cancels video capture',
      () async {
        const gateway = _FakeImagePickerGateway(
          result: null,
        );

        const service = VideoCaptureService(
          imagePicker: gateway,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.video(),
        );

        expect(result, isNull);
      },
    );

    test(
      'rejects non-video capture requests',
      () async {
        const gateway = _FakeImagePickerGateway(
          result: ImagePickerSelection(
            path: '/videos/fire_system.mp4',
            name: 'fire_system.mp4',
          ),
        );

        const service = VideoCaptureService(
          imagePicker: gateway,
        );

        expect(
          () => service.capture(
            const EvidenceCaptureRequest.photograph(),
          ),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'rejects a captured video without a usable path',
      () async {
        const gateway = _FakeImagePickerGateway(
          result: ImagePickerSelection(
            path: null,
            name: 'fire_system.mp4',
          ),
        );

        const service = VideoCaptureService(
          imagePicker: gateway,
        );

        expect(
          () => service.capture(
            const EvidenceCaptureRequest.video(),
          ),
          throwsStateError,
        );
      },
    );

    test(
      'rejects a captured video with an empty path',
      () async {
        const gateway = _FakeImagePickerGateway(
          result: ImagePickerSelection(
            path: '   ',
            name: 'fire_system.mp4',
          ),
        );

        const service = VideoCaptureService(
          imagePicker: gateway,
        );

        expect(
          () => service.capture(
            const EvidenceCaptureRequest.video(),
          ),
          throwsStateError,
        );
      },
    );
  });
}