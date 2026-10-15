import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_assessment_progress.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
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

  PHSAnswer createAnswer(String questionId) {
    return PHSAnswer(questionId: questionId, response: PHSResponse.yes);
  }

  group('PHSAssessmentProgress', () {
    test('calculates overall question completion', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q3', category: PHSCategory.constructionQuality),
        createQuestion(id: 'Q4', category: PHSCategory.documentation),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('Q1'), createAnswer('Q2')],
      );

      expect(progress.totalQuestions, 4);

      expect(progress.answeredQuestions, 2);

      expect(progress.remainingQuestions, 2);

      expect(progress.completion, 0.5);

      expect(progress.completionPercentage, 50);

      expect(progress.hasStarted, isTrue);

      expect(progress.isComplete, isFalse);
    });

    test('creates progress for all six PHS pillars', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.constructionQuality),
        createQuestion(id: 'Q3', category: PHSCategory.utilitiesInfrastructure),
        createQuestion(id: 'Q4', category: PHSCategory.safetyCompliance),
        createQuestion(id: 'Q5', category: PHSCategory.communityMaintenance),
        createQuestion(id: 'Q6', category: PHSCategory.documentation),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: const [],
      );

      expect(progress.totalCategoryCount, 6);

      expect(progress.completedCategoryCount, 0);

      expect(progress.startedCategoryCount, 0);

      expect(progress.notStartedCategoryCount, 6);

      expect(progress.categoryCompletionPercentage, 0);

      expect(progress.categories.length, 6);
    });

    test('identifies completed and active categories', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(
          id: 'CONSTRUCTION_2',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(
          id: 'UTILITIES_1',
          category: PHSCategory.utilitiesInfrastructure,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [
          createAnswer('LEGAL_1'),
          createAnswer('LEGAL_2'),
          createAnswer('CONSTRUCTION_1'),
        ],
      );

      expect(progress.completedCategoryCount, 1);

      expect(progress.startedCategoryCount, 2);

      expect(progress.notStartedCategoryCount, 4);

      expect(progress.currentCategory, PHSCategory.constructionQuality);

      expect(progress.activeCategory, PHSCategory.constructionQuality);

      expect(progress.categoryCompletionPercentage, 17);
    });

    test('returns progress for a specific category', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(id: 'DOC_1', category: PHSCategory.documentation),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      final legalProgress = progress.progressFor(PHSCategory.legalOwnership);

      expect(legalProgress, isNotNull);

      expect(legalProgress!.totalQuestions, 2);

      expect(legalProgress.answeredQuestions, 1);

      expect(legalProgress.completionPercentage, 50);

      final documentationProgress = progress.progressFor(
        PHSCategory.documentation,
      );

      expect(documentationProgress, isNotNull);

      expect(documentationProgress!.answeredQuestions, 0);
    });

    test('reports complete when every question is answered', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.documentation),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('Q1'), createAnswer('Q2')],
      );

      expect(progress.answeredQuestions, 2);

      expect(progress.remainingQuestions, 0);

      expect(progress.completionPercentage, 100);

      expect(progress.isComplete, isTrue);

      expect(progress.completedCategoryCount, 2);

      expect(progress.categoryCompletionPercentage, 33);

      expect(progress.currentCategory, isNull);

      expect(progress.activeCategory, isNull);
    });

    test('does not count duplicate answers twice', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'Q2', category: PHSCategory.legalOwnership),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('Q1'), createAnswer('Q1'), createAnswer('Q1')],
      );

      expect(progress.totalQuestions, 2);

      expect(progress.answeredQuestions, 1);

      expect(progress.completionPercentage, 50);
    });

    test('ignores answers for questions outside the catalogue', () {
      final questions = [
        createQuestion(id: 'Q1', category: PHSCategory.legalOwnership),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('UNKNOWN')],
      );

      expect(progress.totalQuestions, 1);

      expect(progress.answeredQuestions, 0);

      expect(progress.completionPercentage, 0);
    });

    test('identifies the first incomplete category as current', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      expect(progress.currentCategory, PHSCategory.constructionQuality);

      expect(progress.activeCategory, PHSCategory.constructionQuality);
    });

    test('uses the active category when a pillar is partially complete', () {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1'), createAnswer('CONSTRUCTION_1')],
      );

      expect(progress.activeCategory, PHSCategory.legalOwnership);

      expect(progress.currentCategory, PHSCategory.legalOwnership);
    });
  });
}
