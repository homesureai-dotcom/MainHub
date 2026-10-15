import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_category_progress.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';

void main() {
  PHSQuestion createQuestion({
    required String id,
    required PHSCategory category,
  }) {
    return PHSQuestion(
      id: id,
      category: category,
      title: 'Test question $id',
      helpText: 'Test help text',
      weight: 1,
      requiredEvidence: const [],
      applicableTo: const [PropertyType.apartment],
    );
  }

  group('PHSCategoryProgress', () {
    test('calculates completion correctly', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.legalOwnership,
        totalQuestions: 4,
        answeredQuestions: 2,
      );

      expect(progress.totalQuestions, 4);

      expect(progress.answeredQuestions, 2);

      expect(progress.remainingQuestions, 2);

      expect(progress.completion, 0.5);

      expect(progress.completionPercentage, 50);

      expect(progress.isComplete, isFalse);

      expect(progress.hasStarted, isTrue);

      expect(progress.isNotStarted, isFalse);
    });

    test('marks category complete when all questions are answered', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.documentation,
        totalQuestions: 5,
        answeredQuestions: 5,
      );

      expect(progress.remainingQuestions, 0);

      expect(progress.completion, 1.0);

      expect(progress.completionPercentage, 100);

      expect(progress.isComplete, isTrue);

      expect(progress.hasStarted, isTrue);

      expect(progress.isNotStarted, isFalse);
    });

    test('identifies a category that has not started', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.constructionQuality,
        totalQuestions: 8,
        answeredQuestions: 0,
      );

      expect(progress.remainingQuestions, 8);

      expect(progress.completion, 0.0);

      expect(progress.completionPercentage, 0);

      expect(progress.isComplete, isFalse);

      expect(progress.hasStarted, isFalse);

      expect(progress.isNotStarted, isTrue);
    });

    test('does not exceed one hundred percent', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.safetyCompliance,
        totalQuestions: 4,
        answeredQuestions: 7,
      );

      expect(progress.completion, 1.0);

      expect(progress.completionPercentage, 100);

      expect(progress.remainingQuestions, 0);

      expect(progress.isComplete, isTrue);
    });

    test('handles category with no questions', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.communityMaintenance,
        totalQuestions: 0,
        answeredQuestions: 0,
      );

      expect(progress.completion, 0.0);

      expect(progress.completionPercentage, 0);

      expect(progress.remainingQuestions, 0);

      expect(progress.isComplete, isFalse);

      expect(progress.hasStarted, isFalse);
    });

    test('uses canonical category metadata', () {
      const progress = PHSCategoryProgress(
        category: PHSCategory.legalOwnership,
        totalQuestions: 4,
        answeredQuestions: 1,
      );

      expect(progress.displayName, 'Legal & Ownership');

      expect(progress.weight, 25.0);

      expect(progress.icon, '⚖️');

      expect(
        progress.description,
        'Verifies legal ownership, approvals and statutory compliance.',
      );
    });

    test('builds progress from question catalogue and answered IDs', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q3', category: PHSCategory.constructionQuality),
        createQuestion(id: 'Q4', category: PHSCategory.legalOwnership),
      ];

      final progress = PHSCategoryProgress.fromQuestions(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answeredQuestionIds: {'Q1', 'Q3'},
      );

      expect(progress.totalQuestions, 3);

      expect(progress.answeredQuestions, 1);

      expect(progress.remainingQuestions, 2);

      expect(progress.completionPercentage, 33);

      expect(progress.isComplete, isFalse);
    });

    test('ignores answered IDs belonging to another category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final progress = PHSCategoryProgress.fromQuestions(
        category: PHSCategory.legalOwnership,
        questions: questions,
        answeredQuestionIds: {'CONSTRUCTION_1'},
      );

      expect(progress.totalQuestions, 1);

      expect(progress.answeredQuestions, 0);

      expect(progress.completionPercentage, 0);
    });

    test('supports equality based on progress values', () {
      const first = PHSCategoryProgress(
        category: PHSCategory.documentation,
        totalQuestions: 5,
        answeredQuestions: 2,
      );

      const second = PHSCategoryProgress(
        category: PHSCategory.documentation,
        totalQuestions: 5,
        answeredQuestions: 2,
      );

      const different = PHSCategoryProgress(
        category: PHSCategory.documentation,
        totalQuestions: 5,
        answeredQuestions: 3,
      );

      expect(first, equals(second));

      expect(first, isNot(equals(different)));
    });
  });
}
