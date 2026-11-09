import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/screens/assessment/assessment_screen.dart';
import 'package:homesure_ai/state/assessment_state.dart';

void main() {
  final assessmentState = AssessmentState.instance;

  setUp(() {
    assessmentState.clearAssessment();
  });

  tearDown(() {
    assessmentState.clearAssessment();
  });

  Future<void> pumpAssessmentScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AssessmentScreen()));

    // Allow assessment restoration and initial question selection to finish.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Finder questionCarousel() {
    return find.byKey(
      const PageStorageKey<String>('assessment-question-carousel'),
    );
  }

  Future<void> swipeCarousel(
    WidgetTester tester, {
    required double horizontalDistance,
  }) async {
    final carousel = questionCarousel();

    expect(carousel, findsOneWidget);

    final rect = tester.getRect(carousel);

    expect(
      rect.width,
      greaterThan(100),
      reason: 'The question carousel must have a usable horizontal swipe area.',
    );

    expect(
      rect.height,
      greaterThan(100),
      reason: 'The question carousel must have a usable vertical area.',
    );

    await tester.fling(carousel, Offset(horizontalDistance, 0), 1200);

    await tester.pumpAndSettle();
  }

  testWidgets('swiping left advances to the next question', (tester) async {
    expect(phsQuestions.length, greaterThanOrEqualTo(2));

    await pumpAssessmentScreen(tester);

    final secondQuestion = phsQuestions[1];

    expect(assessmentState.currentQuestionId, phsQuestions[0].id);

    await swipeCarousel(tester, horizontalDistance: -400);

    expect(assessmentState.currentQuestionId, secondQuestion.id);
  });

  testWidgets('swiping right returns to the previous question', (tester) async {
    expect(phsQuestions.length, greaterThanOrEqualTo(2));

    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions[0];
    final secondQuestion = phsQuestions[1];

    final nextButton = find.text('Next Question');

    expect(nextButton, findsOneWidget);

    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(assessmentState.currentQuestionId, secondQuestion.id);

    await swipeCarousel(tester, horizontalDistance: 400);

    expect(assessmentState.currentQuestionId, firstQuestion.id);
  });

  testWidgets('swiping preserves previously saved answers', (tester) async {
    expect(phsQuestions.length, greaterThanOrEqualTo(2));

    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions[0];
    final secondQuestion = phsQuestions[1];

    final yesOption = find.text('Yes');

    expect(yesOption, findsOneWidget);

    await tester.ensureVisible(yesOption);
    await tester.tap(yesOption);
    await tester.pumpAndSettle();

    expect(assessmentState.answers, hasLength(1));

    expect(assessmentState.answers.first.questionId, firstQuestion.id);

    await swipeCarousel(tester, horizontalDistance: -400);

    expect(assessmentState.currentQuestionId, secondQuestion.id);

    expect(assessmentState.answers, hasLength(1));

    expect(assessmentState.answers.first.questionId, firstQuestion.id);
  });
}
