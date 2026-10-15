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
  ///
  /// Question scoring:
  /// - Yes = 100% of question weight
  /// - Unsure = 50% of question weight
  /// - No = 0% of question weight
  ///
  /// A category is scored using the questions that have actually
  /// been answered. Unanswered questions do not reduce the score.
  List<CategoryScore> calculate(List<PHSAnswer> answers) {
    final Map<PHSCategory, double> earnedScore = {};
    final Map<PHSCategory, double> answeredScore = {};

    final Map<PHSCategory, int> totalQuestions = {};
    final Map<PHSCategory, int> answeredQuestions = {};
    final Map<PHSCategory, int> passedQuestions = {};

    for (final question in phsQuestions) {
      totalQuestions.update(
        question.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final matchingAnswers = answers.where(
        (answer) => answer.questionId == question.id,
      );

      if (matchingAnswers.isEmpty) {
        continue;
      }

      final response = matchingAnswers.first.response;
      final questionWeight = question.weight.toDouble();

      final earned = questionWeight * response.value;

      earnedScore.update(
        question.category,
        (value) => value + earned,
        ifAbsent: () => earned,
      );

      answeredScore.update(
        question.category,
        (value) => value + questionWeight,
        ifAbsent: () => questionWeight,
      );

      answeredQuestions.update(
        question.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      if (response == PHSResponse.yes) {
        passedQuestions.update(
          question.category,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final List<CategoryScore> results = [];

    for (final category in PHSCategory.values) {
      final earned = earnedScore[category] ?? 0.0;
      final answeredWeight = answeredScore[category] ?? 0.0;

      final double percentage = answeredWeight == 0
          ? 0.0
          : (earned / answeredWeight) * 100.0;

      results.add(
        CategoryScore(
          category: category,
          score: percentage,
          maxScore: answeredWeight,
          totalQuestions: totalQuestions[category] ?? 0,
          passedQuestions: passedQuestions[category] ?? 0,
        ),
      );
    }

    return results;
  }

  /// Calculates the overall Property Health Score.
  ///
  /// Category scores are weighted using the configured PHS category
  /// weights rather than treating every category equally.
  ///
  /// Categories with no answered questions are excluded from the
  /// calculation and the remaining category weights are normalized.
  double calculateOverallScore(List<CategoryScore> categoryScores) {
    if (categoryScores.isEmpty) {
      return 0.0;
    }

    double weightedScore = 0.0;
    double assessedWeight = 0.0;

    for (final categoryScore in categoryScores) {
      if (categoryScore.maxScore <= 0) {
        continue;
      }

      final categoryWeight = categoryScore.category.weight;

      weightedScore += categoryScore.score * categoryWeight;
      assessedWeight += categoryWeight;
    }

    if (assessedWeight == 0.0) {
      return 0.0;
    }

    return weightedScore / assessedWeight;
  }

  /// Returns the percentage of questions that have been answered.
  ///
  /// This is deliberately separate from the health score so that an
  /// incomplete assessment is not confused with a poor property score.
  double calculateAssessmentCoverage(List<PHSAnswer> answers) {
    if (phsQuestions.isEmpty) {
      return 0.0;
    }

    final questionIds = phsQuestions.map((question) => question.id).toSet();

    final answeredQuestionIds = answers
        .where((answer) => questionIds.contains(answer.questionId))
        .map((answer) => answer.questionId)
        .toSet();

    return (answeredQuestionIds.length / phsQuestions.length) * 100.0;
  }
}
