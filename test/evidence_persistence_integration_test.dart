import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_service.dart';
import 'package:homesure_ai/core/evidence/evidence_status_transition_service.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/in_memory_evidence_repository.dart';
import 'package:homesure_ai/core/evidence/phs_evidence_mapper.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  group('Evidence persistence integration', () {
    late InMemoryEvidenceRepository repository;
    late EvidenceService evidenceService;
    late EvidenceStatusTransitionService transitionService;

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String requirementLabel,
      EvidenceStatus status = EvidenceStatus.provided,
      EvidenceType type = EvidenceType.document,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        requirementId: Evidence.requirementKey(
          questionId: questionId,
          label: requirementLabel,
        ),
        type: type,
        name: '$id.pdf',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );
    }

    setUp(() {
      repository = InMemoryEvidenceRepository();

      evidenceService = EvidenceService(
        repository: repository,
      );

      transitionService = EvidenceStatusTransitionService(
        repository: repository,
      );
    });

    test(
      'evidence survives the complete add and retrieve flow',
      () async {
        final evidence = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
        );

        await evidenceService.addEvidence(evidence);

        final persisted =
            await evidenceService.getEvidenceById('e1');

        expect(persisted, evidence);
        expect(persisted!.questionId, 'LEGAL_OC');
        expect(
          persisted.requirementId,
          Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
        );
      },
    );

    test(
      'captured evidence content survives the complete add and retrieve flow',
      () async {
        final evidence = Evidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          type: EvidenceType.document,
          name: 'Occupancy Certificate',
          content: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: 'file:///documents/occupancy-certificate.pdf',
            label: 'Occupancy Certificate PDF',
          ),
          status: EvidenceStatus.provided,
          source: EvidenceSource.userUpload,
          addedAt: DateTime(2026, 9, 19),
        );

        await evidenceService.addEvidence(evidence);

        final persisted =
            await evidenceService.getEvidenceById('e1');

        expect(persisted, isNotNull);
        expect(persisted!.content, isNotNull);
        expect(
          persisted.content!.kind,
          EvidenceContentKind.file,
        );
        expect(
          persisted.content!.locator,
          'file:///documents/occupancy-certificate.pdf',
        );
        expect(
          persisted.content!.label,
          'Occupancy Certificate PDF',
        );
      },
    );

    test(
      'evidence can be retrieved by PHS question',
      () async {
        final first = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
        );

        final second = createEvidence(
          id: 'e2',
          questionId: 'LEGAL_OC',
          requirementLabel: 'OC approval/reference details',
        );

        await evidenceService.addEvidence(first);
        await evidenceService.addEvidence(second);

        final result =
            await evidenceService.getEvidenceForQuestion('LEGAL_OC');

        expect(result, hasLength(2));
        expect(result, contains(first));
        expect(result, contains(second));
      },
    );

    test(
      'status transition persists through the repository',
      () async {
        final provided = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          status: EvidenceStatus.provided,
        );

        final verified = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          status: EvidenceStatus.verified,
        );

        await evidenceService.addEvidence(provided);

        await transitionService.updateEvidence(verified);

        final persisted =
            await evidenceService.getEvidenceById('e1');

        expect(
          persisted!.status,
          EvidenceStatus.verified,
        );
      },
    );

    test(
      'invalid status transition does not modify persisted evidence',
      () async {
        final verified = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          status: EvidenceStatus.verified,
        );

        final rejected = createEvidence(
          id: 'e1',
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          status: EvidenceStatus.rejected,
        );

        await evidenceService.addEvidence(verified);

        expect(
          () => transitionService.updateEvidence(rejected),
          throwsStateError,
        );

        final persisted =
            await evidenceService.getEvidenceById('e1');

        expect(
          persisted!.status,
          EvidenceStatus.verified,
        );
      },
    );

    test(
      'persisted verified evidence satisfies validation',
      () async {
        const mapper = PHSEvidenceMapper();
        const validator = EvidenceValidator();

        final question = phsQuestions.firstWhere(
          (item) => item.id == 'LEGAL_OC',
        );

        final requirements = mapper.mapQuestion(question);

        final requirement = requirements.firstWhere(
          (item) => item.label == 'Occupancy Certificate',
        );

        final evidence = createEvidence(
          id: 'e1',
          questionId: requirement.questionId,
          requirementLabel: requirement.label,
          status: EvidenceStatus.verified,
          type: requirement.type,
        );

        await evidenceService.addEvidence(evidence);

        final persisted =
            await evidenceService.getEvidenceForQuestion(
          requirement.questionId,
        );

        final validation = validator.validate(
          requirement,
          persisted,
        );

        expect(
          validation.status,
          EvidenceValidationStatus.satisfied,
        );

        expect(
          validation.isSatisfied,
          isTrue,
        );
      },
    );

    test(
      'persisted unverified evidence produces a risk signal',
      () async {
        const mapper = PHSEvidenceMapper();
        const validator = EvidenceValidator();

        final question = phsQuestions.firstWhere(
          (item) => item.id == 'LEGAL_OC',
        );

        final requirements = mapper.mapQuestion(question);

        final requirement = requirements.firstWhere(
          (item) => item.label == 'Occupancy Certificate',
        );

        final evidence = createEvidence(
          id: 'e1',
          questionId: requirement.questionId,
          requirementLabel: requirement.label,
          status: EvidenceStatus.provided,
          type: requirement.type,
        );

        await evidenceService.addEvidence(evidence);

        final persisted =
            await evidenceService.getEvidenceForQuestion(
          requirement.questionId,
        );

        final validation = validator.validate(
          requirement,
          persisted,
        );

        final signal =
            EvidenceRiskSignal.fromValidationResult(
          validation,
        );

        expect(
          signal.level,
          EvidenceRiskLevel.low,
        );

        expect(signal.hasRisk, isTrue);
      },
    );

    test(
      'deleting evidence removes it from validation flow',
      () async {
        const mapper = PHSEvidenceMapper();
        const validator = EvidenceValidator();

        final question = phsQuestions.firstWhere(
          (item) => item.id == 'LEGAL_OC',
        );

        final requirement = mapper
            .mapQuestion(question)
            .firstWhere(
              (item) => item.label == 'Occupancy Certificate',
            );

        final evidence = createEvidence(
          id: 'e1',
          questionId: requirement.questionId,
          requirementLabel: requirement.label,
          status: EvidenceStatus.verified,
          type: requirement.type,
        );

        await evidenceService.addEvidence(evidence);

        expect(
          await evidenceService.deleteEvidence('e1'),
          isTrue,
        );

        final persisted =
            await evidenceService.getEvidenceForQuestion(
          requirement.questionId,
        );

        final validation = validator.validate(
          requirement,
          persisted,
        );

        expect(
          validation.status,
          EvidenceValidationStatus.missing,
        );

        expect(
          validation.isSatisfied,
          isFalse,
        );
      },
    );

    test(
      'clearing evidence removes all persisted evidence',
      () async {
        await evidenceService.addEvidence(
          createEvidence(
            id: 'e1',
            questionId: 'LEGAL_OC',
            requirementLabel: 'Occupancy Certificate',
          ),
        );

        await evidenceService.addEvidence(
          createEvidence(
            id: 'e2',
            questionId: 'LEGAL_SD',
            requirementLabel: 'Registered Sale Deed',
          ),
        );

        await evidenceService.clearEvidence();

        expect(
          await evidenceService.getAllEvidence(),
          isEmpty,
        );
      },
    );

    test(
      'canonical PHS evidence requirements remain compatible',
      () {
        const mapper = PHSEvidenceMapper();

        final mapped = mapper.mapQuestions(phsQuestions);

        expect(mapped.length, 33);

        for (final question in phsQuestions) {
          expect(
            mapped[question.id],
            isNotNull,
          );

          expect(
            mapped[question.id]!,
            isNotEmpty,
          );
        }
      },
    );

    test(
      'repository persistence does not alter PHS question data',
      () async {
        const mapper = PHSEvidenceMapper();

        final question = phsQuestions.firstWhere(
          (item) => item.id == 'LEGAL_OC',
        );

        final requirements = mapper.mapQuestion(question);

        final requirement = requirements.first;

        final evidence = createEvidence(
          id: 'e1',
          questionId: requirement.questionId,
          requirementLabel: requirement.label,
          status: EvidenceStatus.verified,
          type: requirement.type,
        );

        await evidenceService.addEvidence(evidence);

        final persistedQuestion = phsQuestions.firstWhere(
          (item) => item.id == evidence.questionId,
        );

        expect(
          persistedQuestion.id,
          question.id,
        );

        expect(
          persistedQuestion.requiredEvidence,
          question.requiredEvidence,
        );
      },
    );
  });
}