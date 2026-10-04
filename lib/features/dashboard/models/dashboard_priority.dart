import '../../../core/phs/phs_categories.dart';
import '../../../models/property_health/recommendation.dart';

/// A dashboard-ready representation of an actionable recommendation.
///
/// This model intentionally contains only presentation-facing information.
/// The underlying recommendation remains owned by the Property Health Engine.
class DashboardPriority {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final int estimatedPHIGain;
  final List<String> requiredDocuments;
  final PHSCategory? category;

  const DashboardPriority({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedPHIGain,
    required this.requiredDocuments,
    this.category,
  });

  bool get isCritical =>
      priority == RecommendationPriority.critical;

  bool get isHigh =>
      priority == RecommendationPriority.high;

  bool get isMedium =>
      priority == RecommendationPriority.medium;

  bool get isLow =>
      priority == RecommendationPriority.low;

  int get priorityRank {
    switch (priority) {
      case RecommendationPriority.critical:
        return 0;
      case RecommendationPriority.high:
        return 1;
      case RecommendationPriority.medium:
        return 2;
      case RecommendationPriority.low:
        return 3;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DashboardPriority &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.estimatedPHIGain == estimatedPHIGain &&
        _listEquals(
          other.requiredDocuments,
          requiredDocuments,
        ) &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        priority,
        estimatedPHIGain,
        Object.hashAll(requiredDocuments),
        category,
      );

  @override
  String toString() {
    return 'DashboardPriority('
        'id: $id, '
        'title: $title, '
        'priority: $priority, '
        'estimatedPHIGain: $estimatedPHIGain'
        ')';
  }

  static bool _listEquals(
    List<String> first,
    List<String> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}