import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  final engine = PropertyIntelligenceEngine();

  group('Utilities & Infrastructure', () {
    test('all utility answers as Yes produce 100 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'UTILITY_BESCOM',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_BWSSB',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_STP',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WTP',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_DG',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_LIFTS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WATER',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.utilitiesInfrastructure],
        closeTo(100.0, 0.0001),
      );

      expect(result.risks, isEmpty);
      expect(result.recommendations, isEmpty);
    });

    test('all utility answers as No produce 0 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'UTILITY_BESCOM',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_BWSSB',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_STP',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WTP',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_DG',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_LIFTS',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WATER',
          response: PHSResponse.no,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.utilitiesInfrastructure],
        closeTo(0.0, 0.0001),
      );

      expect(result.risks.length, 7);
      expect(result.recommendations.length, 7);
    });

    test(
      'Not Sure responses produce a 50 percent Utilities score',
      () {
        final answers = [
          PHSAnswer(
            questionId: 'UTILITY_BESCOM',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_BWSSB',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_STP',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_WTP',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_DG',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_LIFTS',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'UTILITY_WATER',
            response: PHSResponse.unsure,
          ),
        ];

        final result = engine.evaluateAssessment(answers);

        expect(
          result.categoryScores[PHSCategory.utilitiesInfrastructure],
          closeTo(50.0, 0.0001),
        );
      },
    );

    test('mixed utility answers calculate the expected score', () {
      final answers = [
        PHSAnswer(
          questionId: 'UTILITY_BESCOM',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'UTILITY_BWSSB',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_STP',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WTP',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_DG',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_LIFTS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'UTILITY_WATER',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.utilitiesInfrastructure],
        closeTo(85.0, 0.0001),
      );

      expect(result.risks.length, 1);
      expect(result.recommendations.length, 1);
    });
  });
}