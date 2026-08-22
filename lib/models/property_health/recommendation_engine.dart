import '../../core/phs/phs_answer.dart';
import '../../models/property_health/category_score.dart';
import '../../models/property_health/property_risk.dart';
import '../../models/property_health/recommendation.dart';

/// Generates recommendations from
/// assessment results.
///
/// Currently returns an empty list.
/// Recommendation rules will be added
/// incrementally.
class RecommendationEngine {
  List<Recommendation> generate({
    required List<PHSAnswer> answers,
    required List<PropertyRisk> risks,
    required List<CategoryScore> categoryScores,
  }) {
    return [];
  }
}