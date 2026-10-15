import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/core/phs/phs_question_progress.dart';
import 'package:homesure_ai/widgets/assessment/current_question_progress.dart';

void main() {
  const question = PHSQuestion(
    id: 'CONSTRUCTION_QUALITY_04',
    category: PHSCategory.constructionQuality,
    title: 'Is the property free from significant structural concerns?',
    helpText: 'Check available structural documentation.',
    weight: 10,
    requiredEvidence: [],
    applicableTo: [PropertyType.apartment],
  );

  const progress = PHSQuestionProgress(
    question: question,
    questionIndex: 13,
    totalQuestions: 33,
    categoryQuestionIndex: 3,
    categoryQuestionCount: 8,
    categoryAnsweredQuestionCount: 3,
  );

  Widget buildWidget() {
    return const MaterialApp(
      home: Scaffold(body: CurrentQuestionProgress(progress: progress)),
    );
  }

  group('CurrentQuestionProgress', () {
    testWidgets('shows overall assessment position', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Assessment Progress'), findsOneWidget);

      expect(find.text('Question 14 of 33'), findsOneWidget);
    });

    testWidgets('shows current PHS pillar', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Construction Quality'), findsOneWidget);
    });

    testWidgets('shows current position within the pillar', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('4 of 8 questions'), findsOneWidget);
    });

    testWidgets('shows actual answered progress', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('3 of 8 answered'), findsOneWidget);
    });

    testWidgets('shows actual pillar completion percentage', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('38%'), findsOneWidget);
    });

    testWidgets('renders two progress indicators', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('renders current pillar icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('renders assessment progress before pillar progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      final assessmentProgress = tester.getTopLeft(
        find.text('Assessment Progress'),
      );

      final pillarTitle = tester.getTopLeft(find.text('Construction Quality'));

      expect(assessmentProgress.dy, lessThan(pillarTitle.dy));
    });
  });
}
