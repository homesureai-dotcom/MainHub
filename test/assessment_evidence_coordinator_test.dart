import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_coordinator.dart';
import 'package:homesure_ai/core/evidence/assessment_evidence_summary_builder.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('AssessmentEvidenceCoordinator', () {
    late InMemoryEvidenceRepository repository;
    late AssessmentEvidenceCoordinator coordinator;

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

    const saleDeedRequirement = EvidenceRequirement(
      questionId: 'LEGAL_SD',
      label: 'Registered Sale Deed',
      type: EvidenceType.document,
    );

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String label,
      EvidenceStatus status = EvidenceStatus.verified,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        requirementId: Evidence.requirementKey(
          questionId: questionId,
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

      const builder = AssessmentEvidenceSummaryBuilder(
        validator: EvidenceValidator(),
      );

      coordinator = AssessmentEvidenceCoordinator(
        repository: repository,
        summaryBuilder: builder,
      );
    });

    test('loads evidence for multiple questions in question order',
        () async {
      final occupancy = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
      );

      final saleDeed = createEvidence(
        id: 'E2',
        questionId: 'LEGAL_SD',
        label: 'Registered Sale Deed',
      );

      await repository.add(occupancy);
      await repository.add(saleDeed);

      final result = await coordinator.loadEvidence([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, [occupancy, saleDeed]);
    });

    test('returns empty evidence when no question evidence exists',
        () async {
      final result = await coordinator.loadEvidence([
        'LEGAL_OC',
        'LEGAL_SD',
      ]);

      expect(result, isEmpty);
    });

    test('builds a complete summary from persisted evidence', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E3',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      );

      final summary = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
          saleDeedRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
          'LEGAL_SD',
        ],
      );

      expect(summary.totalRequirements, 3);
      expect(summary.satisfiedRequirements, 3);
      expect(summary.missingRequirements, 0);
      expect(summary.coveragePercentage, 100);
      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.hasEvidenceRisk, isFalse);
    });

    test('builds an incomplete summary when persisted evidence is missing',
        () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final summary = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
          'LEGAL_SD',
        ],
      );

      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.missingRequirements, 1);
      expect(summary.coveragePercentage, 50);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
      expect(summary.hasEvidenceRisk, isTrue);
    });

    test('includes category coverage in the generated summary', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
        ),
      );

      final summary = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
        ],
        categoryRequirements: {
          'LEGAL_OWNERSHIP': [
            occupancyRequirement,
            ocReferenceRequirement,
          ],
        },
      );

      expect(summary.categoryCoverage.length, 1);

      final coverage = summary.categoryCoverage.single;

      expect(coverage.categoryId, 'LEGAL_OWNERSHIP');
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 2);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
    });

    test('adds evidence through the coordinator', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
      );

      await coordinator.addEvidence(evidence);

      final stored = await repository.getById('E1');

      expect(stored, evidence);
    });

    test('updates evidence through the coordinator', () async {
      final original = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      await repository.add(original);

      final updated = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Updated Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      await coordinator.updateEvidence(updated);

      final stored = await repository.getById('E1');

      expect(stored, updated);
    });

    test('deletes evidence by ID through the coordinator', () async {
      final evidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
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

    test('deletes all evidence for a question', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
        ),
      );

      await repository.add(
        createEvidence(
          id: 'E3',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      );

      final deletedCount =
          await coordinator.deleteEvidenceForQuestion('LEGAL_OC');

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

    test('summary reflects repository changes after evidence is deleted',
        () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final beforeDeletion = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
        ],
      );

      expect(beforeDeletion.isComplete, isTrue);

      await coordinator.deleteEvidence('E1');

      final afterDeletion = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
        ],
      );

      expect(afterDeletion.isComplete, isFalse);
      expect(afterDeletion.missingRequirements, 1);
      expect(afterDeletion.coveragePercentage, 0);
    });

    test('summary reflects newly added evidence', () async {
      final beforeAddition = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
        ],
      );

      expect(beforeAddition.isComplete, isFalse);

      await coordinator.addEvidence(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final afterAddition = await coordinator.buildSummary(
        requirements: [
          occupancyRequirement,
        ],
        questionIds: [
          'LEGAL_OC',
        ],
      );

      expect(afterAddition.isComplete, isTrue);
      expect(afterAddition.satisfiedRequirements, 1);
      expect(afterAddition.coveragePercentage, 100);
    });

    test('returns immutable loaded evidence', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final result = await coordinator.loadEvidence([
        'LEGAL_OC',
      ]);

      expect(
        () => result.add(
          createEvidence(
            id: 'E2',
            questionId: 'LEGAL_OC',
            label: 'Second Document',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}