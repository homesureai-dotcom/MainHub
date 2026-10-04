import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_service.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('EvidenceService', () {
    late InMemoryEvidenceRepository repository;
    late EvidenceService service;

    Evidence createEvidence({
      required String id,
      required String questionId,
      EvidenceStatus status = EvidenceStatus.provided,
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
      service = EvidenceService(repository: repository);
    });

    test('adds evidence through the repository', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await service.addEvidence(evidence);

      expect(
        await service.getEvidenceById('e1'),
        evidence,
      );
    });

    test('gets evidence by ID', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await service.addEvidence(evidence);

      final result = await service.getEvidenceById('e1');

      expect(result, evidence);
    });

    test('returns null for unknown evidence ID', () async {
      expect(
        await service.getEvidenceById('unknown'),
        isNull,
      );
    });

    test('gets evidence for a question', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final second = createEvidence(
        id: 'e2',
        questionId: 'Q1',
      );

      final third = createEvidence(
        id: 'e3',
        questionId: 'Q2',
      );

      await service.addEvidence(first);
      await service.addEvidence(second);
      await service.addEvidence(third);

      final result =
          await service.getEvidenceForQuestion('Q1');

      expect(result, hasLength(2));
      expect(result, contains(first));
      expect(result, contains(second));
      expect(result, isNot(contains(third)));
    });

    test('gets all evidence', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final second = createEvidence(
        id: 'e2',
        questionId: 'Q2',
      );

      await service.addEvidence(first);
      await service.addEvidence(second);

      final result = await service.getAllEvidence();

      expect(result, hasLength(2));
      expect(result, contains(first));
      expect(result, contains(second));
    });

    test('updates existing evidence', () async {
      final original = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.provided,
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      await service.addEvidence(original);
      await service.updateEvidence(updated);

      final result = await service.getEvidenceById('e1');

      expect(result, updated);
      expect(
        result!.status,
        EvidenceStatus.verified,
      );
    });

    test('deletes evidence by ID', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await service.addEvidence(evidence);

      final deleted = await service.deleteEvidence('e1');

      expect(deleted, isTrue);
      expect(
        await service.getEvidenceById('e1'),
        isNull,
      );
    });

    test('returns false when deleting unknown evidence', () async {
      final deleted =
          await service.deleteEvidence('unknown');

      expect(deleted, isFalse);
    });

    test('deletes evidence for a question', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final second = createEvidence(
        id: 'e2',
        questionId: 'Q1',
      );

      final third = createEvidence(
        id: 'e3',
        questionId: 'Q2',
      );

      await service.addEvidence(first);
      await service.addEvidence(second);
      await service.addEvidence(third);

      final deletedCount =
          await service.deleteEvidenceForQuestion('Q1');

      expect(deletedCount, 2);

      expect(
        await service.getEvidenceById('e1'),
        isNull,
      );

      expect(
        await service.getEvidenceById('e2'),
        isNull,
      );

      expect(
        await service.getEvidenceById('e3'),
        third,
      );
    });

    test('clears all evidence', () async {
      await service.addEvidence(
        createEvidence(
          id: 'e1',
          questionId: 'Q1',
        ),
      );

      await service.addEvidence(
        createEvidence(
          id: 'e2',
          questionId: 'Q2',
        ),
      );

      await service.clearEvidence();

      expect(
        await service.getAllEvidence(),
        isEmpty,
      );
    });

    test('preserves repository errors', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await service.addEvidence(evidence);

      expect(
        () => service.addEvidence(evidence),
        throwsStateError,
      );
    });
  });
}