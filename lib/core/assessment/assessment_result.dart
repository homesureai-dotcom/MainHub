import 'category_result.dart';

class AssessmentResult {
  /// Final HomeSure Property Health Score (0–100)
  final double overallScore;

  /// Grade derived from the overall score.
  final String grade;

  /// Human-readable assessment summary.
  final String summary;

  /// Result for each PHS category.
  final List<CategoryResult> categoryResults;

  /// Recommended next actions.
  final List<String> recommendations;

  const AssessmentResult({
    required this.overallScore,
    required this.grade,
    required this.summary,
    required this.categoryResults,
    required this.recommendations,
  });
}