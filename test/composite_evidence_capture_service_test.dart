import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/composite_evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';

class _FakeCaptureService implements EvidenceCaptureService {
  final EvidenceContent? result;
  int captureCount = 0;
  EvidenceCaptureRequest? lastRequest;

  _FakeCaptureService({
    required this.result,
  });

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) async {
    captureCount++;
    lastRequest = request;
    return result;
  }
}

void main() {
  group('CompositeEvidenceCaptureService', () {
    test(
      'routes document requests to the document capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/fire_noc.pdf',
            label: 'fire_noc.pdf',
          ),
        );

        final photographService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.image,
            locator: '/photos/fire_system.jpg',
            label: 'fire_system.jpg',
          ),
        );

        final videoService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.video,
            locator: '/videos/fire_system.mp4',
            label: 'fire_system.mp4',
          ),
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.document(),
        );

        expect(result, isNotNull);
        expect(result!.kind, EvidenceContentKind.file);
        expect(result.locator, '/documents/fire_noc.pdf');

        expect(documentService.captureCount, 1);
        expect(
          documentService.lastRequest?.isDocument,
          isTrue,
        );

        expect(photographService.captureCount, 0);
        expect(videoService.captureCount, 0);
      },
    );

    test(
      'routes photograph requests to the photograph capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/fire_noc.pdf',
            label: 'fire_noc.pdf',
          ),
        );

        final photographService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.image,
            locator: '/photos/fire_system.jpg',
            label: 'fire_system.jpg',
          ),
        );

        final videoService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.video,
            locator: '/videos/fire_system.mp4',
            label: 'fire_system.mp4',
          ),
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.photograph(),
        );

        expect(result, isNotNull);
        expect(result!.kind, EvidenceContentKind.image);
        expect(result.locator, '/photos/fire_system.jpg');

        expect(photographService.captureCount, 1);
        expect(
          photographService.lastRequest?.isPhotograph,
          isTrue,
        );

        expect(documentService.captureCount, 0);
        expect(videoService.captureCount, 0);
      },
    );

    test(
      'routes video requests to the video capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/fire_noc.pdf',
            label: 'fire_noc.pdf',
          ),
        );

        final photographService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.image,
            locator: '/photos/fire_system.jpg',
            label: 'fire_system.jpg',
          ),
        );

        final videoService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.video,
            locator: '/videos/fire_system.mp4',
            label: 'fire_system.mp4',
          ),
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.video(),
        );

        expect(result, isNotNull);
        expect(result!.kind, EvidenceContentKind.video);
        expect(result.locator, '/videos/fire_system.mp4');

        expect(videoService.captureCount, 1);
        expect(
          videoService.lastRequest?.isVideo,
          isTrue,
        );

        expect(documentService.captureCount, 0);
        expect(photographService.captureCount, 0);
      },
    );

    test(
      'preserves a null result from the document capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: null,
        );

        final photographService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.image,
            locator: '/photos/fire_system.jpg',
            label: 'fire_system.jpg',
          ),
        );

        final videoService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.video,
            locator: '/videos/fire_system.mp4',
            label: 'fire_system.mp4',
          ),
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.document(),
        );

        expect(result, isNull);
        expect(documentService.captureCount, 1);
        expect(photographService.captureCount, 0);
        expect(videoService.captureCount, 0);
      },
    );

    test(
      'preserves a null result from the photograph capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/fire_noc.pdf',
            label: 'fire_noc.pdf',
          ),
        );

        final photographService = _FakeCaptureService(
          result: null,
        );

        final videoService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.video,
            locator: '/videos/fire_system.mp4',
            label: 'fire_system.mp4',
          ),
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.photograph(),
        );

        expect(result, isNull);
        expect(photographService.captureCount, 1);
        expect(documentService.captureCount, 0);
        expect(videoService.captureCount, 0);
      },
    );

    test(
      'preserves a null result from the video capture service',
      () async {
        final documentService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/fire_noc.pdf',
            label: 'fire_noc.pdf',
          ),
        );

        final photographService = _FakeCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.image,
            locator: '/photos/fire_system.jpg',
            label: 'fire_system.jpg',
          ),
        );

        final videoService = _FakeCaptureService(
          result: null,
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        final result = await service.capture(
          const EvidenceCaptureRequest.video(),
        );

        expect(result, isNull);
        expect(videoService.captureCount, 1);
        expect(documentService.captureCount, 0);
        expect(photographService.captureCount, 0);
      },
    );

    test(
      'rejects manual capture until manual capture is implemented',
      () async {
        final documentService = _FakeCaptureService(
          result: null,
        );

        final photographService = _FakeCaptureService(
          result: null,
        );

        final videoService = _FakeCaptureService(
          result: null,
        );

        final service = CompositeEvidenceCaptureService(
          documentCaptureService: documentService,
          photographCaptureService: photographService,
          videoCaptureService: videoService,
        );

        expect(
          () => service.capture(
            const EvidenceCaptureRequest.manual(),
          ),
          throwsUnsupportedError,
        );

        expect(documentService.captureCount, 0);
        expect(photographService.captureCount, 0);
        expect(videoService.captureCount, 0);
      },
    );
  });
}