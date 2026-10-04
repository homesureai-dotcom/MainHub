import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';

import 'package:homesure_ai/screens/assessment/evidence_details_screen.dart';
import 'package:homesure_ai/screens/assessment/surebot_screen.dart';
import 'package:homesure_ai/screens/home_screen_v2.dart';

import 'package:homesure_ai/state/assessment_state.dart';

import 'package:homesure_ai/widgets/dashboard/assessment_progress_card.dart';
import 'package:homesure_ai/widgets/dashboard/evidence_snapshot_card.dart';
import 'package:homesure_ai/widgets/dashboard/quick_action_card.dart';

Property createProperty() {
  return Property(
    id: 'property-001',
    name: 'Casagrand Aquene',
    builderName: 'Casagrand',
    ownerName: 'Vinod',
    address: const Address(
      line1: 'Bangalore',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ),
    type: PropertyType.apartment,
    yearOfConstruction: 2026,
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

void main() {
  setUp(() {
    PropertyState.instance.clear();
    AssessmentState.instance.clearAssessment();
  });

  tearDown(() {
    PropertyState.instance.clear();
    AssessmentState.instance.clearAssessment();
  });

  testWidgets(
    'shows selected property dashboard',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Casagrand Aquene'),
        findsOneWidget,
      );

      expect(
        find.text('Bengaluru'),
        findsOneWidget,
      );

      expect(
        find.byType(AssessmentProgressCard),
        findsOneWidget,
      );

      expect(
        find.byType(EvidenceSnapshotCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows no property selected state',
    (tester) async {
      PropertyState.instance.initialize(
        properties: const [],
        selectedProperty: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No property selected.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows explicit not-started assessment state',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Not Assessed'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Your property health assessment has not started yet.',
        ),
        findsAtLeastNWidgets(1),
      );

      expect(
        find.byType(AssessmentProgressCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows assessment progress and priorities after assessment starts',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      AssessmentState.instance.startAssessment(
        propertyId: property.id,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(AssessmentProgressCard),
        findsOneWidget,
      );

      expect(
        find.text('Today’s Priorities'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows evidence snapshot',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(EvidenceSnapshotCard),
        findsOneWidget,
      );

      expect(
        find.text('Evidence Snapshot'),
        findsOneWidget,
      );

      expect(
        find.text(
          'No evidence has been added yet. Add supporting documents, photographs, videos, or other evidence to strengthen your assessment.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens AI Advisor from Quick Actions',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      final aiAdvisorCard = find.ancestor(
        of: find.text('AI Advisor'),
        matching: find.byType(QuickActionCard),
      );

      expect(
        aiAdvisorCard,
        findsOneWidget,
      );

      await tester.ensureVisible(aiAdvisorCard);
      await tester.tap(aiAdvisorCard);

      await tester.pumpAndSettle();

      expect(
        find.byType(SureBotScreen),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens Documents from Quick Actions',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      final documentsCard = find.ancestor(
        of: find.text('Documents'),
        matching: find.byType(QuickActionCard),
      );

      expect(
        documentsCard,
        findsOneWidget,
      );

      await tester.ensureVisible(documentsCard);
      await tester.tap(documentsCard);

      await tester.pumpAndSettle();

      expect(
        find.byType(EvidenceDetailsScreen),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'does not navigate to Compliance when there is no assessment',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      final complianceCard = find.ancestor(
        of: find.text('Compliance'),
        matching: find.byType(QuickActionCard),
      );

      expect(
        complianceCard,
        findsOneWidget,
      );

      await tester.ensureVisible(complianceCard);
      await tester.tap(complianceCard);

      await tester.pumpAndSettle();

      expect(
        find.byType(HomeScreenV2),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'does not navigate to Timeline because the Timeline screen is not implemented',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      final timelineCard = find.ancestor(
        of: find.text('Timeline'),
        matching: find.byType(QuickActionCard),
      );

      expect(
        timelineCard,
        findsOneWidget,
      );

      await tester.ensureVisible(timelineCard);
      await tester.tap(timelineCard);

      await tester.pumpAndSettle();

      expect(
        find.byType(HomeScreenV2),
        findsOneWidget,
      );
    },
  );
}