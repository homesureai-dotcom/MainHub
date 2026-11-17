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
    await tester.pumpWidget(const MaterialApp(home: AssessmentScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Finder activePillarTitle(PHSCategory category) {
    return find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.key == const ValueKey<String>('active-pillar-title') &&
          w.data == category.displayName,
    );
  }

  testWidgets('scrolling brings later questions of the active pillar into view', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final legalQuestions = phsQuestions
        .where((q) => q.category == PHSCategory.legalOwnership)
        .toList();
    expect(legalQuestions.length, greaterThanOrEqualTo(2));

    final lastLegalQCard = find.byKey(
      ValueKey<String>('assessment-qcard-${legalQuestions.last.id}'),
    );
    await tester.ensureVisible(lastLegalQCard);
    await tester.pumpAndSettle();

    expect(lastLegalQCard, findsOneWidget);
    expect(
      find.descendant(
        of: lastLegalQCard,
        matching: find.text("I'm Not Sure"),
      ),
      findsOneWidget,
    );
  });

  testWidgets('scrolling horizontally on pillars strip exposes remaining pillars', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final scrollablePillarStrip = find.byKey(
      const ValueKey<String>('assessment-pillars-strip'),
    );
    expect(scrollablePillarStrip, findsOneWidget);

    await tester.drag(scrollablePillarStrip, const Offset(-450, 0));
    await tester.pumpAndSettle();

    final safetyPillar = find.byKey(
      const ValueKey<String>('assessment-pillar-safetyCompliance'),
    );
    expect(safetyPillar, findsOneWidget);
    await tester.tap(safetyPillar);
    await tester.pumpAndSettle();

    expect(activePillarTitle(PHSCategory.safetyCompliance), findsOneWidget);
  });

  testWidgets('answering stacked questions preserves responses while switching pillars', (
    tester,
  ) async {
    await pumpAssessmentScreen(tester);

    final legalQuestions = phsQuestions
        .where((q) => q.category == PHSCategory.legalOwnership)
        .toList();
    final firstCard = find.byKey(
      ValueKey<String>('assessment-qcard-${legalQuestions[0].id}'),
    );
    final secondCard = find.byKey(
      ValueKey<String>('assessment-qcard-${legalQuestions[1].id}'),
    );

    final firstYes = find.descendant(of: firstCard, matching: find.text('Yes'));
    await tester.ensureVisible(firstYes);
    await tester.tap(firstYes);
    await tester.pumpAndSettle();

    final secondNo = find.descendant(of: secondCard, matching: find.text('No'));
    await tester.ensureVisible(secondNo);
    await tester.tap(secondNo);
    await tester.pumpAndSettle();

    expect(assessmentState.answers, hasLength(2));
    expect(assessmentState.answers[0].response, PHSResponse.yes);
    expect(assessmentState.answers[1].response, PHSResponse.no);

    final nextPillarBtn = find.byKey(
      const ValueKey<String>('assessment-next-pillar-btn'),
    );
    await tester.ensureVisible(nextPillarBtn);
    await tester.tap(nextPillarBtn);
    await tester.pumpAndSettle();

    expect(assessmentState.answers, hasLength(2));
    expect(activePillarTitle(PHSCategory.constructionQuality), findsOneWidget);
  });
}
