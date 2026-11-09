import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_category_progress.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/widgets/assessment/classic_category_accordion.dart';

void main() {
  const question = PHSQuestion(
    id: 'LEGAL_OC',
    category: PHSCategory.legalOwnership,
    title: 'Is the occupancy certificate available?',
    helpText: 'Check the occupancy certificate.',
    weight: 1,
    requiredEvidence: [],
    applicableTo: [PropertyType.apartment],
  );

  testWidgets('displays the category dropdown and its question', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassicCategoryAccordion(
              questions: const [question],
              progressFor: (category) => PHSCategoryProgress(
                category: category,
                totalQuestions: category == PHSCategory.legalOwnership ? 1 : 0,
                answeredQuestions: 0,
              ),
              isAnswered: (_) => false,
              currentQuestionId: question.id,
              onQuestionSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Assessment category'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assessment-category-dropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('classic-question-LEGAL_OC')),
      findsOneWidget,
    );
    expect(find.text('Q1'), findsOneWidget);
    expect(
      find.text('Is the occupancy certificate available?'),
      findsOneWidget,
    );
    expect(find.text('0% complete'), findsOneWidget);
  });

  testWidgets('selecting a question chip invokes its callback', (
    tester,
  ) async {
    PHSQuestion? selectedQuestion;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassicCategoryAccordion(
              questions: const [question],
              progressFor: (category) => PHSCategoryProgress(
                category: category,
                totalQuestions: category == PHSCategory.legalOwnership ? 1 : 0,
                answeredQuestions: 0,
              ),
              isAnswered: (_) => false,
              currentQuestionId: question.id,
              onQuestionSelected: (selected) {
                selectedQuestion = selected;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(
      const ValueKey('classic-question-LEGAL_OC'),
    ));
    await tester.pumpAndSettle();

    expect(selectedQuestion?.id, 'LEGAL_OC');
  });
}
