import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_category_question_resolver.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';

void main() {
  const resolver = PHSCategoryQuestionResolver();

  PHSQuestion createQuestion({
    required String id,
    required PHSCategory category,
  }) {
    return PHSQuestion(
      id: id,
      category: category,
      title: 'Question $id',
      helpText: 'Help for $id',
      weight: 1,
      requiredEvidence: const [],
      applicableTo: const [PropertyType.apartment],
    );
  }

  PHSAnswer createAnswer(String questionId) {
    return PHSAnswer(questionId: questionId, response: PHSResponse.yes);
  }

  group('PHSCategoryQuestionResolver', () {
    test('returns the first question in a category when none are answered', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'DOC_1', category: PHSCategory.documentation),
      ];

      final result = resolver.resolve(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: const [],
      );

      expect(result?.id, 'LEGAL_1');
    });

    test('returns the first unanswered question in a category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_3', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      expect(result?.id, 'LEGAL_2');
    });

    test('skips multiple answered questions', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_3', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: [createAnswer('LEGAL_1'), createAnswer('LEGAL_2')],
      );

      expect(result?.id, 'LEGAL_3');
    });

    test('returns first question when entire category is complete', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: [createAnswer('LEGAL_1'), createAnswer('LEGAL_2')],
      );

      expect(result?.id, 'LEGAL_1');
    });

    test('ignores answers belonging to another category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final result = resolver.resolve(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: [createAnswer('CONSTRUCTION_1')],
      );

      expect(result?.id, 'LEGAL_1');
    });

    test('returns null when category has no questions', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        category: PHSCategory.documentation,
        questions: questions,
        answers: const [],
      );

      expect(result, isNull);
    });

    test('returns the resolved question index', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final index = resolver.resolveIndex(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      expect(index, 2);
    });

    test('returns null index when category has no questions', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
      ];

      final index = resolver.resolveIndex(
        category: PHSCategory.documentation,
        questions: questions,
        answers: const [],
      );

      expect(index, isNull);
    });
  });
}
