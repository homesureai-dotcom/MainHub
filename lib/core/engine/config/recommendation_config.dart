import '../../../models/property_health/recommendation.dart';

/// Configuration describing a recommendation produced
/// by the Property Intelligence Engine.
class RecommendationConfig {
  /// Recommendation title.
  final String title;

  /// Detailed explanation shown to the user.
  final String description;

  /// Estimated improvement to the Property Health Index.
  final int estimatedPHIGain;

  /// Priority assigned to the recommendation.
  final RecommendationPriority priority;

  /// Documents required to complete the recommendation.
  final List<String> requiredDocuments;

  const RecommendationConfig({
    required this.title,
    required this.description,
    required this.estimatedPHIGain,
    required this.priority,
    this.requiredDocuments = const [],
  });
}