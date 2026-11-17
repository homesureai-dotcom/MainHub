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
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('omits legacy Classic/Premium view toggle', (tester) async {
    await pumpAssessmentScreen(tester);

    expect(find.text('Classic'), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('shows horizontal Assessment pillars strip with progress counters', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    expect(find.text('Assessment pillars'), findsOneWidget);
    expect(find.text('Swipe right to explore →'), findsOneWidget);

    for (final category in [
      PHSCategory.legalOwnership,
      PHSCategory.constructionQuality,
    ]) {
      expect(
        find.byKey(ValueKey<String>('assessment-pillar-${category.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('updates overall live PHI banner and top-right pill dynamically', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final firstQuestion = phsQuestions.first;
    final firstCard = find.byKey(
      ValueKey<String>('assessment-qcard-${firstQuestion.id}'),
    );
    final yesOption = find.descendant(
      of: firstCard,
      matching: find.text('Yes'),
    );

    await tester.ensureVisible(yesOption);
    await tester.tap(yesOption);
    await tester.pumpAndSettle();

    final categoryScores = ScoreCalculator().calculate(assessmentState.answers);
    final overallScore =
        ScoreCalculator().calculateOverallScore(categoryScores).round();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('assessment-phi-top-right')),
        matching: find.text('$overallScore out of 100'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('answering questions across multiple pillars preserves answers', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final legalQ = phsQuestions.firstWhere(
      (q) => q.category == PHSCategory.legalOwnership,
    );
    final legalCard = find.byKey(
      ValueKey<String>('assessment-qcard-${legalQ.id}'),
    );
    await tester.ensureVisible(
      find.descendant(of: legalCard, matching: find.text('No')),
    );
    await tester.tap(find.descendant(of: legalCard, matching: find.text('No')));
    await tester.pumpAndSettle();

    final constructionPillar = find.byKey(
      const ValueKey<String>('assessment-pillar-constructionQuality'),
    );
    await tester.ensureVisible(constructionPillar);
    await tester.tap(constructionPillar);
    await tester.pumpAndSettle();

    final conQ = phsQuestions.firstWhere(
      (q) => q.category == PHSCategory.constructionQuality,
    );
    final conCard = find.byKey(
      ValueKey<String>('assessment-qcard-${conQ.id}'),
    );
    await tester.ensureVisible(
      find.descendant(of: conCard, matching: find.text('Yes')),
    );
    await tester.tap(find.descendant(of: conCard, matching: find.text('Yes')));
    await tester.pumpAndSettle();

    expect(assessmentState.answers, hasLength(2));
    expect(
      assessmentState.answers.any(
        (a) => a.questionId == legalQ.id && a.response == PHSResponse.no,
      ),
      isTrue,
    );
    expect(
      assessmentState.answers.any(
        (a) => a.questionId == conQ.id && a.response == PHSResponse.yes,
      ),
      isTrue,
    );
  });
}
