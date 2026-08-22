class ScoreResult {
  final int overallScore;
  final int legalScore;
  final int utilityScore;
  final int safetyScore;
  final int builderScore;

  final String grade;
  final String summary;

  const ScoreResult({
    required this.overallScore,
    required this.legalScore,
    required this.utilityScore,
    required this.safetyScore,
    required this.builderScore,
    required this.grade,
    required this.summary,
  });
}