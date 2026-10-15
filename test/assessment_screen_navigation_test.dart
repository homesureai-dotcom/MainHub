import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
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
    await tester.pumpWidget(
      const MaterialApp(
        home: AssessmentScreen(),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  Future<void> answerCurrentQuestion(
    WidgetTester tester,
    String responseLabel,
  ) async {
    final finder = find.text(responseLabel);

    expect(
      finder,
      findsOneWidget,
      reason:
          'Expected answer option "$responseLabel" to be visible in the widget tree.',
    );

    await tester.ensureVisible(finder);
    await tester.pump();

    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  Finder pillarRow(PHSCategory category) {
    return find
        .ancestor(
          of: find.text(category.displayName),
          matching: find.byType(InkWell),
        )
        .first;
  }

  testWidgets(
    'opens first unanswered question when pillar is selected',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final category = PHSCategory.legalOwnership;

      final firstCategoryQuestion = phsQuestions.firstWhere(
        (question) => question.category == category,
      );

      final row = pillarRow(category);

      expect(
        row,
        findsOneWidget,
      );

      await tester.ensureVisible(row);
      await tester.pump();

      await tester.tap(row);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.currentQuestionId,
        firstCategoryQuestion.id,
      );

      expect(
        find.text(category.displayName),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'skips multiple answered questions when opening a pillar',
    (tester) async {
      final category = PHSCategory.legalOwnership;

      final categoryQuestions = phsQuestions
          .where((question) => question.category == category)
          .toList();

      expect(
        categoryQuestions.length,
        greaterThanOrEqualTo(3),
      );

      await pumpAssessmentScreen(tester);

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: categoryQuestions[0].id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: categoryQuestions[0].id,
      );

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: categoryQuestions[1].id,
          response: PHSResponse.no,
        ),
        currentQuestionId: categoryQuestions[1].id,
      );

      await tester.pump();

      final row = pillarRow(category);

      expect(
        row,
        findsOneWidget,
      );

      await tester.ensureVisible(row);
      await tester.pump();

      await tester.tap(row);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.currentQuestionId,
        categoryQuestions[2].id,
      );
    },
  );

  testWidgets(
    'completed pillar falls back to its first question',
    (tester) async {
      final category = PHSCategory.legalOwnership;

      final categoryQuestions = phsQuestions
          .where((question) => question.category == category)
          .toList();

      expect(
        categoryQuestions,
        isNotEmpty,
      );

      await pumpAssessmentScreen(tester);

      for (final question in categoryQuestions) {
        assessmentState.saveAnswer(
          PHSAnswer(
            questionId: question.id,
            response: PHSResponse.yes,
          ),
          currentQuestionId: question.id,
        );
      }

      await tester.pump();

      final row = pillarRow(category);

      expect(
        row,
        findsOneWidget,
      );

      await tester.ensureVisible(row);
      await tester.pump();

      await tester.tap(row);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.currentQuestionId,
        categoryQuestions.first.id,
      );
    },
  );

  testWidgets(
    'selecting another pillar updates current question and pillar progress',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final firstCategory = PHSCategory.legalOwnership;
      final secondCategory = PHSCategory.constructionQuality;

      final secondCategoryQuestions = phsQuestions
          .where((question) => question.category == secondCategory)
          .toList();

      expect(
        secondCategoryQuestions,
        isNotEmpty,
      );

      final firstRow = pillarRow(firstCategory);

      expect(
        firstRow,
        findsOneWidget,
      );

      await tester.ensureVisible(firstRow);
      await tester.pump();

      await tester.tap(firstRow);
      await tester.pump();
      await tester.pump();

      final firstQuestionId = assessmentState.currentQuestionId;

      expect(
        firstQuestionId,
        isNotNull,
      );

      final secondRow = pillarRow(secondCategory);

      expect(
        secondRow,
        findsOneWidget,
      );

      await tester.ensureVisible(secondRow);
      await tester.pump();

      await tester.tap(secondRow);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.currentQuestionId,
        secondCategoryQuestions.first.id,
      );

      expect(
        assessmentState.currentQuestionId,
        isNot(firstQuestionId),
      );
    },
  );

  testWidgets(
    'previous question updates persisted current question',
    (tester) async {
      expect(
        phsQuestions.length,
        greaterThanOrEqualTo(2),
      );

      final firstQuestion = phsQuestions[0];
      final secondQuestion = phsQuestions[1];

      // Create an active assessment session first.
      assessmentState.startAssessment();

      // Persist an answer for question 1 and explicitly persist
      // question 2 as the current question.
      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: firstQuestion.id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: secondQuestion.id,
      );

      expect(
        assessmentState.currentQuestionId,
        secondQuestion.id,
      );

      expect(
        assessmentState.answers,
        hasLength(1),
      );

      // Now launch the actual screen. AssessmentScreen should restore
      // the persisted question 2 position.
      await pumpAssessmentScreen(tester);

      expect(
        assessmentState.currentQuestionId,
        secondQuestion.id,
      );

      final previousButton = find.text('Previous Question');

      expect(
        previousButton,
        findsOneWidget,
      );

      await tester.ensureVisible(previousButton);
      await tester.pump();

      await tester.tap(previousButton);
      await tester.pump();
      await tester.pump();

      // Previous Question must persist question 1.
      expect(
        assessmentState.currentQuestionId,
        firstQuestion.id,
      );
    },
  );

  testWidgets(
    'pillar selection preserves answered progress',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final firstQuestion = phsQuestions.first;

      await answerCurrentQuestion(
        tester,
        'Yes',
      );

      expect(
        assessmentState.answers,
        hasLength(1),
      );

      expect(
        assessmentState.answers.first.questionId,
        firstQuestion.id,
      );

      final category = firstQuestion.category;

      final row = pillarRow(category);

      expect(
        row,
        findsOneWidget,
      );

      await tester.ensureVisible(row);
      await tester.pump();

      await tester.tap(row);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.answers,
        hasLength(1),
      );

      expect(
        assessmentState.answers.first.questionId,
        firstQuestion.id,
      );

      final categoryProgress =
          assessmentState.assessmentProgress.progressFor(category);

      expect(
        categoryProgress,
        isNotNull,
      );

      expect(
        categoryProgress!.answeredQuestions,
        greaterThanOrEqualTo(1),
      );
    },
  );
}