import '../../core/phs/phs_answer.dart';
import '../../core/phs/phs_categories.dart';
import '../../data/phs_questions.dart';
import '../../models/property_health/category_score.dart';

/// Calculates Property Health scores from assessment answers.
///
/// Responsible ONLY for score calculation.
/// It does not generate risks or recommendations.
class ScoreCalculator {
  /// Calculates the score for each Property Health category.
  List<CategoryScore> calculate(
    List<PHSAnswer> answers,
  ) {
    final Map<PHSCategory, double> earnedScore = {};
    final Map<PHSCategory, double> totalScore = {};

    final Map<PHSCategory, int> totalQuestions = {};
    final Map<PHSCategory, int> passedQuestions = {};

    for (final question in phsQuestions) {
      // Count total questions
      totalQuestions.update(
        question.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final matchingAnswers = answers.where(
        (a) => a.questionId == question.id,
      );

      if (matchingAnswers.isEmpty) {
        continue;
      }

      final response = matchingAnswers.first.response;

      double earned = 0;

      switch (response) {
        case PHSResponse.yes:
          earned = question.weight.toDouble();

          passedQuestions.update(
            question.category,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          break;

        case PHSResponse.unsure:
          earned = question.weight * 0.5;
          break;

        case PHSResponse.no:
          earned = 0;
          break;
      }

      earnedScore.update(
        question.category,
        (value) => value + earned,
        ifAbsent: () => earned,
      );

      totalScore.update(
        question.category,
        (value) => value + question.weight.toDouble(),
        ifAbsent: () => question.weight.toDouble(),
      );
    }

    final List<CategoryScore> results = [];

    for (final category in PHSCategory.values) {
      final earned = earnedScore[category] ?? 0.0;
      final max = totalScore[category] ?? 0.0;

      final double percentage =
          max == 0 ? 0.0 : (earned / max) * 100.0;

      results.add(
        CategoryScore(
          category: category,
          score: percentage,
          maxScore: max,
          totalQuestions: totalQuestions[category] ?? 0,
          passedQuestions: passedQuestions[category] ?? 0,
        ),
      );
    }

    return results;
  }

  /// Calculates the overall Property Health Index.
  double calculateOverallScore(
    List<CategoryScore> categoryScores,
  ) {
    if (categoryScores.isEmpty) {
      return 0;
    }

    final total = categoryScores.fold<double>(
      0,
      (sum, item) => sum + item.score,
    );

    return total / categoryScores.length;
  }
}