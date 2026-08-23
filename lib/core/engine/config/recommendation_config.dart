/// Configuration describing the recommendation
/// produced by the Property Intelligence Engine.
class RecommendationConfig {
  /// Recommendation title.
  final String title;

  /// Detailed explanation shown to the user.
  final String description;

  /// Estimated increase in the Property Health Index
  /// after completing this recommendation.
  final int estimatedPHIGain;

  /// Documents required to complete the recommendation.
  final List<String> requiredDocuments;

  const RecommendationConfig({
    required this.title,
    required this.description,
    required this.estimatedPHIGain,
    this.requiredDocuments = const [],
  });
}