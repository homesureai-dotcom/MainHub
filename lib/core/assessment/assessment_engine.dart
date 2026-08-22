import '../phs/phs_answer.dart';
import '../phs/phs_categories.dart';
import '../phs/phs_question.dart';

import 'assessment_result.dart';
import 'category_result.dart';

class AssessmentEngine {
  const AssessmentEngine();

  AssessmentResult evaluate({
    required List<PHSQuestion> questions,
    required List<PHSAnswer> answers,
  }) {
    // Track earned and maximum score for each category
    final Map<PHSCategory, double> earnedScores = {};
    final Map<PHSCategory, double> maximumScores = {};

    // Initialize every category
    for (final category in PHSCategory.values) {
      earnedScores[category] = 0;
      maximumScores[category] = 0;
    }

    // Evaluate every question
    for (final question in questions) {
      // Find the user's answer
      final answer = answers.where(
        (a) => a.questionId == question.id,
      );

      final response =
          answer.isEmpty ? PHSResponse.unsure : answer.first.response;

      // Add maximum possible score
      maximumScores[question.category] =
          maximumScores[question.category]! + question.weight;

      // Add earned score
      earnedScores[question.category] =
          earnedScores[question.category]! +
              (question.weight * response.value);
    }

    // Build category results
    final List<CategoryResult> categoryResults = [];

    double overallScore = 0;

    for (final category in PHSCategory.values) {
      final result = CategoryResult(
        category: category,
        earnedScore: earnedScores[category]!,
        maximumScore: maximumScores[category]!,
        weight: category.weight,
      );

      categoryResults.add(result);

      overallScore += result.weightedContribution;
    }

    // Round score
    overallScore = overallScore.clamp(0, 100);

    // Determine grade and summary
    String grade;
    String summary;

    if (overallScore >= 90) {
      grade = "Excellent";
      summary =
          "Your property is in excellent health with very few compliance risks.";
    } else if (overallScore >= 75) {
      grade = "Good";
      summary =
          "Your property is generally healthy with a few improvements recommended.";
    } else if (overallScore >= 60) {
      grade = "Fair";
      summary =
          "Your property has moderate compliance gaps that should be addressed.";
    } else {
      grade = "Needs Attention";
      summary =
          "Your property has significant compliance risks requiring immediate attention.";
    }

    return AssessmentResult(
      overallScore: overallScore,
      grade: grade,
      summary: summary,
      categoryResults: categoryResults,
      recommendations: const [],
    );
  }
}