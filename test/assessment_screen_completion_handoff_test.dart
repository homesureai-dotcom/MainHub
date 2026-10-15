import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/screens/assessment/analyzing_screen.dart';
import 'package:homesure_ai/screens/assessment/assessment_screen.dart';
import 'package:homesure_ai/screens/assessment/property_health_result_screen.dart';
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

  Future<void> pumpAssessmentScreen(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AssessmentScreen(),
      ),
    );

    await tester.pump();
    await tester.pump();
  }

  Future<void> completeAssessmentState() async {
    assessmentState.startAssessment();

    for (final question in phsQuestions) {
      assessmentState.saveAnswer(
        PHSAnswer(
          questionId: question.id,
          response: PHSResponse.yes,
        ),
        currentQuestionId: question.id,
      );
    }

    assessmentState.completeAssessment();
  }

  testWidgets(
    'assessment completion navigates through analysis to property health result',
    (tester) async {
      await completeAssessmentState();

      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyzingScreen(),
        ),
      );

      await tester.pump();

      expect(
        find.text('Analyzing your Property'),
        findsOneWidget,
      );

      expect(
        find.byType(AnalyzingScreen),
        findsOneWidget,
      );

      // AnalyzingScreen intentionally waits two seconds before
      // evaluating the assessment.
      await tester.pump(const Duration(seconds: 2));

      await tester.pump();
      await tester.pump();

      expect(
        find.byType(PropertyHealthResultScreen),
        findsOneWidget,
      );

      expect(
        find.text('PROPERTY HEALTH INDEX™'),
        findsOneWidget,
      );

      expect(
        find.text('Your Property Health Score is ready.'),
        findsOneWidget,
      );

      expect(
        find.text('Category Scores'),
        findsOneWidget,
      );

      expect(
        find.text('Risks Identified'),
        findsOneWidget,
      );

      expect(
        find.text('Recommended Actions'),
        findsOneWidget,
      );
    },
  );
}
