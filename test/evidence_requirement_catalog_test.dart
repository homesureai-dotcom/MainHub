import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_requirement_catalog.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_resolver.dart';
import 'package:homesure_ai/core/evidence/evidence_type_mapper.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';

void main() {
  group('EvidenceRequirementCatalog', () {
    late EvidenceRequirementCatalog catalog;

    setUp(() {
      catalog = const EvidenceRequirementCatalog(
        resolver: EvidenceRequirementResolver(
          typeMapper: EvidenceTypeMapper(),
        ),
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

    test('gets requirements for a single question', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

      final requirements = catalog.getForQuestion(question);

      expect(requirements.length, 2);
      expect(requirements[0].questionId, 'LEGAL_OC');
      expect(requirements[0].label, 'Occupancy Certificate');
      expect(
        requirements[1].label,
        'OC approval/reference details',
      );
    });

    test('gets requirements by canonical question ID', () {
      final requirements =
          catalog.getForQuestionId('LEGAL_OC');

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
          catalog.getForQuestionId('UNKNOWN_QUESTION');

      expect(requirements, isEmpty);
    });

    test('reports whether a question has requirements', () {
      expect(
        catalog.hasRequirements('LEGAL_OC'),
        isTrue,
      );

      expect(
        catalog.hasRequirements('UNKNOWN_QUESTION'),
        isFalse,
      );
    });

    test('detects an existing evidence requirement', () {
      expect(
        catalog.containsRequirement(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        isTrue,
      );
    });

    test('does not match an unknown evidence requirement', () {
      expect(
        catalog.containsRequirement(
          questionId: 'LEGAL_OC',
          label: 'Unknown Document',
        ),
        isFalse,
      );
    });

    test('does not match a requirement from another question', () {
      expect(
        catalog.containsRequirement(
          questionId: 'LEGAL_OC',
          label: 'Registered Sale Deed',
        ),
        isFalse,
      );
    });

    test('gets requirements for multiple questions', () {
      final questions = <PHSQuestion>[
        createQuestion(
          id: 'LEGAL_OC',
          title: 'Is the Occupancy Certificate available?',
          requiredEvidence: const [
            'Occupancy Certificate',
            'OC approval/reference details',
          ],
        ),
        createQuestion(
          id: 'LEGAL_SD',
          title: 'Is the Sale Deed registered?',
          requiredEvidence: const [
            'Registered Sale Deed',
            'Registration details',
          ],
        ),
      ];

      final result = catalog.getForQuestions(questions);

      expect(result.keys, containsAll([
        'LEGAL_OC',
        'LEGAL_SD',
      ]));

      expect(result['LEGAL_OC']?.length, 2);
      expect(result['LEGAL_SD']?.length, 2);
    });

    test('returns an immutable map for multiple questions', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      final result = catalog.getForQuestions([
        question,
      ]);

      expect(
        () => result['LEGAL_SD'] = const [],
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('flattens requirements from multiple questions', () {
      final questions = <PHSQuestion>[
        createQuestion(
          id: 'LEGAL_OC',
          title: 'Is the Occupancy Certificate available?',
          requiredEvidence: const [
            'Occupancy Certificate',
            'OC approval/reference details',
          ],
        ),
        createQuestion(
          id: 'LEGAL_SD',
          title: 'Is the Sale Deed registered?',
          requiredEvidence: const [
            'Registered Sale Deed',
            'Registration details',
          ],
        ),
      ];

      final result = catalog.flatten(questions);

      expect(result.length, 4);

      expect(
        result.map((requirement) => requirement.questionId).toList(),
        [
          'LEGAL_OC',
          'LEGAL_OC',
          'LEGAL_SD',
          'LEGAL_SD',
        ],
      );
    });

    test('flatten preserves requirement order', () {
      final questions = <PHSQuestion>[
        createQuestion(
          id: 'LEGAL_OC',
          title: 'Is the Occupancy Certificate available?',
          requiredEvidence: const [
            'Occupancy Certificate',
            'OC approval/reference details',
          ],
        ),
        createQuestion(
          id: 'LEGAL_SD',
          title: 'Is the Sale Deed registered?',
          requiredEvidence: const [
            'Registered Sale Deed',
            'Registration details',
          ],
        ),
      ];

      final result = catalog.flatten(questions);

      expect(
        result.map((requirement) => requirement.label).toList(),
        [
          'Occupancy Certificate',
          'OC approval/reference details',
          'Registered Sale Deed',
          'Registration details',
        ],
      );
    });

    test('returns an immutable flattened requirement list', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      final result = catalog.flatten([
        question,
      ]);

      expect(
        () => result.add(result.first),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}