import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/phs_evidence_mapper.dart';
import 'package:homesure_ai/data/phs_questions.dart';

void main() {
  group('PHSEvidenceMapper', () {
    const mapper = PHSEvidenceMapper();

    test('should map the Legal OC evidence requirements', () {
      final question = phsQuestions.firstWhere(
        (question) => question.id == 'LEGAL_OC',
      );

      final requirements = mapper.mapQuestion(question);

      expect(requirements.length, 2);

      expect(
        requirements[0],
        const EvidenceRequirement(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          type: EvidenceType.document,
        ),
      );

      expect(
        requirements[1],
        const EvidenceRequirement(
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
          type: EvidenceType.document,
        ),
      );
    });

    test('should map photograph evidence correctly', () {
      final question = phsQuestions.firstWhere(
        (question) => question.id == 'CONSTRUCTION_CRACKS',
      );

      final requirements = mapper.mapQuestion(question);

      expect(requirements.length, 3);

      expect(
        requirements[0].label,
        'Inspection photographs',
      );

      expect(
        requirements[0].type,
        EvidenceType.photograph,
      );

      expect(
        requirements[1].label,
        'Builder inspection report where applicable',
      );

      expect(
        requirements[1].type,
        EvidenceType.document,
      );

      expect(
        requirements[2].label,
        'Structural engineer report for suspected structural cracks',
      );

      expect(
        requirements[2].type,
        EvidenceType.document,
      );
    });

    test('should map Documentation Property Tax requirements', () {
      final question = phsQuestions.firstWhere(
        (question) => question.id == 'DOCUMENTATION_PROPERTY_TAX',
      );

      final requirements = mapper.mapQuestion(question);

      expect(requirements.length, 3);

      expect(
        requirements.map((requirement) => requirement.label).toList(),
        [
          'Property tax receipt',
          'Latest tax payment record',
          'Property tax assessment details where applicable',
        ],
      );

      expect(
        requirements.every(
          (requirement) => requirement.type == EvidenceType.document,
        ),
        isTrue,
      );
    });

    test('should preserve the PHS question ID for every requirement', () {
      final question = phsQuestions.firstWhere(
        (question) => question.id == 'UTILITY_BWSSB',
      );

      final requirements = mapper.mapQuestion(question);

      expect(requirements, isNotEmpty);

      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'UTILITY_BWSSB',
        ),
        isTrue,
      );
    });

    test('should preserve the original PHS evidence labels', () {
      final question = phsQuestions.firstWhere(
        (question) => question.id == 'DOCUMENTATION_BWSSB',
      );

      final requirements = mapper.mapQuestion(question);

      expect(
        requirements.map((requirement) => requirement.label).toList(),
        question.requiredEvidence,
      );
    });

    test('should map every canonical PHS question', () {
      final mapped = mapper.mapQuestions(phsQuestions);

      expect(mapped.length, phsQuestions.length);

      for (final question in phsQuestions) {
        expect(
          mapped.containsKey(question.id),
          isTrue,
          reason: 'Missing evidence mapping for ${question.id}',
        );

        expect(
          mapped[question.id]!.length,
          question.requiredEvidence.length,
          reason:
              'Evidence count mismatch for ${question.id}',
        );
      }
    });

    test(
      'should produce non-empty evidence requirements for all PHS questions',
      () {
        final mapped = mapper.mapQuestions(phsQuestions);

        for (final question in phsQuestions) {
          expect(
            mapped[question.id],
            isNotEmpty,
            reason:
                '${question.id} should have at least one evidence requirement',
          );
        }
      },
    );

    test('should classify current PHS evidence into supported types', () {
      final mapped = mapper.mapQuestions(phsQuestions);

      final allRequirements = mapped.values.expand(
        (requirements) => requirements,
      );

      expect(
        allRequirements.every(
          (requirement) =>
              EvidenceType.values.contains(requirement.type),
        ),
        isTrue,
      );
    });

    test('should map the expected number of canonical PHS questions', () {
      expect(phsQuestions.length, 33);

      final mapped = mapper.mapQuestions(phsQuestions);

      expect(mapped.length, 33);
    });

    test('should keep mapped requirement lists immutable', () {
      final mapped = mapper.mapQuestions(phsQuestions);

      expect(
        () => mapped['LEGAL_OC']!.add(
          const EvidenceRequirement(
            questionId: 'LEGAL_OC',
            label: 'Unexpected evidence',
            type: EvidenceType.document,
          ),
        ),
        throwsUnsupportedError,
      );

      final originalQuestion = phsQuestions.firstWhere(
        (question) => question.id == 'LEGAL_OC',
      );

      expect(
        originalQuestion.requiredEvidence,
        [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );
    });
  });
}