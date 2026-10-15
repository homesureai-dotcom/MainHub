import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/assessment/assessment_session.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
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

  group('Assessment Session', () {
    test('new assessment session starts in progress', () {
      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);
      expect(
        assessmentState.session!.status,
        AssessmentSessionStatus.inProgress,
      );
      expect(assessmentState.hasActiveSession, isTrue);
      expect(assessmentState.hasCompletedSession, isFalse);
    });

    test('new assessment session stores the property ID', () {
      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.session!.propertyId, 'P001');
      expect(assessmentState.propertyId, 'P001');
    });

    test('saving an answer stores it in the active session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: question.id,
      );

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.session!.answers, hasLength(1));
      expect(
        assessmentState.session!.answers.first.questionId,
        question.id,
      );
    });

    test('saving an answer updates the current question', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions[2];

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: question.id,
      );

      expect(assessmentState.currentQuestionId, question.id);
      expect(
        assessmentState.session!.currentQuestionId,
        question.id,
      );
    });

    test('saveAndExit preserves the active session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions[2];

      assessmentState.updateCurrentQuestion(question.id);

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
      );

      assessmentState.saveAndExit();

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.hasActiveSession, isTrue);
      expect(assessmentState.currentQuestionId, question.id);
      expect(assessmentState.session!.answers, hasLength(1));
    });

    test('starting an active assessment resumes the existing session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final question = phsQuestions[2];

      assessmentState.updateCurrentQuestion(question.id);

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
      );

      final originalSession = assessmentState.session;

      assessmentState.saveAndExit();

      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);
      expect(assessmentState.hasActiveSession, isTrue);
      expect(
        assessmentState.session!.assessmentId,
        originalSession!.assessmentId,
      );
      expect(assessmentState.currentQuestionId, question.id);
      expect(assessmentState.answers, hasLength(1));
    });

    test('startNewAssessment creates a fresh session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      final firstSessionId =
          assessmentState.session!.assessmentId;

      final question = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
      );

      assessmentState.startNewAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);
      expect(
        assessmentState.session!.assessmentId,
        isNot(firstSessionId),
      );
      expect(assessmentState.session!.status,
          AssessmentSessionStatus.inProgress);
      expect(assessmentState.answers, isEmpty);
      expect(assessmentState.currentQuestionId, isNull);
    });

    test('completeAssessment marks the session as completed', () {
      assessmentState.startAssessment(propertyId: 'P001');

      assessmentState.completeAssessment();

      expect(assessmentState.session, isNotNull);
      expect(
        assessmentState.session!.status,
        AssessmentSessionStatus.completed,
      );
      expect(assessmentState.session!.isCompleted, isTrue);
      expect(assessmentState.hasCompletedSession, isTrue);
      expect(assessmentState.hasActiveSession, isFalse);
    });

    test('clearAssessment removes the session', () {
      assessmentState.startAssessment(propertyId: 'P001');

      expect(assessmentState.session, isNotNull);

      assessmentState.clearAssessment();

      expect(assessmentState.session, isNull);
      expect(assessmentState.hasActiveSession, isFalse);
      expect(assessmentState.hasCompletedSession, isFalse);
      expect(assessmentState.currentQuestionId, isNull);
    });
  });
}
