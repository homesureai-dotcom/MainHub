import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/widgets/dashboard/property_health_breakdown_card.dart';

void main() {
  PropertyHealthResult buildResult({
    Map<PHSCategory, double> categoryScores = const {},
    double overallScore = 72,
  }) {
    return PropertyHealthResult(
      overallScore: overallScore,
      categoryScores: categoryScores,
      risks: const [],
      recommendations: const [],
      evaluatedQuestionCount: categoryScores.isEmpty ? 0 : 33,
      totalQuestionCount: 33,
      evaluatedCategoryCount: categoryScores.length,
      totalCategoryCount: 6,
      evaluatedAt: DateTime(2026, 10, 1),
      phsVersion: '1.0',
    );
  }

  Widget buildTestWidget(PropertyHealthResult result) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PropertyHealthBreakdownCard(
            result: result,
          ),
        ),
      ),
    );
  }

  group('PropertyHealthBreakdownCard', () {
    testWidgets('shows all six property health pillars', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          buildResult(
            categoryScores: const {
              PHSCategory.legalOwnership: 61,
              PHSCategory.constructionQuality: 84,
              PHSCategory.utilitiesInfrastructure: 68,
              PHSCategory.safetyCompliance: 91,
              PHSCategory.communityMaintenance: 78,
              PHSCategory.documentation: 52,
            },
          ),
        ),
      );

      expect(find.text('Property Health Breakdown'), findsOneWidget);
      expect(find.text('Legal & Ownership'), findsOneWidget);
      expect(find.text('Construction Quality'), findsOneWidget);
      expect(find.text('Utilities & Infrastructure'), findsOneWidget);
      expect(find.text('Safety & Compliance'), findsOneWidget);
      expect(find.text('Community & Maintenance'), findsOneWidget);
      expect(find.text('Documentation'), findsOneWidget);
    });

    testWidgets('shows category scores and weights', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          buildResult(
            categoryScores: const {
              PHSCategory.legalOwnership: 61,
              PHSCategory.constructionQuality: 84,
              PHSCategory.utilitiesInfrastructure: 68,
              PHSCategory.safetyCompliance: 91,
              PHSCategory.communityMaintenance: 78,
              PHSCategory.documentation: 52,
            },
          ),
        ),
      );

      expect(find.text('61'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
      expect(find.text('68'), findsOneWidget);
      expect(find.text('91'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);

      expect(find.text('25% weight'), findsNWidgets(2));
      expect(find.text('15% weight'), findsNWidgets(2));
      expect(find.text('10% weight'), findsNWidgets(2));
    });

    testWidgets('uses Not Assessed for unevaluated categories',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          buildResult(
            categoryScores: const {
              PHSCategory.legalOwnership: 61,
              PHSCategory.safetyCompliance: 91,
            },
          ),
        ),
      );

      expect(find.text('61'), findsOneWidget);
      expect(find.text('91'), findsOneWidget);

      expect(find.text('Not Assessed'), findsNWidgets(4));
      expect(find.text('—'), findsNWidgets(4));
    });

    testWidgets('shows score health labels for assessed categories',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          buildResult(
            categoryScores: const {
              PHSCategory.legalOwnership: 61,
              PHSCategory.constructionQuality: 84,
              PHSCategory.safetyCompliance: 91,
              PHSCategory.documentation: 52,
            },
          ),
        ),
      );

      expect(find.textContaining('Needs Attention'), findsNWidgets(1));
      expect(find.textContaining('Good'), findsNWidgets(1));
      expect(find.textContaining('Excellent'), findsNWidgets(1));
      expect(find.textContaining('At Risk'), findsNWidgets(1));
    });

    testWidgets('shows overall score when final score is available',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          buildResult(
            overallScore: 82,
            categoryScores: const {
              PHSCategory.legalOwnership: 82,
              PHSCategory.constructionQuality: 82,
              PHSCategory.utilitiesInfrastructure: 82,
              PHSCategory.safetyCompliance: 82,
              PHSCategory.communityMaintenance: 82,
              PHSCategory.documentation: 82,
            },
          ),
        ),
      );

      expect(find.text('82/100'), findsOneWidget);
    });

    testWidgets('calls category callback when a pillar is tapped',
        (tester) async {
      PHSCategory? selectedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyHealthBreakdownCard(
                result: buildResult(
                  categoryScores: const {
                    PHSCategory.legalOwnership: 61,
                    PHSCategory.constructionQuality: 84,
                    PHSCategory.utilitiesInfrastructure: 68,
                    PHSCategory.safetyCompliance: 91,
                    PHSCategory.communityMaintenance: 78,
                    PHSCategory.documentation: 52,
                  },
                ),
                onCategoryTap: (category) {
                  selectedCategory = category;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Legal & Ownership'));
      await tester.pump();

      expect(selectedCategory, PHSCategory.legalOwnership);
    });
  });
}
