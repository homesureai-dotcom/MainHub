import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  group('Documentation Engine Rules', () {
    late PropertyIntelligenceEngine engine;

    setUp(() {
      engine = PropertyIntelligenceEngine();
    });

    test('Property Tax - Yes should score 20 weighted points', () {
      final evaluation = engine.evaluate(
        const PHSAnswer(
          questionId: 'DOCUMENTATION_PROPERTY_TAX',
          response: PHSResponse.yes,
        ),
      );

      expect(evaluation.category, PHSCategory.documentation);
      expect(evaluation.score, 20);
      expect(evaluation.maxScore, 20);
      expect(evaluation.percentage, 100);
      expect(evaluation.hasRisk, false);
      expect(evaluation.hasRecommendation, false);
    });

    test('Property Tax - Unsure should score 10 weighted points', () {
      final evaluation = engine.evaluate(
        const PHSAnswer(
          questionId: 'DOCUMENTATION_PROPERTY_TAX',
          response: PHSResponse.unsure,
        ),
      );

      expect(evaluation.category, PHSCategory.documentation);
      expect(evaluation.score, 10);
      expect(evaluation.maxScore, 20);
      expect(evaluation.percentage, 50);
      expect(evaluation.hasRisk, true);
      expect(evaluation.hasRecommendation, true);
    });

    test('Property Tax - No should score 0 weighted points', () {
      final evaluation = engine.evaluate(
        const PHSAnswer(
          questionId: 'DOCUMENTATION_PROPERTY_TAX',
          response: PHSResponse.no,
        ),
      );

      expect(evaluation.category, PHSCategory.documentation);
      expect(evaluation.score, 0);
      expect(evaluation.maxScore, 20);
      expect(evaluation.percentage, 0);
      expect(evaluation.hasRisk, true);
      expect(evaluation.hasRecommendation, true);
    });

    test('All Documentation questions should be registered', () {
      const questionIds = [
        'DOCUMENTATION_PROPERTY_TAX',
        'DOCUMENTATION_BESCOM',
        'DOCUMENTATION_BWSSB',
        'DOCUMENTATION_WARRANTY',
        'DOCUMENTATION_MANUALS',
      ];

      for (final questionId in questionIds) {
        final evaluation = engine.evaluate(
          PHSAnswer(
            questionId: questionId,
            response: PHSResponse.yes,
          ),
        );

        expect(
          evaluation.category,
          PHSCategory.documentation,
          reason: '$questionId should belong to Documentation',
        );

        expect(
          evaluation.score,
          20,
          reason: '$questionId should earn 20 weighted points for Yes',
        );

        expect(
          evaluation.maxScore,
          20,
          reason: '$questionId should have a maximum weight of 20',
        );

        expect(
          evaluation.percentage,
          100,
          reason: '$questionId should have a 100% question percentage for Yes',
        );
      }
    });

    test('Documentation assessment with all Yes answers should score 100', () {
      const questionIds = [
        'DOCUMENTATION_PROPERTY_TAX',
        'DOCUMENTATION_BESCOM',
        'DOCUMENTATION_BWSSB',
        'DOCUMENTATION_WARRANTY',
        'DOCUMENTATION_MANUALS',
      ];

      final answers = questionIds
          .map(
            (questionId) => PHSAnswer(
              questionId: questionId,
              response: PHSResponse.yes,
            ),
          )
          .toList();

      final result = engine.evaluateAssessment(answers);

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);
      expect(result.totalCategoryCount, 6);

      expect(
        result.categoryScores[PHSCategory.documentation],
        100,
      );

      expect(result.isComplete, false);
      expect(result.hasFinalScore, false);
    });

    test('Documentation assessment with all No answers should score 0', () {
      const questionIds = [
        'DOCUMENTATION_PROPERTY_TAX',
        'DOCUMENTATION_BESCOM',
        'DOCUMENTATION_BWSSB',
        'DOCUMENTATION_WARRANTY',
        'DOCUMENTATION_MANUALS',
      ];

      final answers = questionIds
          .map(
            (questionId) => PHSAnswer(
              questionId: questionId,
              response: PHSResponse.no,
            ),
          )
          .toList();

      final result = engine.evaluateAssessment(answers);

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);

      expect(
        result.categoryScores[PHSCategory.documentation],
        0,
      );

      expect(result.isComplete, false);
      expect(result.hasFinalScore, false);
    });
  });
}