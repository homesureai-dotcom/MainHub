import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/core/phs/phs_question_progress_resolver.dart';

void main() {
  const resolver = PHSQuestionProgressResolver();

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

  group('PHSQuestionProgressResolver', () {
    test('resolves overall and category position', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_3', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_2',
        questions: questions,
      );

      expect(result, isNotNull);

      expect(result!.question.id, 'LEGAL_2');

      expect(result.questionNumber, 2);

      expect(result.totalQuestions, 4);

      expect(result.category, PHSCategory.legalOwnership);

      expect(result.categoryQuestionNumber, 2);

      expect(result.categoryQuestionCount, 3);
    });

    test('counts only answered questions from the current category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_3', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_2',
        questions: questions,
        answeredQuestionIds: {'LEGAL_1', 'CONSTRUCTION_1'},
      );

      expect(result, isNotNull);

      expect(result!.categoryAnsweredQuestions, 1);

      expect(result.categoryQuestionCount, 3);

      expect(result.categoryAnsweredCompletionPercentage, 33);

      expect(result.categoryRemainingQuestions, 2);
    });

    test('does not count answers from another category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_2',
        questions: questions,
        answeredQuestionIds: {'CONSTRUCTION_1'},
      );

      expect(result!.categoryAnsweredQuestions, 0);

      expect(result.categoryAnsweredCompletionPercentage, 0);

      expect(result.hasCategoryStarted, isFalse);
    });

    test('recognizes a fully answered category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_3', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_2',
        questions: questions,
        answeredQuestionIds: {'LEGAL_1', 'LEGAL_2', 'LEGAL_3'},
      );

      expect(result!.categoryAnsweredQuestions, 3);

      expect(result.categoryRemainingQuestions, 0);

      expect(result.categoryAnsweredCompletionPercentage, 100);

      expect(result.isCategoryComplete, isTrue);
    });

    test('resolves first question in a category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_1',
        questions: questions,
      );

      expect(result!.questionNumber, 1);

      expect(result.categoryQuestionNumber, 1);

      expect(result.categoryQuestionCount, 2);
    });

    test('resolves last question in a category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'LEGAL_2',
        questions: questions,
      );

      expect(result!.questionNumber, 3);

      expect(result.categoryQuestionNumber, 2);

      expect(result.categoryQuestionCount, 2);
    });

    test('calculates overall completion percentage', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q3', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q4', category: PHSCategory.documentation),
      ];

      final result = resolver.resolve(questionId: 'Q2', questions: questions);

      expect(result!.overallCompletionPercentage, 50);
    });

    test('calculates category position percentage', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q3', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q4', category: PHSCategory.documentation),
      ];

      final result = resolver.resolve(questionId: 'Q2', questions: questions);

      expect(result!.categoryCompletionPercentage, 67);
    });

    test('provides human-readable position labels', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q3', category: PHSCategory.documentation),
      ];

      final result = resolver.resolve(questionId: 'Q2', questions: questions);

      expect(result!.positionLabel, 'Question 2 of 3');

      expect(result.categoryPositionLabel, '2 of 2 questions');

      expect(result.categoryAnsweredLabel, '0 of 2 answered');

      expect(result.categoryDisplayName, 'Legal & Ownership');

      expect(
        result.categoryProgressLabel,
        'Legal & Ownership · 2 of 2 questions',
      );
    });

    test('preserves question catalogue order within a category', () {
      final questions = [
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_2',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'CONSTRUCTION_2',
        questions: questions,
      );

      expect(result!.questionNumber, 3);

      expect(result.categoryQuestionNumber, 2);

      expect(result.categoryQuestionCount, 2);
    });

    test('returns null for an unknown question', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
      ];

      final result = resolver.resolve(
        questionId: 'UNKNOWN',
        questions: questions,
      );

      expect(result, isNull);
    });
  });
}
