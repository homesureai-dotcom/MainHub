import '../../phs/phs_answer.dart';
import '../question_evaluation.dart';
import 'question_rule.dart';

class EncumbranceRule extends QuestionRule {
  const EncumbranceRule();

  @override
  QuestionEvaluation evaluate(PHSAnswer answer) {
    switch (answer.response) {
      case PHSResponse.yes:
        return const QuestionEvaluation(
          score: 15,
          maxScore: 15,
        );

      case PHSResponse.unsure:
        return const QuestionEvaluation(
          score: 7.5,
          maxScore: 15,
        );

      case PHSResponse.no:
        return const QuestionEvaluation(
          score: 0,
          maxScore: 15,
        );
    }
  }
}