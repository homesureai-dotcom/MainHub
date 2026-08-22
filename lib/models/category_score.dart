import '../enums/assessment_category.dart';

class CategoryScore {
  final AssessmentCategory category;

  /// Points earned by the user
  final int earned;

  /// Maximum possible points
  final int maximum;

  const CategoryScore({
    required this.category,
    required this.earned,
    required this.maximum,
  });

  double get percentage {
    if (maximum == 0) return 0;

    return (earned / maximum) * 100;
  }
}