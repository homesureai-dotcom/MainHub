import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/assessment/assessment_result.dart';
import 'package:homesure_ai/core/assessment/category_result.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/features/report/models/property_health_report.dart';
import 'package:homesure_ai/features/surebot/services/property_health_explainer.dart';

PropertyHealthReport buildReport({
  double score = 60,
  List<ReportRisk> risks = const [],
  List<ReportRecommendation> recommendations = const [],
  List<MissingDocument> missingDocuments = const [],
}) {
  return PropertyHealthReport(
    propertyName: 'HomeSure Residency',
    builderName: 'ABC Builders',
    ownerName: 'Test Owner',
    address: '123 Main Road',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560001',
    assessmentDate: DateTime(2026, 10, 27),
    assessment: AssessmentResult(
      overallScore: score,
      grade: 'B',
      summary: 'Assessment summary',
      categoryResults: const [
        CategoryResult(
          category: PHSCategory.legalOwnership,
          earnedScore: 4,
          maximumScore: 10,
          weight: 25,
        ),
        CategoryResult(
          category: PHSCategory.documentation,
          earnedScore: 8,
          maximumScore: 10,
          weight: 10,
        ),
      ],
      recommendations: const [],
    ),
    risks: risks,
    recommendations: recommendations,
    missingDocuments: missingDocuments,
    aiInsights: const [],
  );
}

void main() {
  const explainer = PropertyHealthExplainer();

  group('PropertyHealthExplainer', () {
    test('explains a low assessment score cautiously', () {
      final explanation = explainer.explain(buildReport(score: 40));

      expect(explanation.score, 40);
      expect(explanation.summary, contains('substantial areas'));
      expect(explanation.propertyName, 'HomeSure Residency');
    });

    test('explains a medium assessment score', () {
      final explanation = explainer.explain(buildReport(score: 60));

      expect(
        explanation.summary,
        contains('areas that may need further review'),
      );
    });

    test(
      'explains a high assessment score without guaranteeing compliance',
      () {
        final explanation = explainer.explain(buildReport(score: 90));

        expect(explanation.summary, contains('score is high'));
        expect(explanation.summary, contains('verify'));
      },
    );

    test('orders categories from lowest to highest score', () {
      final explanation = explainer.explain(buildReport());

      expect(explanation.categories, hasLength(2));
      expect(explanation.categories.first.name, 'Legal & Ownership');
      expect(explanation.categories.first.score, 40);
      expect(explanation.categories.last.name, 'Documentation');
      expect(explanation.categories.last.score, 80);
    });

    test('includes risk severity and description', () {
      final explanation = explainer.explain(
        buildReport(
          risks: const [
            ReportRisk(
              title: 'Missing fire approval',
              description: 'Obtain and verify the relevant approval.',
              severity: RiskSeverity.high,
            ),
          ],
        ),
      );

      expect(explanation.risks, hasLength(1));
      expect(explanation.risks.single, contains('HIGH'));
      expect(explanation.risks.single, contains('Missing fire approval'));
      expect(explanation.risks.single, contains('Obtain and verify'));
    });

    test('includes recommendations as priority actions', () {
      final explanation = explainer.explain(
        buildReport(
          recommendations: const [
            ReportRecommendation(
              title: 'Verify sale deed',
              description: 'Request a copy and verify its registration.',
              expectedScoreIncrease: 10,
              estimatedTimeline: '1 week',
            ),
          ],
        ),
      );

      expect(explanation.priorityActions, hasLength(1));
      expect(explanation.priorityActions.single, contains('Verify sale deed'));
      expect(
        explanation.priorityActions.single,
        contains('verify its registration'),
      );
    });

    test('distinguishes mandatory documents from additional checks', () {
      final explanation = explainer.explain(
        buildReport(
          missingDocuments: const [
            MissingDocument(name: 'Occupancy Certificate', mandatory: true),
            MissingDocument(name: 'Maintenance records', mandatory: false),
          ],
        ),
      );

      expect(explanation.missingEvidence, hasLength(2));
      expect(explanation.missingEvidence[0], contains('Marked mandatory'));
      expect(explanation.missingEvidence[0], contains('Occupancy Certificate'));
      expect(explanation.missingEvidence[1], contains('Additional check'));
      expect(explanation.missingEvidence[1], contains('Maintenance records'));
    });

    test('includes a disclaimer against treating the explanation as proof', () {
      final explanation = explainer.explain(buildReport());

      expect(explanation.disclaimer, contains('not a legal opinion'));
      expect(explanation.disclaimer, contains('guarantee of property safety or compliance'));
    });
  });
}
