import 'score_result.dart';

class ScoreEngine {
  const ScoreEngine();

  ScoreResult calculate({
    required int legalScore,
    required int utilityScore,
    required int safetyScore,
    required int builderScore,
  }) {
    final overallScore = (
      legalScore +
      utilityScore +
      safetyScore +
      builderScore
    ) ~/ 4;

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
          "Your property has significant compliance risks that require immediate attention.";
    }

    return ScoreResult(
      overallScore: overallScore,
      legalScore: legalScore,
      utilityScore: utilityScore,
      safetyScore: safetyScore,
      builderScore: builderScore,
      grade: grade,
      summary: summary,
    );
  }
}