import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/phs_evidence_mapper.dart';
import 'package:homesure_ai/core/evidence/evidence_status_rules.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  group('Evidence Foundation Contract', () {
    const mapper = PHSEvidenceMapper();
    const statusRules = EvidenceStatusRules();

    late Map<String, List<EvidenceRequirement>> mappedEvidence;

    setUp(() {
      mappedEvidence = mapper.mapQuestions(phsQuestions);
    });

    test('canonical PHS question count should remain 33', () {
      expect(phsQuestions.length, 33);
    });

    test('every canonical PHS question should have evidence requirements', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id];

        expect(
          requirements,
          isNotNull,
          reason: 'Missing evidence mapping for ${question.id}',
        );

        expect(
          requirements,
          isNotEmpty,
          reason:
              '${question.id} should have at least one evidence requirement',
        );
      }
    });

    test('evidence requirement count should match PHS source definitions', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id]!;

        expect(
          requirements.length,
          question.requiredEvidence.length,
          reason:
              'Evidence count mismatch for ${question.id}',
        );
      }
    });

    test('evidence labels should exactly match PHS source definitions', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id]!;

        expect(
          requirements.map((requirement) => requirement.label).toList(),
          question.requiredEvidence,
          reason:
              'Evidence labels changed for ${question.id}',
        );
      }
    });

    test('every evidence requirement should reference its owning question', () {
      for (final question in phsQuestions) {
        final requirements = mappedEvidence[question.id]!;

        for (final requirement in requirements) {
          expect(
            requirement.questionId,
            question.id,
            reason:
                'Incorrect question ID on evidence requirement '
                '${requirement.label}',
          );
        }
      }
    });

    test('every mapped evidence type should be supported', () {
      for (final requirements in mappedEvidence.values) {
        for (final requirement in requirements) {
          expect(
            EvidenceType.values.contains(requirement.type),
            isTrue,
            reason:
                'Unsupported evidence type for ${requirement.label}',
          );
        }
      }
    });

    test('document evidence classification should remain valid', () {
      const documentLabels = [
        'Occupancy Certificate',
        'Registered Sale Deed',
        'Khata certificate',
        'Encumbrance Certificate',
        'BESCOM documents',
        'BWSSB documents',
        'Fire NOC',
        'Property tax receipt',
        'Builder warranty documents',
        'Operation and maintenance manuals',
      ];

      for (final label in documentLabels) {
        final question = phsQuestions.firstWhere(
          (question) =>
              question.requiredEvidence.contains(label),
        );

        final requirement = mappedEvidence[question.id]!.firstWhere(
          (requirement) => requirement.label == label,
        );

        expect(
          requirement.type,
          EvidenceType.document,
          reason:
              '$label should be classified as document evidence',
        );
      }
    });

    test('photograph evidence classification should remain valid', () {
      const photographLabels = [
        'Inspection photographs',
        'Site inspection photographs',
      ];

      for (final label in photographLabels) {
        final question = phsQuestions.firstWhere(
          (question) =>
              question.requiredEvidence.contains(label),
        );

        final requirement = mappedEvidence[question.id]!.firstWhere(
          (requirement) => requirement.label == label,
        );

        expect(
          requirement.type,
          EvidenceType.photograph,
          reason:
              '$label should be classified as photograph evidence',
        );
      }
    });

    test('evidence status lifecycle should remain valid', () {
      expect(
        statusRules.canTransition(
          EvidenceStatus.notProvided,
          EvidenceStatus.provided,
        ),
        isTrue,
      );

      expect(
        statusRules.canTransition(
          EvidenceStatus.provided,
          EvidenceStatus.needsReview,
        ),
        isTrue,
      );

      expect(
        statusRules.canTransition(
          EvidenceStatus.needsReview,
          EvidenceStatus.verified,
        ),
        isTrue,
      );

      expect(
        statusRules.canTransition(
          EvidenceStatus.verified,
          EvidenceStatus.rejected,
        ),
        isFalse,
      );

      expect(
        statusRules.canTransition(
          EvidenceStatus.rejected,
          EvidenceStatus.verified,
        ),
        isFalse,
      );
    });

    test('evidence requirements should not mutate PHS source definitions', () {
      for (final question in phsQuestions) {
        final originalEvidence = List<String>.from(
          question.requiredEvidence,
        );

        mapper.mapQuestion(question);

        expect(
          question.requiredEvidence,
          originalEvidence,
          reason:
              'PHS evidence definitions were mutated for ${question.id}',
        );
      }
    });

    test('mapping should cover every PHS question exactly once', () {
      expect(
        mappedEvidence.keys.length,
        phsQuestions.length,
      );

      final questionIds = phsQuestions
          .map((question) => question.id)
          .toSet();

      expect(
        mappedEvidence.keys.toSet(),
        questionIds,
      );
    });

    test('evidence foundation should preserve the canonical question IDs',
        () {
      for (final question in phsQuestions) {
        expect(
          mappedEvidence.containsKey(question.id),
          isTrue,
          reason:
              'Canonical question ID missing: ${question.id}',
        );
      }
    });
  });
}