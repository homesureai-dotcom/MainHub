import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_completeness.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/phs_evidence_mapper.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  group('Evidence Intelligence Contract', () {
    const mapper = PHSEvidenceMapper();
    const matcher = EvidenceRequirementMatcher();
    const validator = EvidenceValidator();

    late Map<String, List<EvidenceRequirement>> mappedEvidence;

    setUp(() {
      mappedEvidence = mapper.mapQuestions(phsQuestions);
    });

    test('canonical PHS question count remains 33', () {
      expect(phsQuestions.length, 33);
    });

    test('every canonical PHS question has evidence requirements', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id];

        expect(
          requirements,
          isNotNull,
          reason: 'Missing evidence requirements for ${question.id}',
        );

        expect(
          requirements,
          isNotEmpty,
          reason: '${question.id} should have evidence requirements',
        );
      }
    });

    test('mapped evidence labels remain identical to PHS definitions', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id]!;

        expect(
          requirements.map((item) => item.label).toList(),
          question.requiredEvidence,
          reason:
              'Evidence definitions changed for ${question.id}',
        );
      }
    });

    test('every mapped requirement references its owning question', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id]!;

        for (final requirement in requirements) {
          expect(
            requirement.questionId,
            question.id,
          );
        }
      }
    });

    test('requirement-specific matching does not overcount same-type evidence',
        () {
      const firstRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      const secondRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'OC approval/reference details',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      expect(
        matcher.matches(
          evidence,
          firstRequirement,
        ),
        isTrue,
      );

      expect(
        matcher.matches(
          evidence,
          secondRequirement,
        ),
        isFalse,
      );
    });

    test('verified evidence satisfies its specific requirement', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC_VERIFIED',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = validator.validate(
        requirement,
        [evidence],
      );

      expect(
        result.status,
        EvidenceValidationStatus.satisfied,
      );

      expect(result.isSatisfied, isTrue);
    });

    test('provided evidence is not treated as satisfied', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC_PROVIDED',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = validator.validate(
        requirement,
        [evidence],
      );

      expect(
        result.status,
        EvidenceValidationStatus.provided,
      );

      expect(result.isSatisfied, isFalse);
    });

    test('rejected evidence is not treated as satisfied', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC_REJECTED',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.rejected,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = validator.validate(
        requirement,
        [evidence],
      );

      expect(
        result.status,
        EvidenceValidationStatus.rejected,
      );

      expect(result.isSatisfied, isFalse);
    });

    test('missing evidence is correctly identified', () {
      const requirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final result = validator.validate(
        requirement,
        const [],
      );

      expect(
        result.status,
        EvidenceValidationStatus.missing,
      );

      expect(result.isSatisfied, isFalse);
    });

    test('completeness counts requirements rather than evidence files', () {
      const firstRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      const secondRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'OC approval/reference details',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final completeness = EvidenceCompleteness.calculate(
        requirements: [
          firstRequirement,
          secondRequirement,
        ],
        evidence: [
          evidence,
        ],
      );

      expect(completeness.totalRequirements, 2);
      expect(completeness.matchedRequirements, 1);
      expect(completeness.missingRequirements, 1);
      expect(completeness.coveragePercentage, 50);
    });

    test('verified evidence can satisfy one requirement while another remains missing',
        () {
      const firstRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      const secondRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'OC approval/reference details',
        type: EvidenceType.document,
      );

      final evidence = Evidence(
        id: 'EVIDENCE_OC_VERIFIED',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final validationResults = validator.validateAll(
        [
          firstRequirement,
          secondRequirement,
        ],
        [
          evidence,
        ],
      );

      expect(
        validationResults[0].status,
        EvidenceValidationStatus.satisfied,
      );

      expect(
        validationResults[1].status,
        EvidenceValidationStatus.missing,
      );
    });

    test('evidence intelligence covers every canonical PHS question exactly once',
        () {
      expect(
        mappedEvidence.keys.length,
        phsQuestions.length,
      );

      final canonicalIds = phsQuestions
          .map((question) => question.id)
          .toSet();

      expect(
        mappedEvidence.keys.toSet(),
        canonicalIds,
      );
    });

    test('evidence intelligence does not mutate canonical PHS evidence definitions',
        () {
      for (final question in phsQuestions) {
        final originalEvidence = List<String>.from(
          question.requiredEvidence,
        );

        final requirements = mappedEvidence[question.id]!;

        validator.validateAll(
          requirements,
          const [],
        );

        expect(
          question.requiredEvidence,
          originalEvidence,
          reason:
              'Canonical evidence definitions changed for ${question.id}',
        );
      }
    });
  });
}