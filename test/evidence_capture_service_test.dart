import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';

void main() {
  group('EvidenceCaptureService', () {
    test('should capture document content', () async {
      final service = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: 'file:///documents/occupancy-certificate.pdf',
          label: 'Occupancy Certificate',
        ),
      );

      final result = await service.capture(
        EvidenceCaptureRequest.document(),
      );

      expect(result, isNotNull);
      expect(result!.kind, EvidenceContentKind.file);
      expect(
        result.locator,
        'file:///documents/occupancy-certificate.pdf',
      );
    });

    test('should capture photograph content', () async {
      final service = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.image,
          locator: 'file:///images/water-leakage.jpg',
        ),
      );

      final result = await service.capture(
        EvidenceCaptureRequest.photograph(),
      );

      expect(result, isNotNull);
      expect(result!.kind, EvidenceContentKind.image);
    });

    test('should capture video content', () async {
      final service = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.video,
          locator: 'file:///videos/stp-inspection.mp4',
        ),
      );

      final result = await service.capture(
        EvidenceCaptureRequest.video(),
      );

      expect(result, isNotNull);
      expect(result!.kind, EvidenceContentKind.video);
    });

    test('should capture manual evidence content', () async {
      final service = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.manual,
          locator: 'manual://evidence/001',
          label: 'Verified manually by owner',
        ),
      );

      final result = await service.capture(
        EvidenceCaptureRequest.manual(),
      );

      expect(result, isNotNull);
      expect(result!.kind, EvidenceContentKind.manual);
      expect(
        result.label,
        'Verified manually by owner',
      );
    });

    test('should allow capture cancellation', () async {
      final service = _FakeEvidenceCaptureService(null);

      final result = await service.capture(
        EvidenceCaptureRequest.document(),
      );

      expect(result, isNull);
    });
  });
}

class _FakeEvidenceCaptureService
    implements EvidenceCaptureService {
  final EvidenceContent? result;

  const _FakeEvidenceCaptureService(this.result);

  @override
  Future<EvidenceContent?> capture(
    EvidenceCaptureRequest request,
  ) async {
    return result;
  }
}