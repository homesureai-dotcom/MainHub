import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_assessment_progress.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/core/phs/phs_question.dart';
import 'package:homesure_ai/widgets/assessment/phs_pillar_progress.dart';

void main() {
  PHSQuestion createQuestion({
    required String id,
    required PHSCategory category,
  }) {
    return PHSQuestion(
      id: id,
      category: category,
      title: 'Test question $id',
      helpText: 'Test help text',
      weight: 1,
      requiredEvidence: const [],
      applicableTo: const [PropertyType.apartment],
    );
  }

  PHSAnswer createAnswer(String questionId) {
    return PHSAnswer(questionId: questionId, response: PHSResponse.yes);
  }

  Widget buildWidget(PHSAssessmentProgress progress) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PHSAssessmentPillarProgress(progress: progress),
        ),
      ),
    );
  }

  group('PHSAssessmentPillarProgress', () {
    testWidgets('shows all six PHS pillars', (tester) async {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
        createQuestion(
          id: 'UTILITIES_1',
          category: PHSCategory.utilitiesInfrastructure,
        ),
        createQuestion(id: 'SAFETY_1', category: PHSCategory.safetyCompliance),
        createQuestion(
          id: 'COMMUNITY_1',
          category: PHSCategory.communityMaintenance,
        ),
        createQuestion(
          id: 'DOCUMENTATION_1',
          category: PHSCategory.documentation,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: const [],
      );

      await tester.pumpWidget(buildWidget(progress));

      expect(find.text(PHSCategory.legalOwnership.displayName), findsOneWidget);

      expect(
        find.text(PHSCategory.constructionQuality.displayName),
        findsOneWidget,
      );

      expect(
        find.text(PHSCategory.utilitiesInfrastructure.displayName),
        findsOneWidget,
      );

      expect(
        find.text(PHSCategory.safetyCompliance.displayName),
        findsOneWidget,
      );

      expect(
        find.text(PHSCategory.communityMaintenance.displayName),
        findsOneWidget,
      );

      expect(find.text(PHSCategory.documentation.displayName), findsOneWidget);
    });

    testWidgets('shows overall pillar completion', (tester) async {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1'), createAnswer('LEGAL_2')],
      );

      await tester.pumpWidget(buildWidget(progress));

      expect(find.text('1 of 6 pillars complete'), findsOneWidget);

      expect(find.text('17%'), findsOneWidget);
    });

    testWidgets('marks the current category', (tester) async {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(
          id: 'CONSTRUCTION_1',
          category: PHSCategory.constructionQuality,
        ),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      await tester.pumpWidget(buildWidget(progress));

      expect(find.text('CURRENT'), findsOneWidget);

      expect(
        find.text(PHSCategory.constructionQuality.displayName),
        findsOneWidget,
      );
    });

    testWidgets('shows completed question count', (tester) async {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
        createQuestion(id: 'LEGAL_2', category: PHSCategory.legalOwnership),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      await tester.pumpWidget(buildWidget(progress));

      expect(find.text('1 of 2 questions'), findsOneWidget);
    });

    testWidgets('shows complete status for a completed pillar', (tester) async {
      final questions = [
        createQuestion(id: 'LEGAL_1', category: PHSCategory.legalOwnership),
      ];

      final progress = PHSAssessmentProgress.fromQuestions(
        questions: questions,
        answers: [createAnswer('LEGAL_1')],
      );

      await tester.pumpWidget(buildWidget(progress));

      expect(find.text('1 question complete'), findsOneWidget);
    });
  });
}
