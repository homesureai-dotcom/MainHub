import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/core/phs/phs_question_progress.dart';

void main() {
  PHSQuestion createQuestion() {
    return const PHSQuestion(
      id: 'CONSTRUCTION_DAMPNESS',
      category: PHSCategory.constructionQuality,
      title: 'Is the property free from significant dampness?',
      helpText: 'Check the property for signs of dampness.',
      weight: 15,
      requiredEvidence: [],
      applicableTo: [PropertyType.apartment],
    );
  }

  group('PHSQuestionProgress', () {
    test('exposes the current category', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.category, PHSCategory.constructionQuality);
    });

    test('calculates one-based question position', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.questionNumber, 14);

      expect(progress.categoryQuestionNumber, 4);
    });

    test('calculates overall completion', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.overallCompletionPercentage, 42);
    });

    test('calculates current pillar position', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.categoryCompletionPercentage, 50);
    });

    test('calculates actual answered pillar progress', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.categoryAnsweredQuestions, 3);

      expect(progress.categoryAnsweredCompletionPercentage, 38);

      expect(progress.categoryRemainingQuestions, 5);

      expect(progress.hasCategoryStarted, isTrue);

      expect(progress.isCategoryComplete, isFalse);
    });

    test('provides assessment position label', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.positionLabel, 'Question 14 of 33');
    });

    test('provides pillar position label', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.categoryPositionLabel, '4 of 8 questions');
    });

    test('provides pillar answered label', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(progress.categoryAnsweredLabel, '3 of 8 answered');

      expect(progress.categoryAnsweredProgressLabel, '3 of 8 answered');
    });

    test('provides combined pillar progress label', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 3,
      );

      expect(
        progress.categoryProgressLabel,
        'Construction Quality · '
        '4 of 8 questions',
      );
    });

    test('identifies a completed pillar', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 8,
      );

      expect(progress.categoryAnsweredQuestions, 8);

      expect(progress.categoryRemainingQuestions, 0);

      expect(progress.categoryAnsweredCompletionPercentage, 100);

      expect(progress.hasCategoryStarted, isTrue);

      expect(progress.isCategoryComplete, isTrue);
    });

    test('clamps answered count to category question count', () {
      final progress = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 13,
        totalQuestions: 33,
        categoryQuestionIndex: 3,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 20,
      );

      expect(progress.categoryAnsweredQuestions, 8);

      expect(progress.categoryRemainingQuestions, 0);

      expect(progress.categoryAnsweredCompletionPercentage, 100);
    });

    test('identifies first and last positions', () {
      final first = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 0,
        totalQuestions: 33,
        categoryQuestionIndex: 0,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 0,
      );

      final last = PHSQuestionProgress(
        question: createQuestion(),
        questionIndex: 32,
        totalQuestions: 33,
        categoryQuestionIndex: 7,
        categoryQuestionCount: 8,
        categoryAnsweredQuestionCount: 8,
      );

      expect(first.isFirstQuestion, isTrue);

      expect(first.isFirstQuestionInCategory, isTrue);

      expect(first.isLastQuestion, isFalse);

      expect(last.isLastQuestion, isTrue);

      expect(last.isLastQuestionInCategory, isTrue);
    });
  });
}
