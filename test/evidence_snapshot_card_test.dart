import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/widgets/dashboard/evidence_snapshot_card.dart';

Property createTestProperty() {
  return const Property(
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
    carpetArea: 1000,
    totalUnits: 100,
    compliance: ComplianceSummary(
      verifiedCount: 3,
      pendingCount: 2,
      issueCount: 1,
      compliancePercentage: 60,
    ),
    assessment: AssessmentSummary(),
    documents: DocumentSummary(
      verifiedDocuments: 2,
      pendingDocuments: 1,
      missingDocuments: 1,
    ),
  );
}

AssessmentEvidenceSummary createEvidenceSummary({
  required int totalRequirements,
  required int satisfiedRequirements,
  required int providedRequirements,
  required int needsReviewRequirements,
  required int missingRequirements,
  required int rejectedRequirements,
  required double coveragePercentage,
}) {
  return AssessmentEvidenceSummary(
    overallCoverage: EvidenceCoverage(
      totalRequirements: totalRequirements,
      satisfiedRequirements: satisfiedRequirements,
      providedRequirements: providedRequirements,
      needsReviewRequirements: needsReviewRequirements,
      missingRequirements: missingRequirements,
      rejectedRequirements: rejectedRequirements,
      coveragePercentage: coveragePercentage,
    ),
    validationResults: const [],
    riskSignals: const [],
    categoryCoverage: const [],
  );
}

DashboardData createDashboardData({
  AssessmentEvidenceSummary? evidenceSummary,
}) {
  return DashboardData(
    property: createTestProperty(),
    evidenceSummary: evidenceSummary,
  );
}

void main() {
  testWidgets(
    'shows empty state when evidence summary is unavailable',
    (tester) async {
      final data = createDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvidenceSnapshotCard(data: data),
          ),
        ),
      );

      expect(
        find.text('Evidence Snapshot'),
        findsOneWidget,
      );

      expect(
        find.text('Supporting documents and proof'),
        findsOneWidget,
      );

      expect(
        find.text(
          'No evidence has been added yet. Add supporting documents, photographs, videos, or other evidence to strengthen your assessment.',
        ),
        findsOneWidget,
      );

      expect(
        find.text('View Evidence Details'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'shows evidence coverage and metrics when summary is available',
    (tester) async {
      final data = createDashboardData(
        evidenceSummary: createEvidenceSummary(
          totalRequirements: 4,
          satisfiedRequirements: 3,
          providedRequirements: 0,
          needsReviewRequirements: 0,
          missingRequirements: 1,
          rejectedRequirements: 0,
          coveragePercentage: 75,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvidenceSnapshotCard(data: data),
          ),
        ),
      );

      expect(
        find.text('75%'),
        findsOneWidget,
      );

      expect(
        find.text('coverage'),
        findsOneWidget,
      );

      expect(
        find.text('3'),
        findsOneWidget,
      );

      expect(
        find.text('Satisfied'),
        findsOneWidget,
      );

      expect(
        find.text('Review'),
        findsOneWidget,
      );

      expect(
        find.text('Missing'),
        findsOneWidget,
      );

      expect(
        find.text('View Evidence Details'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows rejected evidence notice when rejected evidence exists',
    (tester) async {
      final data = createDashboardData(
        evidenceSummary: createEvidenceSummary(
          totalRequirements: 4,
          satisfiedRequirements: 2,
          providedRequirements: 0,
          needsReviewRequirements: 0,
          missingRequirements: 1,
          rejectedRequirements: 1,
          coveragePercentage: 50,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvidenceSnapshotCard(data: data),
          ),
        ),
      );

      expect(
        find.text('1 evidence item needs attention.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'view evidence details callback is invoked',
    (tester) async {
      var tapped = false;

      final data = createDashboardData(
        evidenceSummary: createEvidenceSummary(
          totalRequirements: 5,
          satisfiedRequirements: 4,
          providedRequirements: 0,
          needsReviewRequirements: 1,
          missingRequirements: 0,
          rejectedRequirements: 0,
          coveragePercentage: 80,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvidenceSnapshotCard(
              data: data,
              onViewDetails: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.text('View Evidence Details'),
      );

      expect(tapped, isTrue);
    },
  );
}
