import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_status_transition_service.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('EvidenceStatusTransitionService', () {
    late InMemoryEvidenceRepository repository;
    late EvidenceStatusTransitionService service;

    Evidence createEvidence({
      required String id,
      required String questionId,
      required EvidenceStatus status,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        type: EvidenceType.document,
        name: '$id.pdf',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();

      service = EvidenceStatusTransitionService(
        repository: repository,
      );
    });

    test('allows provided to verified', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        await service.getEvidenceById('e1'),
        updated,
      );
    });

    test('allows provided to needsReview', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.needsReview,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.needsReview,
      );
    });

    test('allows provided to rejected', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.rejected,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.rejected,
      );
    });

    test('allows needsReview to verified', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.needsReview,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.verified,
      );
    });

    test('allows needsReview to rejected', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.needsReview,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.rejected,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.rejected,
      );
    });

    test('rejects verified to provided', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      await repository.add(existing);

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.verified,
      );
    });

    test('rejects verified to rejected', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.rejected,
      );

      await repository.add(existing);

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.verified,
      );
    });

    test('rejects rejected to verified', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.rejected,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      await repository.add(existing);

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );

      expect(
        (await service.getEvidenceById('e1'))!.status,
        EvidenceStatus.rejected,
      );
    });

    test('rejects rejected to provided', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.rejected,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      await repository.add(existing);

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );
    });

    test('rejects update when evidence does not exist', () async {
      final updated = createEvidence(
        id: 'missing',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );
    });

    test('rejects changing question ID during update', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q2',
        status: EvidenceStatus.verified,
      );

      await repository.add(existing);

      expect(
        () => service.updateEvidence(updated),
        throwsStateError,
      );

      final persisted = await service.getEvidenceById('e1');

      expect(persisted!.questionId, 'Q1');
      expect(persisted.status, EvidenceStatus.provided);
    });

    test('allows a no-op status update', () async {
      final existing = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      await repository.add(existing);

      await service.updateEvidence(updated);

      expect(
        await service.getEvidenceById('e1'),
        updated,
      );
    });
  });
}