import '../../phs/phs_answer.dart';
import '../question_evaluation.dart';

/// Base contract implemented by every
/// Property Health rule.
abstract class QuestionRule {
  const QuestionRule();

  /// Evaluates one assessment answer.
  QuestionEvaluation evaluate(
    PHSAnswer answer,
  );
}