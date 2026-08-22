import '../../data/assessment_questions.dart';
import '../../models/assessment_answer.dart';

class AssessmentEvaluationResult {
  final int legalScore;
  final int utilityScore;
  final int safetyScore;
  final int builderScore;

  const AssessmentEvaluationResult({
    required this.legalScore,
    required this.utilityScore,
    required this.safetyScore,
    required this.builderScore,
  });
}

class AssessmentEvaluator {
  const AssessmentEvaluator();

  AssessmentEvaluationResult evaluate(
    List<AssessmentAnswer> answers,
  ) {
    int legal = 0;
    int utility = 0;
    int safety = 0;
    int builder = 0;

    for (final answer in answers) {
      final question = assessmentQuestions.firstWhere(
        (q) => q.id == answer.questionId,
      );

      int score = 0;

      switch (answer.response) {
        case AssessmentResponse.yes:
          score = question.yesScore;
          break;

        case AssessmentResponse.no:
          score = question.noScore;
          break;

        case AssessmentResponse.unsure:
          score = question.unsureScore;
          break;
      }

      switch (question.category) {
        case "Legal":
          legal += score;
          break;

        case "Utilities":
          utility += score;
          break;

        case "Safety":
          safety += score;
          break;

        case "Builder":
          builder += score;
          break;
      }
    }

    return AssessmentEvaluationResult(
      legalScore: legal,
      utilityScore: utility,
      safetyScore: safety,
      builderScore: builder,
    );
  }
}