import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/models/property_health/score_calculator.dart';
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

    await tester.pump();
    await tester.pump();
  }

  Future<void> switchToPremiumView(WidgetTester tester) async {
    final premiumButton = find.text('Premium');

    expect(
      premiumButton,
      findsWidgets,
      reason: 'Expected the Premium view toggle to be visible.',
    );

    await tester.tap(premiumButton.first);
    await tester.pump();
    await tester.pump();
  }

  Finder pillarTapTarget(PHSCategory category) {
    return find
        .ancestor(
          of: find.text(category.displayName),
          matching: find.byType(InkWell),
        )
        .first;
  }

  testWidgets('shows Classic view by default', (tester) async {
    await pumpAssessmentScreen(tester);

    expect(find.text('Classic'), findsWidgets);

    expect(find.text('Premium'), findsWidgets);

    expect(find.text('Property Health Map'), findsNothing);

    expect(find.text('Question 1 of 33'), findsWidgets);
  });

  testWidgets('switches from Classic view to Premium view', (tester) async {
    await pumpAssessmentScreen(tester);

    await switchToPremiumView(tester);

    expect(find.text('Property Health Map'), findsOneWidget);

    expect(find.text('PROPERTY HEALTH'), findsOneWidget);

    expect(find.text('Assessment not started'), findsOneWidget);
  });

  testWidgets('Premium view shows all PHS pillars', (tester) async {
    await pumpAssessmentScreen(tester);

    await switchToPremiumView(tester);

    for (final category in PHSCategory.values) {
      expect(
        find.text(category.displayName),
        findsWidgets,
        reason: 'Expected ${category.displayName} in Premium View.',
      );
    }
  });

  testWidgets('Premium view shows unassessed pillars as not assessed', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    await switchToPremiumView(tester);

    expect(find.text('Not assessed'), findsWidgets);
  });

  testWidgets('Premium view shows an unassessed score as --', (tester) async {
    await pumpAssessmentScreen(tester);

    await switchToPremiumView(tester);

    expect(find.text('--'), findsOneWidget);

    expect(find.text('/ 100'), findsOneWidget);
  });

  testWidgets('Premium view reflects an answered question in its pillar', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions.first;

    assessmentState.saveAnswer(
      PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
      currentQuestionId: firstQuestion.id,
    );

    await tester.pump();

    await switchToPremiumView(tester);

    final category = firstQuestion.category;

    final categoryScores = ScoreCalculator().calculate(assessmentState.answers);

    final categoryScore = categoryScores.firstWhere(
      (score) => score.category == category,
    );

    expect(
      find.text(
        '${categoryScore.score.round()} · '
        '${categoryScore.score >= 90
            ? 'Excellent'
            : categoryScore.score >= 75
            ? 'Good'
            : categoryScore.score >= 60
            ? 'Needs attention'
            : categoryScore.score >= 40
            ? 'At risk'
            : 'Critical'}',
      ),
      findsOneWidget,
    );

    expect(find.textContaining('/'), findsWidgets);
  });

  testWidgets('Premium view displays the calculated overall score', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions.first;

    assessmentState.saveAnswer(
      PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
      currentQuestionId: firstQuestion.id,
    );

    await tester.pump();

    await switchToPremiumView(tester);

    final categoryScores = ScoreCalculator().calculate(assessmentState.answers);

    final overallScore = ScoreCalculator().calculateOverallScore(
      categoryScores,
    );

    expect(find.text(overallScore.round().toString()), findsWidgets);

    expect(
      find.text(
        '${ScoreCalculator().calculateAssessmentCoverage(assessmentState.answers).round()}% assessed',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'selecting a different Premium pillar opens its question inline',
    (tester) async {
      await pumpAssessmentScreen(tester);

      await switchToPremiumView(tester);

      final category = PHSCategory.constructionQuality;

      final categoryQuestion = phsQuestions.firstWhere(
        (question) => question.category == category,
      );

      final categoryTapTarget = pillarTapTarget(category);

      expect(categoryTapTarget, findsOneWidget);

      await tester.ensureVisible(categoryTapTarget);
      await tester.pump();

      await tester.tap(categoryTapTarget);
      await tester.pump();
      await tester.pump();

      expect(assessmentState.currentQuestionId, categoryQuestion.id);

      expect(find.text(categoryQuestion.title), findsOneWidget);
    },
  );

  testWidgets('Premium pillar question uses the existing answer options', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    await switchToPremiumView(tester);

    final category = PHSCategory.constructionQuality;

    final categoryTapTarget = pillarTapTarget(category);

    await tester.ensureVisible(categoryTapTarget);
    await tester.pump();

    await tester.tap(categoryTapTarget);
    await tester.pump();
    await tester.pump();

    expect(find.text('Yes'), findsOneWidget);

    expect(find.text('No'), findsOneWidget);

    expect(find.text("I'm Not Sure"), findsOneWidget);
  });

  testWidgets(
    'answering a question from Premium view updates AssessmentState',
    (tester) async {
      await pumpAssessmentScreen(tester);

      await switchToPremiumView(tester);

      final category = PHSCategory.constructionQuality;

      final categoryTapTarget = pillarTapTarget(category);

      await tester.ensureVisible(categoryTapTarget);
      await tester.pump();

      await tester.tap(categoryTapTarget);
      await tester.pump();
      await tester.pump();

      final questionId = assessmentState.currentQuestionId;

      expect(questionId, isNotNull);

      final yesOption = find.text('Yes');

      await tester.ensureVisible(yesOption);
      await tester.pump();

      await tester.tap(yesOption);
      await tester.pump();
      await tester.pump();

      expect(
        assessmentState.answers.any(
          (answer) =>
              answer.questionId == questionId &&
              answer.response == PHSResponse.yes,
        ),
        isTrue,
      );
    },
  );

  testWidgets('switching back to Classic view preserves assessment state', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions.first;

    assessmentState.saveAnswer(
      PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
      currentQuestionId: firstQuestion.id,
    );

    await tester.pump();

    await switchToPremiumView(tester);

    expect(find.text('Property Health Map'), findsOneWidget);

    final classicButtons = find.text('Classic');

    expect(classicButtons, findsWidgets);

    await tester.tap(classicButtons.first);
    await tester.pump();
    await tester.pump();

    expect(find.text('Question 1 of 33'), findsWidgets);

    expect(assessmentState.answers, hasLength(1));

    expect(assessmentState.answers.first.response, PHSResponse.yes);
  });
}
