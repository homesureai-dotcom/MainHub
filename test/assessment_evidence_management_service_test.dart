import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_management_service.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('AssessmentEvidenceManagementService', () {
    late InMemoryEvidenceRepository repository;
    late AssessmentEvidenceManagementService service;

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String name,
      EvidenceStatus status = EvidenceStatus.provided,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        type: EvidenceType.document,
        name: name,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();

      service = AssessmentEvidenceManagementService(
        repository: repository,
      );
    });

    test('updates an existing evidence item', () async {
      final original = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Updated Occupancy Certificate',
      );

      await service.updateEvidence(updated);

      final stored = await repository.getById('E1');

      expect(stored, updated);
    });

    test('allows a valid status transition during update', () async {
      final original = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
        status: EvidenceStatus.verified,
      );

      await service.updateEvidence(updated);

      final stored = await repository.getById('E1');

      expect(
        stored?.status,
        EvidenceStatus.verified,
      );
    });

    test('rejects update when evidence does not exist', () async {
      final evidence = createEvidence(
        id: 'MISSING',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      expect(
        () => service.updateEvidence(evidence),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });

    test('rejects changing the question association', () async {
      final original = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_SD',
        name: 'Occupancy Certificate',
      );

      expect(
        () => service.updateEvidence(updated),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('question ID cannot be changed'),
          ),
        ),
      );

      final stored = await repository.getById('E1');

      expect(
        stored?.questionId,
        'LEGAL_OC',
      );
    });

    test('rejects an invalid status transition', () async {
      final original = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
        status: EvidenceStatus.verified,
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Updated Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      expect(
        () => service.updateEvidence(updated),
        throwsA(isA<StateError>()),
      );

      final stored = await repository.getById('E1');

      expect(
        stored?.status,
        EvidenceStatus.verified,
      );
    });

    test('deletes an existing evidence item', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final deleted = await service.deleteEvidence('E1');

      expect(deleted, isTrue);
      expect(
        await repository.getById('E1'),
        isNull,
      );
    });

    test(
      'completes evidence create, status update, and delete lifecycle',
      () async {
        final created = createEvidence(
          id: 'LIFECYCLE_E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
          status: EvidenceStatus.notProvided,
        );

        await repository.add(created);

        final storedAfterCreate =
            await service.getEvidenceById('LIFECYCLE_E1');

        expect(
          storedAfterCreate,
          created,
        );

        expect(
          storedAfterCreate?.status,
          EvidenceStatus.notProvided,
        );

        final provided = created.copyWith(
          status: EvidenceStatus.provided,
        );

        await service.updateEvidence(provided);

        final storedAfterProvided =
            await service.getEvidenceById('LIFECYCLE_E1');

        expect(
          storedAfterProvided?.status,
          EvidenceStatus.provided,
        );

        final needsReview = provided.copyWith(
          status: EvidenceStatus.needsReview,
        );

        await service.updateEvidence(needsReview);

        final storedAfterReview =
            await service.getEvidenceById('LIFECYCLE_E1');

        expect(
          storedAfterReview?.status,
          EvidenceStatus.needsReview,
        );

        final deleted =
            await service.deleteEvidence('LIFECYCLE_E1');

        expect(
          deleted,
          isTrue,
        );

        final storedAfterDelete =
            await service.getEvidenceById('LIFECYCLE_E1');

        expect(
          storedAfterDelete,
          isNull,
        );
      },
    );

    test('returns false when deleting missing evidence', () async {
      final deleted = await service.deleteEvidence('MISSING');

      expect(deleted, isFalse);
    });

    test('deletes all evidence for a question', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          name: 'OC approval/reference details',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E3',
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
        ),
      );

      final deletedCount =
          await service.deleteEvidenceForQuestion('LEGAL_OC');

      expect(deletedCount, 2);

      expect(
        await repository.getById('E1'),
        isNull,
      );

      expect(
        await repository.getById('E2'),
        isNull,
      );

      expect(
        await repository.getById('E3'),
        isNotNull,
      );
    });

    test(
      'returns zero when deleting evidence for an empty question',
      () async {
        final deletedCount =
            await service.deleteEvidenceForQuestion('LEGAL_OC');

        expect(deletedCount, 0);
      },
    );

    test('retrieves evidence by ID', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final result = await service.getEvidenceById('E1');

      expect(result, evidence);
    });

    test('returns null when evidence ID does not exist', () async {
      final result = await service.getEvidenceById('MISSING');

      expect(result, isNull);
    });
  });
}