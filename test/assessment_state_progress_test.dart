import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/state/assessment_state.dart';

void main() {
  late AssessmentState assessmentState;

  setUp(() {
    assessmentState = AssessmentState.instance;

    assessmentState.clearAssessment();
  });

  tearDown(() {
    assessmentState.clearAssessment();
  });

  group('AssessmentState.assessmentProgress', () {
    test('returns zero progress when assessment has no answers', () {
      expect(
        assessmentState.assessmentProgress.totalQuestions,
        phsQuestions.length,
      );

      expect(assessmentState.assessmentProgress.answeredQuestions, 0);

      expect(assessmentState.assessmentProgress.completionPercentage, 0);

      expect(assessmentState.assessmentProgress.hasStarted, isFalse);

      expect(assessmentState.assessmentProgress.isComplete, isFalse);
    });

    test('updates progress when an answer is saved', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.yes),
      );

      final progress = assessmentState.assessmentProgress;

      expect(progress.totalQuestions, phsQuestions.length);

      expect(progress.answeredQuestions, 1);

      expect(progress.remainingQuestions, phsQuestions.length - 1);

      expect(progress.hasStarted, isTrue);

      expect(progress.isComplete, isFalse);

      expect(
        progress.completionPercentage,
        ((1 / phsQuestions.length) * 100).round(),
      );
    });

    test('uses the latest answer for the same question', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.yes),
      );

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.no),
      );

      final progress = assessmentState.assessmentProgress;

      expect(assessmentState.answers.length, 1);

      expect(progress.answeredQuestions, 1);
    });

    test('progress contains the canonical six PHS categories', () {
      final progress = assessmentState.assessmentProgress;

      expect(progress.totalCategoryCount, PHSCategory.values.length);

      expect(progress.totalCategoryCount, 6);
    });

    test('progress reflects multiple answered questions', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final questions = phsQuestions.take(3).toList();

      for (final question in questions) {
        assessmentState.saveAnswer(
          PHSAnswer(questionId: question.id, response: PHSResponse.yes),
        );
      }

      final progress = assessmentState.assessmentProgress;

      expect(progress.answeredQuestions, 3);

      expect(progress.remainingQuestions, phsQuestions.length - 3);

      expect(
        progress.completionPercentage,
        ((3 / phsQuestions.length) * 100).round(),
      );

      expect(progress.hasStarted, isTrue);
    });

    test('progress resets when a new assessment starts', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.yes),
      );

      expect(assessmentState.assessmentProgress.answeredQuestions, 1);

      assessmentState.startNewAssessment(propertyId: 'P001');

      expect(assessmentState.assessmentProgress.answeredQuestions, 0);

      expect(assessmentState.assessmentProgress.completionPercentage, 0);

      expect(assessmentState.assessmentProgress.hasStarted, isFalse);
    });

    test('progress is restored from an active session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final questions = phsQuestions.take(2).toList();

      for (final question in questions) {
        assessmentState.saveAnswer(
          PHSAnswer(questionId: question.id, response: PHSResponse.yes),
        );
      }

      assessmentState.saveAndExit();

      expect(assessmentState.assessmentProgress.answeredQuestions, 2);

      assessmentState.startAssessment(propertyId: 'P001');

      final progress = assessmentState.assessmentProgress;

      expect(progress.answeredQuestions, 2);

      expect(
        progress.completionPercentage,
        ((2 / phsQuestions.length) * 100).round(),
      );
    });

    test('progress exposes the current category', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final firstQuestion = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
      );

      final progress = assessmentState.assessmentProgress;

      expect(progress.currentCategory, isNotNull);
    });

    test('clearAssessment resets progress', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.yes),
      );

      expect(assessmentState.assessmentProgress.answeredQuestions, 1);

      assessmentState.clearAssessment();

      expect(assessmentState.assessmentProgress.answeredQuestions, 0);

      expect(assessmentState.assessmentProgress.completionPercentage, 0);

      expect(assessmentState.assessmentProgress.hasStarted, isFalse);
    });

    test('exposes current question progress', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.updateCurrentQuestion(question.id);

      final progress = assessmentState.currentQuestionProgress;

      expect(progress, isNotNull);

      expect(progress!.question.id, question.id);

      expect(progress.questionNumber, 1);

      expect(progress.totalQuestions, phsQuestions.length);

      expect(progress.category, question.category);
    });

    test('current question progress updates when navigating', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final firstQuestion = phsQuestions.first;

      final secondQuestion = phsQuestions[1];

      assessmentState.updateCurrentQuestion(firstQuestion.id);

      expect(
        assessmentState.currentQuestionProgress!.question.id,
        firstQuestion.id,
      );

      assessmentState.updateCurrentQuestion(secondQuestion.id);

      expect(
        assessmentState.currentQuestionProgress!.question.id,
        secondQuestion.id,
      );

      expect(assessmentState.currentQuestionProgress!.questionNumber, 2);
    });

    test('current question progress is null before a question is selected', () {
      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.currentQuestionProgress, isNull);
    });

    test('current question progress survives save and exit', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions[2];

      assessmentState.updateCurrentQuestion(question.id);

      assessmentState.saveAndExit();

      expect(assessmentState.currentQuestionProgress!.question.id, question.id);

      expect(assessmentState.currentQuestionProgress!.questionNumber, 3);
    });

    test('new assessment session starts in progress', () {
      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.session!.isInProgress, isTrue);
      expect(assessmentState.hasActiveSession, isTrue);
      expect(assessmentState.hasCompletedSession, isFalse);
      expect(assessmentState.session!.propertyId, 'P001');
      expect(assessmentState.session!.answers, isEmpty);
    });

    test('completed assessment session changes to completed status', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(questionId: question.id, response: PHSResponse.yes),
      );

      assessmentState.completeAssessment();

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.session!.isCompleted, isTrue);
      expect(assessmentState.hasCompletedSession, isTrue);
      expect(assessmentState.hasActiveSession, isFalse);
    });

    test('restores the saved current question when an active session resumes',
        () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions[2];

      assessmentState.updateCurrentQuestion(question.id);

      assessmentState.saveAndExit();

      expect(assessmentState.currentQuestionId, question.id);

      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.hasActiveSession, isTrue);
      expect(assessmentState.currentQuestionId, question.id);
      expect(
        assessmentState.currentQuestionProgress!.questionNumber,
        3,
      );
    });
  });
}
