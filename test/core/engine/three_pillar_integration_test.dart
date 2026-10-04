import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/engine.dart';
import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  final engine = PropertyIntelligenceEngine();

  test('four completed PHS pillars are aggregated correctly', () {
    final answers = [
      // =========================================================
      // Legal & Ownership
      // =========================================================

      PHSAnswer(
        questionId: 'LEGAL_OC',
        response: PHSResponse.no,
      ),
      PHSAnswer(
        questionId: 'LEGAL_SD',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'LEGAL_KHATA',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'LEGAL_EC',
        response: PHSResponse.yes,
      ),

      // =========================================================
      // Construction Quality
      // =========================================================

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

      // =========================================================
      // Utilities & Infrastructure
      // =========================================================

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

      // =========================================================
      // Community & Maintenance
      // =========================================================

      PHSAnswer(
        questionId: 'COMMUNITY_ASSOCIATION',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'COMMUNITY_CORPUS',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'COMMUNITY_AMC',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'COMMUNITY_VENDOR_CONTRACTS',
        response: PHSResponse.yes,
      ),
      PHSAnswer(
        questionId: 'COMMUNITY_COMPLAINTS',
        response: PHSResponse.yes,
      ),
    ];

    final result = engine.evaluateAssessment(answers);

    // =========================================================
    // Category Scores
    // =========================================================

    // Legal & Ownership:
    // (0 + 25 + 20 + 15) / 100 = 60
    expect(
      result.categoryScores[PHSCategory.legalOwnership],
      closeTo(60.0, 0.0001),
    );

    // Construction Quality:
    // (0 + 20 + 15 + 15 + 10 + 20) / 100 = 80
    expect(
      result.categoryScores[PHSCategory.constructionQuality],
      closeTo(80.0, 0.0001),
    );

    // Utilities & Infrastructure:
    // (0 + 15 + 15 + 15 + 15 + 10 + 15) / 100 = 85
    expect(
      result.categoryScores[PHSCategory.utilitiesInfrastructure],
      closeTo(85.0, 0.0001),
    );

    // Community & Maintenance:
    // (20 + 20 + 20 + 20 + 20) / 100 = 100
    expect(
      result.categoryScores[PHSCategory.communityMaintenance],
      closeTo(100.0, 0.0001),
    );

    // =========================================================
    // Weighted Overall Score
    // =========================================================

    // Legal:        60 × 25% = 15.00
    // Construction: 80 × 25% = 20.00
    // Utilities:    85 × 15% = 12.75
    // Community:   100 × 10% = 10.00
    //
    // Total = 57.75
    //
    // Safety & Compliance and Documentation are not evaluated,
    // so their contributions remain 0 for this partial assessment.
    expect(
      result.overallScore,
      closeTo(57.75, 0.0001),
    );

    // =========================================================
    // Assessment Completion
    // =========================================================

    expect(result.evaluatedQuestionCount, 22);
    expect(result.evaluatedCategoryCount, 4);
    expect(result.totalCategoryCount, 6);

    // Four of six PHS pillars are evaluated.
    expect(result.isComplete, false);

    // =========================================================
    // Risks & Recommendations
    // =========================================================

    // One risk from each of the three negative answers:
    // Legal OC
    // Construction Cracks
    // Utilities BESCOM
    expect(result.risks.length, 3);

    expect(result.recommendations.length, 3);
  });
}