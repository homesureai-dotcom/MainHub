import '../phs/phs_answer.dart';
import 'builders/assessment_result_builder.dart';
import 'evaluator/rule_evaluator.dart';
import 'models/property_health_result.dart';
import 'models/question_evaluation.dart';
import 'registry/rule_registry.dart';

/// Facade for the Property Intelligence Engine.
///
/// All consumers (UI, reports, services, SureBot, etc.)
/// should interact only with this class.
class PropertyIntelligenceEngine {
  PropertyIntelligenceEngine({
    RuleRegistry? registry,
    RuleEvaluator? evaluator,
    AssessmentResultBuilder? resultBuilder,
  })  : _registry = registry ?? const RuleRegistry(),
        _evaluator = evaluator ?? const RuleEvaluator(),
        _resultBuilder = resultBuilder ?? const AssessmentResultBuilder();

  final RuleRegistry _registry;
  final RuleEvaluator _evaluator;
  final AssessmentResultBuilder _resultBuilder;

  /// ------------------------------------------------------------
  /// TEMPORARY API
  /// ------------------------------------------------------------
  ///
  /// Evaluates a single answer.
  ///
  /// This exists only to support the Engine Playground while we
  /// migrate the application to evaluate complete assessments.
  ///
  /// Once the assessment flow has been fully integrated, this
  /// method can be removed.
  ///
  QuestionEvaluation? evaluate(
    PHSAnswer answer,
  ) {
    final rule = _registry.getRule(answer.questionId);

    if (rule == null || !rule.isEnabled) {
      return null;
    }

    return _evaluator.evaluate(
      rule: rule,
      answer: answer,
    );
  }

  /// ------------------------------------------------------------
  /// PRIMARY API
  /// ------------------------------------------------------------
  ///
  /// Evaluates an entire assessment and returns the final
  /// Property Health Result.
  ///
  PropertyHealthResult evaluateAssessment(
    List<PHSAnswer> answers,
  ) {
    final List<QuestionEvaluation> evaluations = [];

    for (final answer in answers) {
      final rule = _registry.getRule(answer.questionId);

      if (rule == null || !rule.isEnabled) {
        continue;
      }

      final evaluation = _evaluator.evaluate(
        rule: rule,
        answer: answer,
      );

      evaluations.add(evaluation);
    }

    return _resultBuilder.build(
      evaluations: evaluations,
    );
  }
}