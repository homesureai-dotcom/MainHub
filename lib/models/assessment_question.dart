class AssessmentQuestion {
  final String id;
  final String category;
  final String question;
  final String helpText;
  final int yesScore;
  final int noScore;
  final int unsureScore;

  const AssessmentQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.helpText,
    required this.yesScore,
    required this.noScore,
    required this.unsureScore,
  });
}