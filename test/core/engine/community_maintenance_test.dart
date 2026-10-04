import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  final engine = PropertyIntelligenceEngine();

  group('Community & Maintenance PHS', () {
    test('all Community answers Yes should produce a score of 100', () {
      final result = engine.evaluateAssessment([
        const PHSAnswer(
          questionId: 'COMMUNITY_ASSOCIATION',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_CORPUS',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_AMC',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_VENDOR_CONTRACTS',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_COMPLAINTS',
          response: PHSResponse.yes,
        ),
      ]);

      expect(
        result.categoryScores[PHSCategory.communityMaintenance],
        100.0,
      );

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);
      expect(result.isComplete, false);
      expect(result.risks, isEmpty);
      expect(result.recommendations, isEmpty);
    });

    test('all Community answers Unsure should produce a score of 50', () {
      final result = engine.evaluateAssessment([
        const PHSAnswer(
          questionId: 'COMMUNITY_ASSOCIATION',
          response: PHSResponse.unsure,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_CORPUS',
          response: PHSResponse.unsure,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_AMC',
          response: PHSResponse.unsure,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_VENDOR_CONTRACTS',
          response: PHSResponse.unsure,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_COMPLAINTS',
          response: PHSResponse.unsure,
        ),
      ]);

      expect(
        result.categoryScores[PHSCategory.communityMaintenance],
        50.0,
      );

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);
      expect(result.risks, hasLength(5));
      expect(result.recommendations, hasLength(5));
    });

    test('all Community answers No should produce a score of 0', () {
      final result = engine.evaluateAssessment([
        const PHSAnswer(
          questionId: 'COMMUNITY_ASSOCIATION',
          response: PHSResponse.no,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_CORPUS',
          response: PHSResponse.no,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_AMC',
          response: PHSResponse.no,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_VENDOR_CONTRACTS',
          response: PHSResponse.no,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_COMPLAINTS',
          response: PHSResponse.no,
        ),
      ]);

      expect(
        result.categoryScores[PHSCategory.communityMaintenance],
        0.0,
      );

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);
      expect(result.risks, hasLength(5));
      expect(result.recommendations, hasLength(5));
    });

    test('mixed Community answers should produce the correct weighted score', () {
      final result = engine.evaluateAssessment([
        const PHSAnswer(
          questionId: 'COMMUNITY_ASSOCIATION',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_CORPUS',
          response: PHSResponse.yes,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_AMC',
          response: PHSResponse.unsure,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_VENDOR_CONTRACTS',
          response: PHSResponse.no,
        ),
        const PHSAnswer(
          questionId: 'COMMUNITY_COMPLAINTS',
          response: PHSResponse.yes,
        ),
      ]);

      // 20 + 20 + 10 + 0 + 20 = 70.
      expect(
        result.categoryScores[PHSCategory.communityMaintenance],
        70.0,
      );

      expect(result.evaluatedQuestionCount, 5);
      expect(result.evaluatedCategoryCount, 1);
      expect(result.risks, hasLength(2));
      expect(result.recommendations, hasLength(2));
    });
  });
}