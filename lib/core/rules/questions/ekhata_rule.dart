import '../../phs/phs_answer.dart';
import '../question_evaluation.dart';
import 'question_rule.dart';

class EkhataRule extends QuestionRule {
  const EkhataRule();

  @override
  QuestionEvaluation evaluate(PHSAnswer answer) {
    switch (answer.response) {
      case PHSResponse.yes:
        return const QuestionEvaluation(
          score: 20,
          maxScore: 20,
        );

      case PHSResponse.unsure:
        return const QuestionEvaluation(
          score: 10,
          maxScore: 20,
        );

      case PHSResponse.no:
        return const QuestionEvaluation(
          score: 0,
          maxScore: 20,
        );
    }
  }
}