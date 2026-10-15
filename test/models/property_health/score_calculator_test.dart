import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/models/property_health/category_score.dart';
import 'package:homesure_ai/models/property_health/score_calculator.dart';

void main() {
  late ScoreCalculator calculator;

  setUp(() {
    calculator = ScoreCalculator();
  });

  group('ScoreCalculator', () {
    test('returns 100 for every category when all answers are Yes', () {
      final answers = phsQuestions
          .map(
            (question) =>
                PHSAnswer(questionId: question.id, response: PHSResponse.yes),
          )
          .toList();

      final scores = calculator.calculate(answers);

      expect(scores, hasLength(PHSCategory.values.length));

      for (final score in scores) {
        expect(score.score, closeTo(100.0, 0.001));
        expect(score.maxScore, greaterThan(0));
        expect(score.totalQuestions, greaterThan(0));
      }
    });

    test('returns 0 for every category when all answers are No', () {
      final answers = phsQuestions
          .map(
            (question) =>
                PHSAnswer(questionId: question.id, response: PHSResponse.no),
          )
          .toList();

      final scores = calculator.calculate(answers);

      for (final score in scores) {
        expect(score.score, closeTo(0.0, 0.001));
      }
    });

    test('returns 50 for every category when all answers are Unsure', () {
      final answers = phsQuestions
          .map(
            (question) => PHSAnswer(
              questionId: question.id,
              response: PHSResponse.unsure,
            ),
          )
          .toList();

      final scores = calculator.calculate(answers);

      for (final score in scores) {
        expect(score.score, closeTo(50.0, 0.001));
      }
    });

    test(
      'does not penalize unanswered questions inside an assessed category',
      () {
        final legalQuestions = phsQuestions
            .where(
              (question) => question.category == PHSCategory.legalOwnership,
            )
            .toList();

        expect(legalQuestions, isNotEmpty);

        final firstQuestion = legalQuestions.first;

        final answers = [
          PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
        ];

        final scores = calculator.calculate(answers);

        final legalScore = scores.firstWhere(
          (score) => score.category == PHSCategory.legalOwnership,
        );

        expect(legalScore.score, closeTo(100.0, 0.001));
        expect(
          legalScore.maxScore,
          closeTo(firstQuestion.weight.toDouble(), 0.001),
        );
        expect(legalScore.totalQuestions, legalQuestions.length);
      },
    );

    test('leaves completely unassessed categories with zero max score', () {
      final legalQuestion = phsQuestions.firstWhere(
        (question) => question.category == PHSCategory.legalOwnership,
      );

      final answers = [
        PHSAnswer(questionId: legalQuestion.id, response: PHSResponse.yes),
      ];

      final scores = calculator.calculate(answers);

      final constructionScore = scores.firstWhere(
        (score) => score.category == PHSCategory.constructionQuality,
      );

      expect(constructionScore.score, 0.0);
      expect(constructionScore.maxScore, 0.0);
      expect(constructionScore.passedQuestions, 0);
      expect(constructionScore.totalQuestions, greaterThan(0));
    });

    test('uses question weights when calculating a category score', () {
      final legalQuestions = phsQuestions
          .where((question) => question.category == PHSCategory.legalOwnership)
          .toList();

      expect(legalQuestions.length, greaterThanOrEqualTo(2));

      final firstQuestion = legalQuestions[0];
      final secondQuestion = legalQuestions[1];

      final answers = [
        PHSAnswer(questionId: firstQuestion.id, response: PHSResponse.yes),
        PHSAnswer(questionId: secondQuestion.id, response: PHSResponse.no),
      ];

      final scores = calculator.calculate(answers);

      final legalScore = scores.firstWhere(
        (score) => score.category == PHSCategory.legalOwnership,
      );

      final expectedScore =
          firstQuestion.weight /
          (firstQuestion.weight + secondQuestion.weight) *
          100.0;

      expect(legalScore.score, closeTo(expectedScore, 0.001));
    });

    test('uses configured category weights for the overall score', () {
      final categoryScores = [
        const CategoryScore(
          category: PHSCategory.legalOwnership,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.constructionQuality,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.utilitiesInfrastructure,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.safetyCompliance,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.communityMaintenance,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.documentation,
          score: 100.0,
          maxScore: 1.0,
        ),
      ];

      final overall = calculator.calculateOverallScore(categoryScores);

      expect(overall, closeTo(100.0, 0.001));
    });

    test('normalizes overall score when only one category is assessed', () {
      final categoryScores = [
        const CategoryScore(
          category: PHSCategory.legalOwnership,
          score: 80.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.constructionQuality,
          score: 0.0,
          maxScore: 0.0,
        ),
        const CategoryScore(
          category: PHSCategory.utilitiesInfrastructure,
          score: 0.0,
          maxScore: 0.0,
        ),
        const CategoryScore(
          category: PHSCategory.safetyCompliance,
          score: 0.0,
          maxScore: 0.0,
        ),
        const CategoryScore(
          category: PHSCategory.communityMaintenance,
          score: 0.0,
          maxScore: 0.0,
        ),
        const CategoryScore(
          category: PHSCategory.documentation,
          score: 0.0,
          maxScore: 0.0,
        ),
      ];

      final overall = calculator.calculateOverallScore(categoryScores);

      expect(overall, closeTo(80.0, 0.001));
    });

    test('calculates a weighted overall score correctly', () {
      final categoryScores = [
        const CategoryScore(
          category: PHSCategory.legalOwnership,
          score: 100.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.constructionQuality,
          score: 80.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.utilitiesInfrastructure,
          score: 60.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.safetyCompliance,
          score: 40.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.communityMaintenance,
          score: 20.0,
          maxScore: 1.0,
        ),
        const CategoryScore(
          category: PHSCategory.documentation,
          score: 0.0,
          maxScore: 1.0,
        ),
      ];

      final overall = calculator.calculateOverallScore(categoryScores);

      final expected =
          (100.0 * 25.0 +
              80.0 * 25.0 +
              60.0 * 15.0 +
              40.0 * 15.0 +
              20.0 * 10.0 +
              0.0 * 10.0) /
          100.0;

      expect(overall, closeTo(expected, 0.001));
    });

    test('calculates assessment coverage correctly', () {
      final answers = phsQuestions
          .take(5)
          .map(
            (question) =>
                PHSAnswer(questionId: question.id, response: PHSResponse.yes),
          )
          .toList();

      final coverage = calculator.calculateAssessmentCoverage(answers);

      final expectedCoverage = 5 / phsQuestions.length * 100.0;

      expect(coverage, closeTo(expectedCoverage, 0.001));
    });

    test('returns zero coverage when there are no answers', () {
      expect(calculator.calculateAssessmentCoverage([]), 0.0);
    });

    test(
      'ignores answers for unknown question ids when calculating coverage',
      () {
        final coverage = calculator.calculateAssessmentCoverage([
          const PHSAnswer(
            questionId: 'UNKNOWN_QUESTION',
            response: PHSResponse.yes,
          ),
        ]);

        expect(coverage, 0.0);
      },
    );

    test('configured PHS category weights total 100 percent', () {
      final totalWeight = PHSCategory.values.fold<double>(
        0.0,
        (sum, category) => sum + category.weight,
      );

      expect(totalWeight, closeTo(100.0, 0.001));
    });
  });
}
