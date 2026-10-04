import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/image_picker_gateway.dart';
import 'package:homesure_ai/core/evidence/image_picker_selection.dart';

class _FakeImagePickerGateway implements ImagePickerGateway {
  final ImagePickerSelection? photographResult;
  final ImagePickerSelection? videoResult;

  int photographCallCount = 0;
  int videoCallCount = 0;

  _FakeImagePickerGateway({
    this.photographResult,
    this.videoResult,
  });

  @override
  Future<ImagePickerSelection?> pickPhotograph() async {
    photographCallCount++;
    return photographResult;
  }

  @override
  Future<ImagePickerSelection?> captureVideo() async {
    videoCallCount++;
    return videoResult;
  }
}

void main() {
  group('ImagePickerGateway', () {
    test(
      'photograph gateway contract returns selected photograph',
      () async {
        final gateway = _FakeImagePickerGateway(
          photographResult: const ImagePickerSelection(
            path: '/photos/fire_system.jpg',
            name: 'fire_system.jpg',
          ),
        );

        final result = await gateway.pickPhotograph();

        expect(result, isNotNull);
        expect(result!.path, '/photos/fire_system.jpg');
        expect(result.name, 'fire_system.jpg');
        expect(gateway.photographCallCount, 1);
        expect(gateway.videoCallCount, 0);
      },
    );

    test(
      'photograph gateway contract supports cancellation',
      () async {
        final gateway = _FakeImagePickerGateway();

        final result = await gateway.pickPhotograph();

        expect(result, isNull);
        expect(gateway.photographCallCount, 1);
        expect(gateway.videoCallCount, 0);
      },
    );

    test(
      'video gateway contract returns captured video',
      () async {
        final gateway = _FakeImagePickerGateway(
          videoResult: const ImagePickerSelection(
            path: '/videos/fire_system.mp4',
            name: 'fire_system.mp4',
          ),
        );

        final result = await gateway.captureVideo();

        expect(result, isNotNull);
        expect(result!.path, '/videos/fire_system.mp4');
        expect(result.name, 'fire_system.mp4');
        expect(gateway.videoCallCount, 1);
        expect(gateway.photographCallCount, 0);
      },
    );

    test(
      'video gateway contract supports cancellation',
      () async {
        final gateway = _FakeImagePickerGateway();

        final result = await gateway.captureVideo();

        expect(result, isNull);
        expect(gateway.videoCallCount, 1);
        expect(gateway.photographCallCount, 0);
      },
    );

    test(
      'photograph and video operations remain independent',
      () async {
        final gateway = _FakeImagePickerGateway(
          photographResult: const ImagePickerSelection(
            path: '/photos/property.jpg',
            name: 'property.jpg',
          ),
          videoResult: const ImagePickerSelection(
            path: '/videos/property.mp4',
            name: 'property.mp4',
          ),
        );

        final photograph = await gateway.pickPhotograph();
        final video = await gateway.captureVideo();

        expect(photograph!.path, '/photos/property.jpg');
        expect(video!.path, '/videos/property.mp4');

        expect(gateway.photographCallCount, 1);
        expect(gateway.videoCallCount, 1);
      },
    );
  });
}