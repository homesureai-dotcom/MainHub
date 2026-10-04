import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_capture_coordinator.dart';
import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('EvidenceCaptureCoordinator', () {
    test('should capture and persist evidence content', () async {
      final repository = InMemoryEvidenceRepository();

      final captureService = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: 'file:///documents/occupancy-certificate.pdf',
          label: 'Occupancy Certificate PDF',
        ),
      );

      final coordinator = EvidenceCaptureCoordinator(
        captureService: captureService,
        repository: repository,
      );

      final evidence = await coordinator.captureEvidence(
        id: 'EVIDENCE_001',
        questionId: 'LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        request: const EvidenceCaptureRequest.document(),
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 20),
      );

      expect(evidence, isNotNull);
      expect(evidence!.id, 'EVIDENCE_001');
      expect(evidence.questionId, 'LEGAL_OC');
      expect(evidence.type, EvidenceType.document);
      expect(evidence.status, EvidenceStatus.provided);
      expect(evidence.content, isNotNull);
      expect(
        evidence.content!.kind,
        EvidenceContentKind.file,
      );

      final persisted =
          await repository.getById('EVIDENCE_001');

      expect(persisted, evidence);
    });

    test('should return null when capture is cancelled', () async {
      final repository = InMemoryEvidenceRepository();

      final captureService = _FakeEvidenceCaptureService(null);

      final coordinator = EvidenceCaptureCoordinator(
        captureService: captureService,
        repository: repository,
      );

      final evidence = await coordinator.captureEvidence(
        id: 'EVIDENCE_002',
        questionId: 'LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'Occupancy Certificate',
        request: const EvidenceCaptureRequest.document(),
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 20),
      );

      expect(evidence, isNull);
      expect(
        await repository.getById('EVIDENCE_002'),
        isNull,
      );
    });

    test('should support photograph capture', () async {
      final repository = InMemoryEvidenceRepository();

      final captureService = _FakeEvidenceCaptureService(
        EvidenceContent(
          kind: EvidenceContentKind.image,
          locator: 'file:///images/water-leakage.jpg',
        ),
      );

      final coordinator = EvidenceCaptureCoordinator(
        captureService: captureService,
        repository: repository,
      );

      final evidence = await coordinator.captureEvidence(
        id: 'EVIDENCE_003',
        questionId: 'CONSTRUCTION_LEAKAGE',
        type: EvidenceType.photograph,
        name: 'Water Leakage Photograph',
        request: const EvidenceCaptureRequest.photograph(),
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 20),
      );

      expect(evidence, isNotNull);
      expect(
        evidence!.content!.kind,
        EvidenceContentKind.image,
      );
      expect(evidence.status, EvidenceStatus.provided);
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