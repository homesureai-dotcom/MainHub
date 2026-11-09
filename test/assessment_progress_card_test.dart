import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/widgets/dashboard/assessment_progress_card.dart';

void main() {
  Widget buildTestWidget({
    int completedQuestions = 18,
    int totalQuestions = 33,
    double completionPercentage = 54.545,
    int completedCategories = 5,
    int totalCategories = 6,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AssessmentProgressCard(
          completedQuestions: completedQuestions,
          totalQuestions: totalQuestions,
          completionPercentage: completionPercentage,
          completedCategories: completedCategories,
          totalCategories: totalCategories,
        ),
      ),
    );
  }

  group('AssessmentProgressCard', () {
    testWidgets(
      'shows assessment progress when assessment has started',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('Assessment Progress'),
          findsOneWidget,
        );
        expect(find.text('18'), findsOneWidget);
        expect(find.text('of 33 questions completed'), findsOneWidget);
        expect(find.text('55%'), findsOneWidget);
        expect(
          find.text('5 of 6 categories started'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows not started state when there are no completed questions',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            completedQuestions: 0,
            totalQuestions: 33,
            completionPercentage: 0,
            completedCategories: 0,
            totalCategories: 6,
          ),
        );

        expect(
          find.text(
            'Your property health assessment has not started yet.',
          ),
          findsOneWidget,
        );

        expect(
          find.text('of 33 questions'),
          findsNothing,
        );

        expect(
          find.text('0%'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows complete assessment progress correctly',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            completedQuestions: 33,
            totalQuestions: 33,
            completionPercentage: 100,
            completedCategories: 6,
            totalCategories: 6,
          ),
        );

        expect(find.text('33'), findsOneWidget);
        expect(
          find.text('of 33 questions completed'),
          findsOneWidget,
        );
        expect(find.text('100%'), findsOneWidget);
        expect(
          find.text('6 of 6 categories started'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders the progress indicator',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            completedQuestions: 10,
            totalQuestions: 33,
            completionPercentage: 30.303,
          ),
        );

        expect(
          find.byType(LinearProgressIndicator),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not expose a property health score',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(find.text('82'), findsNothing);
        expect(find.text('Excellent'), findsNothing);
        expect(find.text('Good'), findsNothing);
        expect(find.text('Fair'), findsNothing);
      },
    );
  });
}