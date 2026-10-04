import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_requirement_resolver.dart';
import 'package:homesure_ai/core/evidence/evidence_type_mapper.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';

void main() {
  group('EvidenceRequirementResolver', () {
    late EvidenceRequirementResolver resolver;

    setUp(() {
      resolver = const EvidenceRequirementResolver(
        typeMapper: EvidenceTypeMapper(),
      );
    });

    PHSQuestion createQuestion({
      required String id,
      required String title,
      required List<String> requiredEvidence,
      PHSCategory category = PHSCategory.legalOwnership,
    }) {
      return PHSQuestion(
        id: id,
        category: category,
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

    test('resolves all evidence requirements for a question', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

      final requirements = resolver.resolve(question);

      expect(requirements.length, 2);

      expect(
        requirements[0].questionId,
        'LEGAL_OC',
      );

      expect(
        requirements[0].label,
        'Occupancy Certificate',
      );

      expect(
        requirements[1].questionId,
        'LEGAL_OC',
      );

      expect(
        requirements[1].label,
        'OC approval/reference details',
      );
    });

    test('maps document evidence requirements correctly', () {
      final question = createQuestion(
        id: 'LEGAL_SD',
        title: 'Is the Sale Deed registered?',
        requiredEvidence: const [
          'Registered Sale Deed',
          'Registration details',
        ],
      );

      final requirements = resolver.resolve(question);

      expect(
        requirements.every(
          (requirement) => requirement.isDocument,
        ),
        isTrue,
      );
    });

    test('preserves the canonical evidence requirement order', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );

      final requirements = resolver.resolve(question);

      expect(
        requirements.map((item) => item.label).toList(),
        [
          'Occupancy Certificate',
          'OC approval/reference details',
        ],
      );
    });

    test('returns an immutable requirement list', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      final requirements = resolver.resolve(question);

      expect(
        () => requirements.add(
          requirements.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('resolves multiple questions into a question keyed map', () {
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

      final result = resolver.resolveAll(questions);

      expect(
        result.keys,
        containsAll([
          'LEGAL_OC',
          'LEGAL_SD',
        ]),
      );

      expect(
        result['LEGAL_OC']?.length,
        2,
      );

      expect(
        result['LEGAL_SD']?.length,
        2,
      );
    });

    test('returns an immutable map from resolveAll', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      final result = resolver.resolveAll([
        question,
      ]);

      expect(
        () => result['LEGAL_SD'] = const [],
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('resolves a canonical question by question ID', () {
      final requirements =
          resolver.resolveByQuestionId('LEGAL_OC');

      expect(
        requirements,
        isNotEmpty,
      );

      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'LEGAL_OC',
        ),
        isTrue,
      );

      expect(
        requirements.map((item) => item.label),
        containsAll([
          'Occupancy Certificate',
          'OC approval/reference details',
        ]),
      );
    });

    test('resolves another canonical PHS question by ID', () {
      final requirements =
          resolver.resolveByQuestionId('LEGAL_SD');

      expect(
        requirements,
        isNotEmpty,
      );

      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'LEGAL_SD',
        ),
        isTrue,
      );

      expect(
        requirements.map((item) => item.label),
        containsAll([
          'Registered Sale Deed',
          'Registration details',
        ]),
      );
    });

    test('returns empty requirements for an unknown question ID', () {
      final requirements =
          resolver.resolveByQuestionId('UNKNOWN_QUESTION');

      expect(requirements, isEmpty);
    });

    test('reports when a question has evidence requirements', () {
      final question = createQuestion(
        id: 'LEGAL_OC',
        title: 'Is the Occupancy Certificate available?',
        requiredEvidence: const [
          'Occupancy Certificate',
        ],
      );

      expect(
        resolver.hasRequirements(question),
        isTrue,
      );
    });

    test('reports when a question has no evidence requirements', () {
      final question = createQuestion(
        id: 'TEST_NO_EVIDENCE',
        title: 'Test question without evidence.',
        requiredEvidence: const [],
      );

      expect(
        resolver.hasRequirements(question),
        isFalse,
      );
    });

    test('preserves question ID on every resolved requirement', () {
      final question = createQuestion(
        id: 'LEGAL_EC',
        title: 'Is the Encumbrance Certificate available?',
        requiredEvidence: const [
          'Encumbrance Certificate',
          'Relevant EC period',
        ],
      );

      final requirements = resolver.resolve(question);

      expect(
        requirements.every(
          (requirement) => requirement.questionId == 'LEGAL_EC',
        ),
        isTrue,
      );
    });
  });
}