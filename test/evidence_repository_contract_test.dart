import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_repository.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('EvidenceRepository contract', () {
    late EvidenceRepository repository;

    Evidence createEvidence({
      required String id,
      required String questionId,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        type: EvidenceType.document,
        name: '$id.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();
    });

    test('supports adding and retrieving evidence', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      expect(
        await repository.getById('e1'),
        evidence,
      );
    });

    test('supports retrieving evidence by question', () async {
      final first = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final second = createEvidence(
        id: 'e2',
        questionId: 'Q1',
      );

      await repository.add(first);
      await repository.add(second);

      final result = await repository.getByQuestionId('Q1');

      expect(result, hasLength(2));
      expect(result, contains(first));
      expect(result, contains(second));
    });

    test('supports retrieving all evidence', () async {
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

      expect(
        await repository.getAll(),
        hasLength(2),
      );
    });

    test('supports updating evidence', () async {
      final original = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      final updated = original.copyWith(
        status: EvidenceStatus.verified,
      );

      await repository.add(original);
      await repository.update(updated);

      expect(
        (await repository.getById('e1'))!.status,
        EvidenceStatus.verified,
      );
    });

    test('supports deleting evidence', () async {
      final evidence = createEvidence(
        id: 'e1',
        questionId: 'Q1',
      );

      await repository.add(evidence);

      expect(
        await repository.delete('e1'),
        isTrue,
      );

      expect(
        await repository.getById('e1'),
        isNull,
      );
    });

    test('supports deleting evidence by question', () async {
      await repository.add(
        createEvidence(
          id: 'e1',
          questionId: 'Q1',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'e2',
          questionId: 'Q1',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'e3',
          questionId: 'Q2',
        ),
      );

      expect(
        await repository.deleteByQuestionId('Q1'),
        2,
      );

      expect(
        await repository.getAll(),
        hasLength(1),
      );

      expect(
        (await repository.getAll()).single.id,
        'e3',
      );
    });

    test('supports clearing the repository', () async {
      await repository.add(
        createEvidence(
          id: 'e1',
          questionId: 'Q1',
        ),
      );

      await repository.clear();

      expect(
        await repository.getAll(),
        isEmpty,
      );
    });
  });
}