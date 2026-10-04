import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  final engine = PropertyIntelligenceEngine();

  group('Construction Quality', () {
    test('all construction answers as Yes produce 100 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'CONSTRUCTION_CRACKS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_LEAKAGE',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_DAMPNESS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_FLOORING',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_PAINT',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_WATERPROOFING',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.constructionQuality],
        closeTo(100.0, 0.0001),
      );

      expect(result.risks, isEmpty);
      expect(result.recommendations, isEmpty);
    });

    test('all construction answers as No produce 0 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'CONSTRUCTION_CRACKS',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_LEAKAGE',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_DAMPNESS',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_FLOORING',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_PAINT',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_WATERPROOFING',
          response: PHSResponse.no,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.constructionQuality],
        closeTo(0.0, 0.0001),
      );

      expect(result.risks.length, 6);
      expect(result.recommendations.length, 6);
    });

    test('mixed construction answers calculate the weighted category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'CONSTRUCTION_CRACKS',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_LEAKAGE',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_DAMPNESS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_FLOORING',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_PAINT',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'CONSTRUCTION_WATERPROOFING',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.constructionQuality],
        closeTo(80.0, 0.0001),
      );

      expect(result.risks.length, 1);
      expect(result.recommendations.length, 1);
    });

    test(
      'Not Sure responses contribute 50 percent of each question weight',
      () {
        final answers = [
          PHSAnswer(
            questionId: 'CONSTRUCTION_CRACKS',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'CONSTRUCTION_LEAKAGE',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'CONSTRUCTION_DAMPNESS',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'CONSTRUCTION_FLOORING',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'CONSTRUCTION_PAINT',
            response: PHSResponse.unsure,
          ),
          PHSAnswer(
            questionId: 'CONSTRUCTION_WATERPROOFING',
            response: PHSResponse.unsure,
          ),
        ];

        final result = engine.evaluateAssessment(answers);

        expect(
          result.categoryScores[PHSCategory.constructionQuality],
          closeTo(50.0, 0.0001),
        );
      },
    );
  });
}