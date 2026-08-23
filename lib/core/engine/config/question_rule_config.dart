import '../../phs/phs_answer.dart';
import 'answer_config.dart';

/// Complete configuration for a Property Health rule.
///
/// A QuestionRuleConfig defines:
/// - Which question it applies to
/// - How much it contributes to the overall score
/// - What happens for YES / NO / UNSURE
class QuestionRuleConfig {
  /// Unique Question ID.
  final String questionId;

  /// Rule version.
  final int version;

  /// Whether this rule is active.
  final bool enabled;

  /// Maximum score for this question.
  final double weight;

  /// Configurations for each possible answer.
  final Map<PHSResponse, AnswerConfig> answers;

  const QuestionRuleConfig({
    required this.questionId,
    required this.weight,
    required this.answers,
    this.version = 1,
    this.enabled = true,
  });

  /// Returns the configuration for a specific answer.
  AnswerConfig configFor(PHSResponse response) {
    final config = answers[response];

    if (config == null) {
      throw StateError(
        'No configuration found for response: $response in question $questionId',
      );
    }

    return config;
  }

  /// Indicates whether the rule can be evaluated.
  bool get isEnabled => enabled;
}