import '../../data/phs_questions.dart';
import '../phs/phs_answer.dart';
import 'builders/assessment_result_builder.dart';
import 'evaluator/rule_evaluator.dart';
import 'models/property_health_result.dart';
import 'models/question_evaluation.dart';
import 'registry/rule_registry.dart';

class PropertyIntelligenceEngine {
  final RuleRegistry _registry;
  final RuleEvaluator _evaluator;
  final AssessmentResultBuilder _resultBuilder;

  PropertyIntelligenceEngine()
      : _registry = RuleRegistry(),
        _evaluator = RuleEvaluator(),
        _resultBuilder = AssessmentResultBuilder();

  /// Evaluates a single PHS answer.
  QuestionEvaluation evaluate(PHSAnswer answer) {
    final rule = _registry.getRule(answer.questionId);

    return _evaluator.evaluate(
      answer: answer,
      rule: rule,
    );
  }

  /// Evaluates a complete PHS assessment.
  PropertyHealthResult evaluateAssessment(
    List<PHSAnswer> answers,
  ) {
    final evaluations = <QuestionEvaluation>[];

    for (final answer in answers) {
      final rule = _registry.getRule(answer.questionId);

      final evaluation = _evaluator.evaluate(
        answer: answer,
        rule: rule,
      );

      evaluations.add(evaluation);
    }

    return _resultBuilder.build(
      evaluations: evaluations,
      totalQuestionCount: phsQuestions.length,
    );
  }
}