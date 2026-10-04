import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_repository.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_catalog.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence_type_mapper.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context_builder.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context_service.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_resolver.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';

void main() {
  group('PHSQuestionEvidenceContextService', () {
    late EvidenceRepository repository;
    late EvidenceRequirementCatalog catalog;
    late PHSQuestionEvidenceContextBuilder builder;
    late PHSQuestionEvidenceContextService service;

    setUp(() {
      repository = InMemoryEvidenceRepository();

      catalog = const EvidenceRequirementCatalog(
        resolver: EvidenceRequirementResolver(
          typeMapper: EvidenceTypeMapper(),
        ),
      );

      builder = PHSQuestionEvidenceContextBuilder(
        validator: EvidenceValidator(
          matcher: EvidenceRequirementMatcher(),
        ),
      );

      service = PHSQuestionEvidenceContextService(
        repository: repository,
        catalog: catalog,
        builder: builder,
      );
    });

    PHSQuestion createQuestion({
      required String id,
      required String title,
      required List<String> requiredEvidence,
    }) {
      return PHSQuestion(
        id: id,
        category: PHSCategory.legalOwnership,
        title: title,
        helpText: 'Test help text.',
        whyItMatters: 'Test reason.',
        impact: 'Test impact.',
        priority: QuestionPriority.medium,
        potentialPHIGain: 10,
        weight: 10,
        requiredEvidence: requiredEvidence,
        applicableTo: const [
          PropertyType.apartment,
        ],
      );
    }

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
        name: '$label.pdf',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );
    }

    test('builds context for a question with no supplied evidence', () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

      final context = await service.buildForQuestion(question);

      expect(context, isA<PHSQuestionEvidenceContext>());
      expect(context.questionId, 'LEGAL_OC');
      expect(context.totalRequirements, 2);
      expect(context.evidence, isEmpty);
      expect(context.missingRequirements, 2);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('builds context using persisted evidence', () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final context = await service.buildForQuestion(question);

      expect(context.evidence, hasLength(1));
      expect(context.satisfiedRequirements, 1);
      expect(context.isComplete, isTrue);
      expect(context.hasEvidenceGaps, isFalse);
    });

    test('builds context with unresolved evidence status', () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          status: EvidenceStatus.needsReview,
        ),
      );

      final context = await service.buildForQuestion(question);

      expect(context.needsReviewRequirements, 1);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceRisk, isTrue);
    });

    test('only loads evidence belonging to the requested question', () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

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
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      );

      final context = await service.buildForQuestion(question);

      expect(context.evidence, hasLength(1));
      expect(context.evidence.first.id, 'E1');
    });

    test('returns evidence for a question ID', () async {
      await repository.add(
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      );

      final evidence =
          await service.getEvidenceForQuestion('LEGAL_OC');

      expect(evidence, hasLength(1));
      expect(evidence.first.id, 'E1');
    });

    test('returns an immutable evidence list', () async {
      final evidenceItem = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
      );

      await repository.add(evidenceItem);

      final evidence =
          await service.getEvidenceForQuestion('LEGAL_OC');

      expect(
        () => evidence.add(evidenceItem),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns requirements for a PHS question', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

      final requirements =
          service.getRequirementsForQuestion(question);

      expect(requirements, hasLength(2));
      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'LEGAL_OC',
        ),
        isTrue,
      );
    });

    test('returns requirements for a canonical question ID', () {
      final requirements =
          service.getRequirementsForQuestionId('LEGAL_OC');

      expect(requirements, isNotEmpty);
      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'LEGAL_OC',
        ),
        isTrue,
      );
    });

    test('returns empty requirements for an unknown question ID', () {
      final requirements =
          service.getRequirementsForQuestionId('UNKNOWN_QUESTION');

      expect(requirements, isEmpty);
    });

    test('preserves canonical requirement labels', () {
      final requirements =
          service.getRequirementsForQuestionId('LEGAL_OC');

      expect(
        requirements.map((requirement) => requirement.label).toList(),
        [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );
    });

    test('does not modify PHS scoring', () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      final context = await service.buildForQuestion(question);

      expect(context.questionId, 'LEGAL_OC');
      expect(context.isComplete, isFalse);

      expect(question.weight, 10);
      expect(question.potentialPHIGain, 10);
    });

    test('builds a complete context when every requirement is verified',
        () async {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

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

      final context = await service.buildForQuestion(question);

      expect(context.totalRequirements, 2);
      expect(context.satisfiedRequirements, 2);
      expect(context.missingRequirements, 0);
      expect(context.isComplete, isTrue);
      expect(context.hasEvidenceRisk, isFalse);
    });
  });
}