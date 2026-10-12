import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/screens/home_screen_v2.dart';
import 'package:homesure_ai/state/assessment_state.dart';
import 'package:homesure_ai/widgets/dashboard/assessment_progress_card.dart';
import 'package:homesure_ai/widgets/dashboard/evidence_snapshot_card.dart';
import 'package:homesure_ai/widgets/dashboard/todays_priorities_card.dart';
import 'package:homesure_ai/widgets/hero_score_card.dart';

void main() {
  setUp(() {
    PropertyState.instance.clear();
    AssessmentState.instance.clearAssessment();
  });

  tearDown(() {
    PropertyState.instance.clear();
    AssessmentState.instance.clearAssessment();
  });

  Property createProperty() {
    return Property(
      id: 'P001',
      name: 'Casagrand Aquene',
      builderName: 'Casagrand',
      ownerName: 'Vinod',
      address: const Address(
        line1: 'Kengeri',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560060',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 2025,
      carpetArea: 708,
      totalUnits: 333,
      compliance: const ComplianceSummary(
        verifiedCount: 24,
        pendingCount: 5,
        issueCount: 2,
        compliancePercentage: 82,
      ),
      assessment: const AssessmentSummary(),
      documents: const DocumentSummary(
        verifiedDocuments: 18,
        pendingDocuments: 4,
        missingDocuments: 3,
      ),
    );
  }

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
        find.descendant(
          of: find.byType(HeroScoreCard),
          matching: find.text('Not Assessed'),
        ),
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
        find.byType(TodaysPrioritiesCard),
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
        find.byType(EvidenceSnapshotCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows dashboard property name',
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
    },
  );

  testWidgets(
    'shows property health score when assessment is complete',
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
        find.byType(HeroScoreCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows priorities card',
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
        find.byType(TodaysPrioritiesCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders dashboard data correctly',
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
        find.byType(HeroScoreCard),
        findsOneWidget,
      );

      expect(
        find.byType(EvidenceSnapshotCard),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows dashboard cards for selected property',
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
        find.byType(HeroScoreCard),
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

      expect(
        find.byType(TodaysPrioritiesCard),
        findsOneWidget,
      );
    },
  );
}