import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  final engine = PropertyIntelligenceEngine();

  group('Safety & Compliance', () {
    test('all safety answers as Yes produce 100 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'SAFETY_FIRE_NOC',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_EMERGENCY_EXITS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_FIRE_SYSTEM',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_CCTV',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_SECURITY',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_LIGHTNING',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.safetyCompliance],
        closeTo(100.0, 0.0001),
      );

      expect(result.risks, isEmpty);
      expect(result.recommendations, isEmpty);
    });

    test('all safety answers as No produce 0 category score', () {
      final answers = [
        PHSAnswer(
          questionId: 'SAFETY_FIRE_NOC',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_EMERGENCY_EXITS',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_FIRE_SYSTEM',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_CCTV',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_SECURITY',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_LIGHTNING',
          response: PHSResponse.no,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.safetyCompliance],
        closeTo(0.0, 0.0001),
      );

      expect(result.risks.length, 6);
      expect(result.recommendations.length, 6);
    });

    test('all Not Sure answers produce 50 percent Safety score', () {
      final answers = [
        PHSAnswer(
          questionId: 'SAFETY_FIRE_NOC',
          response: PHSResponse.unsure,
        ),
        PHSAnswer(
          questionId: 'SAFETY_EMERGENCY_EXITS',
          response: PHSResponse.unsure,
        ),
        PHSAnswer(
          questionId: 'SAFETY_FIRE_SYSTEM',
          response: PHSResponse.unsure,
        ),
        PHSAnswer(
          questionId: 'SAFETY_CCTV',
          response: PHSResponse.unsure,
        ),
        PHSAnswer(
          questionId: 'SAFETY_SECURITY',
          response: PHSResponse.unsure,
        ),
        PHSAnswer(
          questionId: 'SAFETY_LIGHTNING',
          response: PHSResponse.unsure,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.safetyCompliance],
        closeTo(50.0, 0.0001),
      );
    });

    test('mixed safety answers calculate the expected score', () {
      final answers = [
        PHSAnswer(
          questionId: 'SAFETY_FIRE_NOC',
          response: PHSResponse.no,
        ),
        PHSAnswer(
          questionId: 'SAFETY_EMERGENCY_EXITS',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_FIRE_SYSTEM',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_CCTV',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_SECURITY',
          response: PHSResponse.yes,
        ),
        PHSAnswer(
          questionId: 'SAFETY_LIGHTNING',
          response: PHSResponse.yes,
        ),
      ];

      final result = engine.evaluateAssessment(answers);

      expect(
        result.categoryScores[PHSCategory.safetyCompliance],
        closeTo(80.0, 0.0001),
      );

      expect(result.risks.length, 1);
      expect(result.recommendations.length, 1);
    });
  });
}