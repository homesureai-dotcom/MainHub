import '../../phs/phs_answer.dart';
import '../../phs/phs_categories.dart';
import 'answer_config.dart';

/// Complete configuration for a Property Health rule.
///
/// A QuestionRuleConfig defines:
/// - Which question it applies to
/// - Which PHS category it belongs to
/// - How much it contributes to the category score
/// - What happens for YES / NO / UNSURE
class QuestionRuleConfig {
  /// Unique question identifier.
  final String questionId;

  /// PHS category to which this question contributes.
  final PHSCategory category;

  /// Rule version.
  final int version;

  /// Whether this rule is active.
  final bool enabled;

  /// Maximum possible score for this question.
  final double weight;

  /// Configuration for each possible response.
  final Map<PHSResponse, AnswerConfig> answers;

  const QuestionRuleConfig({
    required this.questionId,
    required this.category,
    required this.weight,
    required this.answers,
    this.version = 1,
    this.enabled = true,
  });

  /// Returns the configuration for a specific response.
  AnswerConfig configFor(PHSResponse response) {
    final config = answers[response];

    if (config == null) {
      throw StateError(
        'No configuration found for response: '
        '$response in question $questionId',
      );
    }

    return config;
  }

  /// Whether this rule is currently active.
  bool get isEnabled => enabled;
}