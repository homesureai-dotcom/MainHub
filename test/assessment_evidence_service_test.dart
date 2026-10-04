import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_service.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('AssessmentEvidenceService', () {
    late InMemoryEvidenceRepository repository;
    late AssessmentEvidenceService service;

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String name,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        type: EvidenceType.document,
        name: name,
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();
      service = AssessmentEvidenceService(
        repository: repository,
      );
    });

    test('returns evidence for multiple questions in question order',
        () async {
      final first = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      final second = createEvidence(
        id: 'E2',
        questionId: 'LEGAL_SD',
        name: 'Registered Sale Deed',
      );

      await repository.add(first);
      await repository.add(second);

      final result = await service.getEvidenceForQuestions([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, [first, second]);
    });

    test('returns an empty list when no evidence exists', () async {
      final result = await service.getEvidenceForQuestions([
        'LEGAL_OC',
      ]);

      expect(result, isEmpty);
    });

    test('groups evidence by question ID', () async {
      final ocEvidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      final ocReference = createEvidence(
        id: 'E2',
        questionId: 'LEGAL_OC',
        name: 'OC approval/reference details',
      );

      final saleDeed = createEvidence(
        id: 'E3',
        questionId: 'LEGAL_SD',
        name: 'Registered Sale Deed',
      );

      await repository.add(ocEvidence);
      await repository.add(ocReference);
      await repository.add(saleDeed);

      final result =
          await service.getEvidenceGroupedByQuestion([
        'LEGAL_OC',
        'LEGAL_SD',
        'LEGAL_KHATA',
      ]);

      expect(
        result['LEGAL_OC'],
        [ocEvidence, ocReference],
      );

      expect(
        result['LEGAL_SD'],
        [saleDeed],
      );

      expect(
        result['LEGAL_KHATA'],
        isEmpty,
      );
    });

    test('includes requested questions with no evidence', () async {
      final result =
          await service.getEvidenceGroupedByQuestion([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result.keys, containsAll(['LEGAL_OC', 'LEGAL_SD']));
      expect(result['LEGAL_OC'], isEmpty);
      expect(result['LEGAL_SD'], isEmpty);
    });

    test('counts evidence across multiple questions', () async {
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

      final count = await service.countEvidenceForQuestions([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(count, 3);
    });

    test('returns zero when none of the questions have evidence', () async {
      final count = await service.countEvidenceForQuestions([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(count, 0);
    });

    test('returns true when every question has evidence', () async {
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
          questionId: 'LEGAL_SD',
          name: 'Registered Sale Deed',
        ),
      );

      final result =
          await service.hasEvidenceForEveryQuestion([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, isTrue);
    });

    test('returns false when at least one question has no evidence',
        () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          name: 'Occupancy Certificate',
        ),
      );

      final result =
          await service.hasEvidenceForEveryQuestion([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, isFalse);
    });

    test('returns false when none of the questions have evidence',
        () async {
      final result =
          await service.hasEvidenceForEveryQuestion([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, isFalse);
    });

    test('returns true for an empty question list', () async {
      final result =
          await service.hasEvidenceForEveryQuestion([]);

      expect(result, isTrue);
    });

    test('returns an immutable evidence list', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final result = await service.getEvidenceForQuestions([
        'LEGAL_OC',
      ]);

      expect(
        () => result.add(
          createEvidence(
            id: 'E2',
            questionId: 'LEGAL_OC',
            name: 'Second document',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns an immutable grouped evidence map', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        name: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final result =
          await service.getEvidenceGroupedByQuestion([
        'LEGAL_OC',
      ]);

      expect(
        () => result['LEGAL_SD'] = const [],
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}