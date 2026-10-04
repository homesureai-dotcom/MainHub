import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('InMemoryEvidenceRepository', () {
    late InMemoryEvidenceRepository repository;

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
    });

    test('starts empty', () async {
      expect(await repository.getAll(), isEmpty);
    });

    test('adds and retrieves evidence by ID', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      final result = await repository.getById('e1');

      expect(result, evidence);
    });

    test('returns null for unknown evidence ID', () async {
      expect(
        await repository.getById('unknown'),
        isNull,
      );
    });

    test('returns all stored evidence', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final second = createEvidence(
        id: 'e2',
        questionId: 'Q2',
      );

      await repository.add(first);
      await repository.add(second);

      final result = await repository.getAll();

      expect(result, hasLength(2));
      expect(result, contains(first));
      expect(result, contains(second));
    });

    test('returns evidence for a specific question', () async {
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

      await repository.add(first);
      await repository.add(second);
      await repository.add(third);

      final result = await repository.getByQuestionId('Q1');

      expect(result, hasLength(2));
      expect(result, contains(first));
      expect(result, contains(second));
      expect(result, isNot(contains(third)));
    });

    test('returns empty list for question with no evidence', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      expect(
        await repository.getByQuestionId('Q2'),
        isEmpty,
      );
    });

    test('rejects duplicate evidence IDs', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final duplicate = createEvidence(
        id: 'e1',
        questionId: 'Q2',
      );

      await repository.add(first);

      expect(
        () => repository.add(duplicate),
        throwsStateError,
      );
    });

    test('updates an existing evidence item', () async {
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

      await repository.add(original);
      await repository.update(updated);

      final result = await repository.getById('e1');

      expect(result, updated);
      expect(result!.status, EvidenceStatus.verified);
    });

    test('rejects update when evidence ID does not exist', () async {
      final evidence = createEvidence(
        id: 'missing',
        questionId: 'Q1',
      );

      expect(
        () => repository.update(evidence),
        throwsStateError,
      );
    });

    test('deletes evidence by ID', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      final deleted = await repository.delete('e1');

      expect(deleted, isTrue);
      expect(await repository.getById('e1'), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('delete returns false for unknown evidence ID', () async {
      expect(
        await repository.delete('unknown'),
        isFalse,
      );
    });

    test('deletes all evidence for a question', () async {
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

      await repository.add(first);
      await repository.add(second);
      await repository.add(third);

      final deletedCount =
          await repository.deleteByQuestionId('Q1');

      expect(deletedCount, 2);

      expect(await repository.getById('e1'), isNull);
      expect(await repository.getById('e2'), isNull);
      expect(await repository.getById('e3'), third);
    });

    test('deleteByQuestionId returns zero when nothing matches',
        () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      final deletedCount =
          await repository.deleteByQuestionId('Q2');

      expect(deletedCount, 0);
      expect(await repository.getAll(), hasLength(1));
    });

    test('clear removes all evidence', () async {
      await repository.add(
        createEvidence(
          id: 'e1',
          questionId: 'Q1',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'e2',
          questionId: 'Q2',
        ),
      );

      await repository.clear();

      expect(await repository.getAll(), isEmpty);
    });

    test('updated evidence remains associated with its question',
        () async {
      final original = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final updated = createEvidence(
        id: 'e1',
        questionId: 'Q1',
        status: EvidenceStatus.verified,
      );

      await repository.add(original);
      await repository.update(updated);

      final result = await repository.getByQuestionId('Q1');

      expect(result, hasLength(1));
      expect(result.single, updated);
    });
  });
}