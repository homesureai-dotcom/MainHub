import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/widgets/dashboard/todays_priorities_card.dart';

void main() {
  group('TodaysPrioritiesCard', () {
    testWidgets(
      'shows assessment not started state',
      (tester) async {
        final data = createDashboardData();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(data: data),
            ),
          ),
        );

        expect(
          find.text('Today’s Priorities'),
          findsOneWidget,
        );

        expect(
          find.text('Complete your assessment to see priorities'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Your property health assessment has not started yet.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows no priorities state after assessment',
      (tester) async {
        final data = createDashboardData(
          healthResult: createHealthResult(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(data: data),
            ),
          ),
        );

        expect(
          find.text('What needs your attention'),
          findsOneWidget,
        );

        expect(
          find.text(
            'No priority actions have been identified yet.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows priority title, description, priority and PHI gain',
      (tester) async {
        const priority = DashboardPriority(
          id: 'priority-001',
          title: 'Complete e-Khata',
          description: 'Complete the pending e-Khata process.',
          priority: RecommendationPriority.high,
          estimatedPHIGain: 8,
          requiredDocuments: [
            'Sale Deed',
            'Khata Certificate',
          ],
        );

        final data = createDashboardData(
          healthResult: createHealthResult(),
          priorities: const [
            priority,
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(data: data),
            ),
          ),
        );

        expect(
          find.text('Complete e-Khata'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Complete the pending e-Khata process.',
          ),
          findsOneWidget,
        );

        expect(
          find.text('HIGH'),
          findsOneWidget,
        );

        expect(
          find.text('+8 PHI'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows only the top three priorities',
      (tester) async {
        final priorities = [
          createPriority(
            id: 'priority-001',
            title: 'Priority One',
          ),
          createPriority(
            id: 'priority-002',
            title: 'Priority Two',
          ),
          createPriority(
            id: 'priority-003',
            title: 'Priority Three',
          ),
          createPriority(
            id: 'priority-004',
            title: 'Priority Four',
          ),
        ];

        final data = createDashboardData(
          healthResult: createHealthResult(),
          priorities: priorities,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(data: data),
            ),
          ),
        );

        expect(
          find.text('Priority One'),
          findsOneWidget,
        );

        expect(
          find.text('Priority Two'),
          findsOneWidget,
        );

        expect(
          find.text('Priority Three'),
          findsOneWidget,
        );

        expect(
          find.text('Priority Four'),
          findsNothing,
        );

        expect(
          find.text('View All Priorities'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'calls view all callback',
      (tester) async {
        var tapped = false;

        final priorities = [
          createPriority(
            id: 'priority-001',
            title: 'Priority One',
          ),
          createPriority(
            id: 'priority-002',
            title: 'Priority Two',
          ),
          createPriority(
            id: 'priority-003',
            title: 'Priority Three',
          ),
          createPriority(
            id: 'priority-004',
            title: 'Priority Four',
          ),
        ];

        final data = createDashboardData(
          healthResult: createHealthResult(),
          priorities: priorities,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(
                data: data,
                onViewAll: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(
          find.text('View All Priorities'),
        );

        expect(
          tapped,
          isTrue,
        );
      },
    );

    testWidgets(
      'calls priority callback when a priority is tapped',
      (tester) async {
        DashboardPriority? tappedPriority;

        const priority = DashboardPriority(
          id: 'priority-001',
          title: 'Complete e-Khata',
          description: 'Complete the pending e-Khata process.',
          priority: RecommendationPriority.high,
          estimatedPHIGain: 8,
          requiredDocuments: [
            'Sale Deed',
            'Khata Certificate',
          ],
        );

        final data = createDashboardData(
          healthResult: createHealthResult(),
          priorities: const [
            priority,
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodaysPrioritiesCard(
                data: data,
                onPriorityTap: (value) {
                  tappedPriority = value;
                },
              ),
            ),
          ),
        );

        await tester.tap(
          find.text('Complete e-Khata'),
        );

        expect(
          tappedPriority,
          equals(priority),
        );
      },
    );
  });
}

DashboardData createDashboardData({
  PropertyHealthResult? healthResult,
  List<DashboardPriority> priorities = const [],
}) {
  return DashboardData(
    property: createProperty(),
    healthResult: healthResult,
    priorities: priorities,
  );
}

PropertyHealthResult createHealthResult() {
  return PropertyHealthResult(
    overallScore: 82,
    categoryScores: const {
      PHSCategory.legalOwnership: 82,
    },
    risks: const [],
    recommendations: const [],
    evaluatedQuestionCount: 1,
    totalQuestionCount: 33,
    evaluatedCategoryCount: 1,
    totalCategoryCount: 6,
    evaluatedAt: DateTime(2026, 10, 4),
  );
}

DashboardPriority createPriority({
  required String id,
  required String title,
}) {
  return DashboardPriority(
    id: id,
    title: title,
    description: '$title description.',
    priority: RecommendationPriority.high,
    estimatedPHIGain: 5,
    requiredDocuments: const [],
  );
}

Property createProperty() {
  return Property(
    id: 'property-001',
    name: 'Test Apartment',
    builderName: 'Test Builder',
    ownerName: 'Test Owner',
    address: const Address(
      line1: 'Test Address',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ),
    type: PropertyType.apartment,
    yearOfConstruction: 2025,
    carpetArea: 708,
    totalUnits: 333,
    compliance: const ComplianceSummary(
      verifiedCount: 3,
      pendingCount: 1,
      issueCount: 0,
      compliancePercentage: 75,
    ),
    assessment: const AssessmentSummary(
      latestAssessment: null,
      lastAssessmentDate: null,
    ),
    documents: const DocumentSummary(
      verifiedDocuments: 0,
      pendingDocuments: 0,
      missingDocuments: 0,
    ),
  );
}