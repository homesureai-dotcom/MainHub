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

  Finder pillarCard(PHSCategory category) {
    return find.byKey(
      ValueKey<String>('assessment-pillar-${category.name}'),
    );
  }

  Finder activePillarTitle(PHSCategory category) {
    return find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.key == const ValueKey<String>('active-pillar-title') &&
          w.data == category.displayName,
    );
  }

  testWidgets(
    'displays Assessment pillars strip, active pillar card, and all questions stacked for scrolling without Classic/Premium toggle',
    (tester) async {
      await pumpAssessmentScreen(tester);

      expect(find.text('Classic'), findsNothing);
      expect(find.text('Premium'), findsNothing);
      expect(find.text('Assessment pillars'), findsOneWidget);
      expect(find.text('ACTIVE ASSESSMENT PILLAR'), findsOneWidget);
      expect(activePillarTitle(PHSCategory.legalOwnership), findsOneWidget);

      final legalQuestions = phsQuestions
          .where((q) => q.category == PHSCategory.legalOwnership)
          .toList();
      for (var i = 0; i < legalQuestions.length; i++) {
        expect(
          find.byKey(
            ValueKey<String>('assessment-qcard-${legalQuestions[i].id}'),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('QUESTION ${i + 1} OF ${legalQuestions.length}'),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'tapping a pillar switches active pillar and renders all questions for that pillar',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final targetCategory = PHSCategory.constructionQuality;
      final targetQuestions = phsQuestions
          .where((q) => q.category == targetCategory)
          .toList();

      await tester.ensureVisible(pillarCard(targetCategory));
      await tester.tap(pillarCard(targetCategory));
      await tester.pumpAndSettle();

      expect(activePillarTitle(targetCategory), findsOneWidget);

      for (var i = 0; i < targetQuestions.length; i++) {
        expect(
          find.byKey(
            ValueKey<String>('assessment-qcard-${targetQuestions[i].id}'),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'switching pillars and returning preserves answered answers and progress',
    (tester) async {
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

      expect(
        assessmentState.answers.any(
          (a) =>
              a.questionId == firstQuestion.id && a.response == PHSResponse.yes,
        ),
        isTrue,
      );

      await tester.ensureVisible(pillarCard(PHSCategory.constructionQuality));
      await tester.tap(pillarCard(PHSCategory.constructionQuality));
      await tester.pumpAndSettle();

      expect(activePillarTitle(PHSCategory.constructionQuality), findsOneWidget);

      await tester.ensureVisible(pillarCard(PHSCategory.legalOwnership));
      await tester.tap(pillarCard(PHSCategory.legalOwnership));
      await tester.pumpAndSettle();

      final legalCount = phsQuestions
          .where((q) => q.category == PHSCategory.legalOwnership)
          .length;
      expect(find.textContaining('1 of $legalCount answered'), findsOneWidget);
      expect(
        find.byKey(ValueKey<String>('assessment-qcard-${firstQuestion.id}')),
        findsOneWidget,
      );
      expect(assessmentState.answers, hasLength(1));
    },
  );

  testWidgets(
    'Next pillar button advances through pillars in sequence',
    (tester) async {
      await pumpAssessmentScreen(tester);

      final nextButton = find.byKey(
        const ValueKey<String>('assessment-next-pillar-btn'),
      );
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(activePillarTitle(PHSCategory.values[1]), findsOneWidget);
    },
  );
}
