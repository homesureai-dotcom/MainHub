
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
      const MaterialApp(home: AssessmentScreen()),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  Finder categoryDropdown() {
    return find.byKey(
      const ValueKey('assessment-category-dropdown'),
    );
  }

  Future<void> selectCategory(
    WidgetTester tester,
    PHSCategory category,
  ) async {
    final dropdown = categoryDropdown();

    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    final option = find.byKey(
      ValueKey('classic-category-option-${category.name}'),
    );

    expect(option, findsOneWidget);

    final optionText = find.descendant(
      of: option,
      matching: find.byType(Text),
    );

    expect(optionText, findsOneWidget);

    await tester.tap(optionText);
    await tester.pumpAndSettle();
  }

  Finder questionChip(String questionId) {
    return find.byKey(
      ValueKey('classic-question-$questionId'),
    );
  }

  testWidgets(
    'selecting a category does not change the active question',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final originalQuestionId = assessmentState.currentQuestionId;
      expect(originalQuestionId, isNotNull);

      const anotherCategory = PHSCategory.constructionQuality;

      expect(
        phsQuestions.any((q) => q.category == anotherCategory),
        isTrue,
      );

      await selectCategory(tester, anotherCategory);

      expect(
        assessmentState.currentQuestionId,
        originalQuestionId,
        reason: 'Selecting a category should only show its question chips.',
      );
    },
  );

  testWidgets(
    'selecting an individual question opens that exact question',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final category = PHSCategory.constructionQuality;

      final categoryQuestions = phsQuestions
          .where((q) => q.category == category)
          .toList();

      expect(categoryQuestions, isNotEmpty);

      await selectCategory(tester, category);

      final targetQuestion = categoryQuestions.last;

      await tapAndSettle(
        tester,
        questionChip(targetQuestion.id),
      );

      expect(
        assessmentState.currentQuestionId,
        targetQuestion.id,
      );
    },
  );

  testWidgets(
    'previous question updates persisted current question',
    (tester) async {
      expect(phsQuestions.length, greaterThanOrEqualTo(2));

      final firstQuestion = phsQuestions[0];
      final secondQuestion = phsQuestions[1];

      assessmentState.startAssessment();

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

      await pumpAssessmentScreen(tester);

      expect(
        assessmentState.currentQuestionId,
        secondQuestion.id,
      );

      await tapAndSettle(
        tester,
        find.text('Previous Question'),
      );

      expect(
        assessmentState.currentQuestionId,
        firstQuestion.id,
      );
    },
  );

  testWidgets(
    'category selection preserves answered progress',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final firstQuestion = phsQuestions.first;

      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: firstQuestion.id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: firstQuestion.id,
      );

      await tester.pump();

      final anotherCategory =
          firstQuestion.category == PHSCategory.constructionQuality
              ? PHSCategory.legalOwnership
              : PHSCategory.constructionQuality;

      await selectCategory(tester, anotherCategory);

      expect(
        assessmentState.currentQuestionId,
        firstQuestion.id,
        reason: 'Category selection must not change the active question.',
      );

      expect(assessmentState.answers, hasLength(1));
      expect(
        assessmentState.answers.first.questionId,
        firstQuestion.id,
      );

      final categoryProgress =
          assessmentState.assessmentProgress.progressFor(
        firstQuestion.category,
      );

      expect(categoryProgress, isNotNull);
      expect(
        categoryProgress!.answeredQuestions,
        greaterThanOrEqualTo(1),
      );
    },
  );

  testWidgets(
    'an answered question can be reopened from its question chip',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final answeredQuestion = phsQuestions.first;

      await tapAndSettle(
        tester,
        find.text('Yes'),
      );

      expect(
        assessmentState.answers.any(
          (answer) => answer.questionId == answeredQuestion.id,
        ),
        isTrue,
        reason: 'Selecting Yes should save the answer through the UI.',
      );

      final anotherCategory =
          answeredQuestion.category == PHSCategory.constructionQuality
              ? PHSCategory.legalOwnership
              : PHSCategory.constructionQuality;

      final otherCategoryQuestions = phsQuestions
          .where((question) => question.category == anotherCategory)
          .toList();

      expect(otherCategoryQuestions, isNotEmpty);

      await selectCategory(tester, anotherCategory);

      final otherQuestion = otherCategoryQuestions.first;

      await tapAndSettle(
        tester,
        questionChip(otherQuestion.id),
      );

      expect(
        assessmentState.currentQuestionId,
        otherQuestion.id,
      );

      await selectCategory(tester, answeredQuestion.category);

      await tapAndSettle(
        tester,
        questionChip(answeredQuestion.id),
      );

      expect(
        assessmentState.currentQuestionId,
        answeredQuestion.id,
        reason: 'An answered question should remain accessible for review.',
      );

      expect(assessmentState.answers, hasLength(1));
      expect(
        assessmentState.answers.first.questionId,
        answeredQuestion.id,
      );
      expect(
        assessmentState.answers.first.response,
        PHSResponse.yes,
      );
    },
  );

  testWidgets(
    'switching categories and returning preserves answered status',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final answeredQuestion = phsQuestions.first;

      // Save the answer through the actual UI so the screen rebuilds
      // using the updated assessment state.
      await tapAndSettle(
        tester,
        find.text('Yes'),
      );

      expect(
        assessmentState.answers.any(
          (answer) => answer.questionId == answeredQuestion.id,
        ),
        isTrue,
        reason: 'Selecting Yes should save the answer through the UI.',
      );

      final anotherCategory =
          answeredQuestion.category == PHSCategory.constructionQuality
              ? PHSCategory.legalOwnership
              : PHSCategory.constructionQuality;

      await selectCategory(tester, anotherCategory);

      expect(
        assessmentState.answers.any(
          (answer) => answer.questionId == answeredQuestion.id,
        ),
        isTrue,
      );

      await selectCategory(tester, answeredQuestion.category);

      final answeredChip = questionChip(answeredQuestion.id);

      expect(answeredChip, findsOneWidget);

      expect(
        find.descendant(
          of: answeredChip,
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
        reason: 'The answered question should display its completed indicator.',
      );

      final categoryProgress =
          assessmentState.assessmentProgress.progressFor(
        answeredQuestion.category,
      );

      expect(categoryProgress, isNotNull);
      expect(
        categoryProgress!.answeredQuestions,
        greaterThanOrEqualTo(1),
      );
      expect(assessmentState.answers, hasLength(1));
    },
  );
}
