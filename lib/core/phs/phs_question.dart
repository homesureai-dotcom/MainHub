import 'phs_categories.dart';

/// The type of residential property that a question applies to.
enum PropertyType {
  apartment,
  villa,
  independentHouse,
  commercial,
}

/// Business priority of a question.
enum QuestionPriority {
  critical,
  high,
  medium,
  low,
}

/// Represents one question in the HomeSure Property Health Standard.
class PHSQuestion {
  /// Unique question identifier.
  final String id;

  /// Assessment category.
  final PHSCategory category;

  /// The question shown to the user.
  final String title;

  /// Additional guidance shown below the question.
  final String helpText;

  /// Why this question matters.
  final String? whyItMatters;

  /// Business impact if the answer is negative.
  final String? impact;

  /// Priority of this question.
  final QuestionPriority? priority;

  /// Estimated Property Health improvement if resolved.
  final int? potentialPHIGain;

  /// Weight within the category.
  final int weight;

  /// Supporting evidence that strengthens the assessment.
  final List<String> requiredEvidence;

  /// Applicable property types.
  final List<PropertyType> applicableTo;

  /// Indicates whether the question is mandatory.
  final bool mandatory;

  /// Version of the Property Health Standard this question belongs to.
  final String phsVersion;

  const PHSQuestion({
    required this.id,
    required this.category,
    required this.title,
    required this.helpText,
    required this.weight,
    required this.requiredEvidence,
    required this.applicableTo,
    this.whyItMatters,
    this.impact,
    this.priority,
    this.potentialPHIGain,
    this.mandatory = true,
    this.phsVersion = '1.0',
  });
}