import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';

void main() {
  late Property property;

  setUp(() {
    property = const Property(
      id: 'property-1',
      name: 'Test Apartment',
      builderName: 'Test Builder',
      ownerName: 'Test Owner',
      address: Address(
        line1: '123 Test Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 2025,
      carpetArea: 708,
      totalUnits: 333,
      compliance: ComplianceSummary(
        verifiedCount: 5,
        pendingCount: 2,
        issueCount: 1,
        compliancePercentage: 62.5,
      ),
      assessment: AssessmentSummary(),
      documents: DocumentSummary(
        verifiedDocuments: 8,
        pendingDocuments: 2,
        missingDocuments: 1,
      ),
    );
  });

  group('DashboardData', () {
    test('exposes property information', () {
      final data = DashboardData(
        property: property,
      );

      expect(data.property, same(property));
      expect(data.property.name, 'Test Apartment');
      expect(data.property.address.city, 'Bengaluru');
    });

    test('returns empty assessment state when no health result exists', () {
      final data = DashboardData(
        property: property,
      );

      expect(data.hasAssessment, isFalse);
      expect(data.isAssessmentComplete, isFalse);
      expect(data.hasFinalScore, isFalse);
      expect(data.healthScore, isNull);
      expect(data.healthGrade, isNull);
      expect(data.evaluatedQuestionCount, 0);
      expect(data.totalQuestionCount, 0);
      expect(data.questionCompletionPercentage, 0.0);
      expect(data.evaluatedCategoryCount, 0);
      expect(data.totalCategoryCount, 0);
      expect(data.categoryCompletionPercentage, 0.0);
      expect(data.riskCount, 0);
      expect(data.recommendationCount, 0);
    });

    test('returns empty evidence state when no evidence summary exists', () {
      final data = DashboardData(
        property: property,
      );

      expect(data.hasEvidenceSummary, isFalse);
      expect(data.evidenceCoveragePercentage, 0.0);
      expect(data.satisfiedEvidenceRequirements, 0);
      expect(data.totalEvidenceRequirements, 0);
      expect(data.evidenceNeedsReviewCount, 0);
      expect(data.missingEvidenceCount, 0);
      expect(data.rejectedEvidenceCount, 0);
      expect(data.activeEvidenceRiskCount, 0);
      expect(data.hasEvidenceGaps, isFalse);
    });

    test('maps an excellent score to the excellent grade', () {
      final result = _healthResult(
        score: 95,
        isComplete: true,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.hasAssessment, isTrue);
      expect(data.isAssessmentComplete, isTrue);
      expect(data.hasFinalScore, isTrue);
      expect(data.healthScore, 95);
      expect(data.healthGrade, 'Excellent');
    });

    test('maps a good score to the good grade', () {
      final result = _healthResult(
        score: 82,
        isComplete: true,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.healthGrade, 'Good');
    });

    test('maps a fair score to the fair grade', () {
      final result = _healthResult(
        score: 65,
        isComplete: true,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.healthGrade, 'Fair');
    });

    test('maps a low score to needs immediate attention', () {
      final result = _healthResult(
        score: 45,
        isComplete: true,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.healthGrade, 'Needs Immediate Attention');
    });

    test('does not expose a score when the assessment is incomplete', () {
      final result = _healthResult(
        score: 82,
        isComplete: false,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.hasAssessment, isTrue);
      expect(data.isAssessmentComplete, isFalse);
      expect(data.hasFinalScore, isFalse);
      expect(data.healthScore, isNull);
      expect(data.healthGrade, isNull);
    });

    test('exposes assessment completion metrics', () {
      final result = _healthResult(
        score: 82,
        isComplete: true,
      );

      final data = DashboardData(
        property: property,
        healthResult: result,
      );

      expect(data.evaluatedQuestionCount, 33);
      expect(data.totalQuestionCount, 33);
      expect(data.questionCompletionPercentage, 100.0);
      expect(data.evaluatedCategoryCount, 6);
      expect(data.totalCategoryCount, 6);
      expect(data.categoryCompletionPercentage, 100.0);
    });

    test('toString contains useful dashboard information', () {
      final data = DashboardData(
        property: property,
      );

      final value = data.toString();

      expect(value, contains('Test Apartment'));
      expect(value, contains('hasAssessment: false'));
      expect(value, contains('healthScore: null'));
    });

    test('supports equality for the same domain references', () {
      final data1 = DashboardData(
        property: property,
      );

      final data2 = DashboardData(
        property: property,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });
  });
}

PropertyHealthResult _healthResult({
  required double score,
  required bool isComplete,
}) {
  return PropertyHealthResult(
    overallScore: score,
    categoryScores: const {},
    risks: const [],
    recommendations: const [],
    evaluatedQuestionCount: isComplete ? 33 : 10,
    totalQuestionCount: 33,
    evaluatedCategoryCount: isComplete ? 6 : 3,
    totalCategoryCount: 6,
    evaluatedAt: DateTime(2026, 10, 1),
    phsVersion: '1.0',
  );
}