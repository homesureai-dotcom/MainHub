import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/core/evidence/question_evidence_coordinator.dart';

void main() {
  group('QuestionEvidenceCoordinator', () {
    late InMemoryEvidenceRepository repository;
    late QuestionEvidenceCoordinator coordinator;

    const occupancyRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const ocReferenceRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String label,
      EvidenceStatus status = EvidenceStatus.verified,
    }) {
      return Evidence(
        id: id,
        questionId: 'LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: label,
        ),
        type: EvidenceType.document,
        name: label,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();

      coordinator = QuestionEvidenceCoordinator(
        repository: repository,
        validator: const EvidenceValidator(),
      );
    });

    test('loads evidence for a question', () async {
      final evidence = createEvidence(
        id: 'E1',
        label: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final result = await coordinator.loadEvidence('LEGAL_OC');

      expect(result, [evidence]);
    });

    test('returns empty evidence when the question has no evidence',
        () async {
      final result = await coordinator.loadEvidence('LEGAL_OC');

      expect(result, isEmpty);
    });

    test('builds a complete question evidence summary', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          label: 'OC approval/reference details',
        ),
      );

      final summary = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
      );

      expect(summary.questionId, 'LEGAL_OC');
      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 2);
      expect(summary.missingRequirements, 0);
      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.hasEvidenceRisk, isFalse);
    });

    test('builds an incomplete summary when evidence is missing',
        () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      final summary = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
      );

      expect(summary.questionId, 'LEGAL_OC');
      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.missingRequirements, 1);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
      expect(summary.hasEvidenceRisk, isTrue);
      expect(summary.activeRiskSignalCount, 1);
    });

    test('includes validation results in the summary', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      final summary = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
      );

      expect(summary.validationResults.length, 2);

      expect(
        summary.validationResults[0].requirement,
        occupancyRequirement,
      );

      expect(
        summary.validationResults[0].isSatisfied,
        isTrue,
      );

      expect(
        summary.validationResults[1].requirement,
        ocReferenceRequirement,
      );

      expect(
        summary.validationResults[1].isSatisfied,
        isFalse,
      );
    });

    test('includes risk signals in the summary', () async {
      final summary = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
      );

      expect(summary.riskSignals.length, 2);
      expect(summary.activeRiskSignalCount, 2);
      expect(summary.hasEvidenceRisk, isTrue);
    });

    test('adds evidence through the coordinator', () async {
      final evidence = createEvidence(
        id: 'E1',
        label: 'Occupancy Certificate',
      );

      await coordinator.addEvidence(evidence);

      final stored = await repository.getById('E1');

      expect(stored, evidence);
    });

    test('updates evidence through the coordinator', () async {
      final original = createEvidence(
        id: 'E1',
        label: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        label: 'Updated Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      await coordinator.updateEvidence(updated);

      final stored = await repository.getById('E1');

      expect(stored, updated);
    });

    test('deletes evidence by ID', () async {
      final evidence = createEvidence(
        id: 'E1',
        label: 'Occupancy Certificate',
      );

      await repository.add(evidence);

      final deleted = await coordinator.deleteEvidence('E1');

      expect(deleted, isTrue);
      expect(
        await repository.getById('E1'),
        isNull,
      );
    });

    test('returns false when deleting missing evidence', () async {
      final deleted = await coordinator.deleteEvidence('MISSING');

      expect(deleted, isFalse);
    });

    test('deletes all evidence for the question', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          label: 'OC approval/reference details',
        ),
      );

      final deletedCount =
          await coordinator.deleteAllEvidence('LEGAL_OC');

      expect(deletedCount, 2);

      expect(
        await repository.getById('E1'),
        isNull,
      );

      expect(
        await repository.getById('E2'),
        isNull,
      );
    });

    test('summary reflects evidence added after the initial summary',
        () async {
      final beforeAddition = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
      );

      expect(beforeAddition.isComplete, isFalse);
      expect(beforeAddition.missingRequirements, 1);

      await coordinator.addEvidence(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      final afterAddition = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
      );

      expect(afterAddition.isComplete, isTrue);
      expect(afterAddition.satisfiedRequirements, 1);
      expect(afterAddition.missingRequirements, 0);
    });

    test('summary reflects evidence deleted after the initial summary',
        () async {
      await coordinator.addEvidence(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      final beforeDeletion = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
      );

      expect(beforeDeletion.isComplete, isTrue);

      await coordinator.deleteEvidence('E1');

      final afterDeletion = await coordinator.buildSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
      );

      expect(afterDeletion.isComplete, isFalse);
      expect(afterDeletion.missingRequirements, 1);
    });

    test('rejects adding evidence with an empty question ID', () async {
      final evidence = Evidence(
        id: 'E1',
        questionId: '',
        type: EvidenceType.document,
        name: 'Invalid Evidence',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );

      expect(
        () => coordinator.addEvidence(evidence),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects updating evidence with an empty question ID', () async {
      final evidence = Evidence(
        id: 'E1',
        questionId: '',
        type: EvidenceType.document,
        name: 'Invalid Evidence',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );

      expect(
        () => coordinator.updateEvidence(evidence),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects deleting all evidence with an empty question ID',
        () async {
      expect(
        () => coordinator.deleteAllEvidence(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns immutable loaded evidence', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      );

      final result = await coordinator.loadEvidence('LEGAL_OC');

      expect(
        () => result.add(
          createEvidence(
            id: 'E2',
            label: 'OC approval/reference details',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}