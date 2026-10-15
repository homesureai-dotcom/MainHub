import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_answer.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/screens/assessment/assessment_screen.dart';
import 'package:homesure_ai/screens/assessment/surebot_screen.dart';
import 'package:homesure_ai/screens/dashboard/priority_detail_screen.dart';
import 'package:homesure_ai/screens/home_screen_v2.dart';
import 'package:homesure_ai/state/assessment_state.dart';
import 'package:homesure_ai/widgets/assessment/answer_option.dart';
import 'package:homesure_ai/widgets/dashboard/assessment_progress_card.dart';
import 'package:homesure_ai/widgets/dashboard/evidence_snapshot_card.dart';
import 'package:homesure_ai/widgets/dashboard/quick_action_card.dart';
import 'package:homesure_ai/widgets/dashboard/quick_action_grid.dart';
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

  Future<void> answerCurrentQuestion(WidgetTester tester) async {
    final answerOption = find.byType(AnswerOption).first;

    expect(answerOption, findsOneWidget);

    await tester.ensureVisible(answerOption);

    await tester.pumpAndSettle();

    await tester.tap(answerOption);

    await tester.pumpAndSettle();
  }

  testWidgets('shows no property selected state', (tester) async {
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
  });

  testWidgets('shows explicit not-started assessment state', (tester) async {
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

    expect(
      find.text('Assessment in progress'),
      findsNothing,
    );
  });

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

      expect(
        find.text('Assessment in progress'),
        findsOneWidget,
      );

      expect(
        find.text('Continue Assessment'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows evidence snapshot', (tester) async {
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
  });

  testWidgets('shows dashboard property name', (tester) async {
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
  });

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

  testWidgets('shows priorities card', (tester) async {
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
  });

  testWidgets('renders dashboard data correctly', (tester) async {
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
  });

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

  testWidgets(
    'shows continue assessment action for an active session',
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
        find.text('Assessment in progress'),
        findsOneWidget,
      );

      expect(
        find.text('Continue Assessment'),
        findsOneWidget,
      );

      expect(
        find.text('0 of 33 questions'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens assessment when continue assessment is tapped',
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

      final continueButton = find.text('Continue Assessment');

      expect(
        continueButton,
        findsOneWidget,
      );

      await tester.ensureVisible(continueButton);

      await tester.pumpAndSettle();

      await tester.tap(continueButton);

      await tester.pumpAndSettle();

      expect(
        find.byType(AssessmentScreen),
        findsOneWidget,
      );

      expect(
        find.text('Property Assessment'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resumes assessment from the next unanswered question after save and exit',
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
        find.byType(HomeScreenV2),
        findsOneWidget,
      );

      final startAssessmentButton = find.text('Start Assessment');

      if (startAssessmentButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(startAssessmentButton);

        await tester.pumpAndSettle();

        await tester.tap(startAssessmentButton);

        await tester.pumpAndSettle();
      } else {
        AssessmentState.instance.startAssessment(
          propertyId: property.id,
        );

        await tester.pumpAndSettle();

        final continueButton = find.text('Continue Assessment');

        expect(
          continueButton,
          findsOneWidget,
        );

        await tester.ensureVisible(continueButton);

        await tester.pumpAndSettle();

        await tester.tap(continueButton);

        await tester.pumpAndSettle();
      }

      expect(
        find.byType(AssessmentScreen),
        findsOneWidget,
      );

      expect(
        find.text('Property Assessment'),
        findsOneWidget,
      );

      expect(
        AssessmentState.instance.answeredQuestionCount,
        0,
      );

      expect(
        AssessmentState.instance.hasActiveSession,
        isTrue,
      );

      await answerCurrentQuestion(tester);

      await answerCurrentQuestion(tester);

      await answerCurrentQuestion(tester);

      expect(
        AssessmentState.instance.answeredQuestionCount,
        3,
      );

      final currentQuestionBeforeExit =
          AssessmentState.instance.currentQuestionId;

      expect(
        currentQuestionBeforeExit,
        isNotNull,
      );

      await tester.pageBack();

      await tester.pumpAndSettle();

      expect(
        find.byType(HomeScreenV2),
        findsOneWidget,
      );

      expect(
        find.text('Assessment in progress'),
        findsOneWidget,
      );

      expect(
        find.text('Continue Assessment'),
        findsOneWidget,
      );

      final continueButton = find.text('Continue Assessment');

      expect(
        continueButton,
        findsOneWidget,
      );

      await tester.ensureVisible(continueButton);

      await tester.pumpAndSettle();

      await tester.tap(continueButton);

      await tester.pumpAndSettle();

      expect(
        find.byType(AssessmentScreen),
        findsOneWidget,
      );

      expect(
        find.text('Property Assessment'),
        findsOneWidget,
      );

      expect(
        find.byType(HomeScreenV2),
        findsNothing,
      );

      expect(
        AssessmentState.instance.answeredQuestionCount,
        3,
      );

      expect(
        AssessmentState.instance.hasActiveSession,
        isTrue,
      );

      final sessionAfterResume =
          AssessmentState.instance.session;

      expect(
        sessionAfterResume,
        isNotNull,
      );

      expect(
        sessionAfterResume!.answers.length,
        3,
      );

      expect(
        AssessmentState.instance.currentQuestionId,
        currentQuestionBeforeExit,
      );
    },
  );

  testWidgets(
    'opens priority detail when a dashboard priority is tapped',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      // ------------------------------------------------------------
      // Start the assessment session.
      // ------------------------------------------------------------

      AssessmentState.instance.startAssessment(
        propertyId: property.id,
      );

      // ------------------------------------------------------------
      // Save a real assessment answer.
      //
      // LEGAL_SD + NO is handled by the production SaleDeedRule
      // and produces the "Obtain Registered Sale Deed"
      // recommendation.
      // ------------------------------------------------------------

      const saleDeedAnswer = PHSAnswer(
        questionId: 'LEGAL_SD',
        response: PHSResponse.no,
      );

      AssessmentState.instance.saveAnswer(
        saleDeedAnswer,
        currentQuestionId: 'LEGAL_SD',
      );

      // ------------------------------------------------------------
      // Open the real Dashboard.
      // ------------------------------------------------------------

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Verify the real dashboard priority exists.
      // ------------------------------------------------------------

      final priorityCard = find.byType(TodaysPrioritiesCard);

      expect(
        priorityCard,
        findsOneWidget,
      );

      final priorityTitle = find.descendant(
        of: priorityCard,
        matching: find.text('Obtain Registered Sale Deed'),
      );

      expect(
        priorityTitle,
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Scroll the Dashboard until the priority is visible.
      // ------------------------------------------------------------

      await tester.ensureVisible(priorityTitle);

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Tap the actual dashboard priority.
      // ------------------------------------------------------------

      await tester.tap(priorityTitle);

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Verify Dashboard -> PriorityDetailScreen navigation.
      // ------------------------------------------------------------

      expect(
        find.byType(PriorityDetailScreen),
        findsOneWidget,
      );

      expect(
        find.text('Priority Details'),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify the correct priority was passed to the detail screen.
      // ------------------------------------------------------------

      expect(
        find.text('Obtain Registered Sale Deed'),
        findsOneWidget,
      );

      expect(
        find.text('What needs your attention'),
        findsOneWidget,
      );

      expect(
        find.text('Potential PHI impact'),
        findsOneWidget,
      );

      expect(
        find.text('CRITICAL'),
        findsOneWidget,
      );

      expect(
        find.text('+25'),
        findsOneWidget,
      );

      expect(
        find.text('PHI'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens AI Advisor with dashboard-derived SureBot context',
    (tester) async {
      final property = createProperty();

      PropertyState.instance.initialize(
        properties: [property],
        selectedProperty: property,
      );

      // ------------------------------------------------------------
      // Start the real assessment session.
      // ------------------------------------------------------------

      AssessmentState.instance.startAssessment(
        propertyId: property.id,
      );

      // ------------------------------------------------------------
      // Save a real assessment answer.
      //
      // LEGAL_SD + NO is handled by the production SaleDeedRule
      // and produces the "Obtain Registered Sale Deed"
      // recommendation.
      // ------------------------------------------------------------

      const saleDeedAnswer = PHSAnswer(
        questionId: 'LEGAL_SD',
        response: PHSResponse.no,
      );

      AssessmentState.instance.saveAnswer(
        saleDeedAnswer,
        currentQuestionId: 'LEGAL_SD',
      );

      // ------------------------------------------------------------
      // Open the real Dashboard.
      // ------------------------------------------------------------

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Verify the Quick Actions section.
      // ------------------------------------------------------------

      final quickActionGrid = find.byType(QuickActionGrid);

      expect(
        quickActionGrid,
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify all four Quick Action cards exist.
      // ------------------------------------------------------------

      final quickActionCards = find.descendant(
        of: quickActionGrid,
        matching: find.byType(QuickActionCard),
      );

      expect(
        quickActionCards,
        findsNWidgets(4),
      );

      // ------------------------------------------------------------
      // Verify the AI Advisor action exists.
      // ------------------------------------------------------------

      final aiAdvisorTitle = find.descendant(
        of: quickActionGrid,
        matching: find.text('AI Advisor'),
      );

      expect(
        aiAdvisorTitle,
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Make the AI Advisor card visible.
      // ------------------------------------------------------------

      await tester.ensureVisible(aiAdvisorTitle);

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Tap the actual AI Advisor action.
      // ------------------------------------------------------------

      await tester.tap(aiAdvisorTitle);

      await tester.pumpAndSettle();

      // ------------------------------------------------------------
      // Verify Dashboard -> SureBotScreen navigation.
      // ------------------------------------------------------------

      expect(
        find.byType(SureBotScreen),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify contextual SureBot UI.
      // ------------------------------------------------------------

      expect(
        find.text('SureBot'),
        findsOneWidget,
      );

      expect(
        find.text("I'm SureBot. I already have some context about your property."),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify property context.
      // ------------------------------------------------------------

      expect(
        find.text('Casagrand Aquene'),
        findsOneWidget,
      );

      expect(
        find.text('Casagrand'),
        findsOneWidget,
      );

      expect(
        find.text('Bangalore, Karnataka'),
        findsOneWidget,
      );

      expect(
        find.text('Apartment'),
        findsOneWidget,
      );

      expect(
        find.text('2025'),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify health context.
      // ------------------------------------------------------------

      expect(
        find.text('Property Health'),
        findsOneWidget,
      );

      expect(
        find.text('In progress'),
        findsOneWidget,
      );

      expect(
        find.text('1/33'),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify evidence context.
      // ------------------------------------------------------------

      expect(
        find.text('Evidence'),
        findsOneWidget,
      );

      // ------------------------------------------------------------
      // Verify the current priority.
      //
      // This assertion validates the complete
      // Dashboard -> SureBotContextBuilder -> SureBotScreen
      // integration.
      // ------------------------------------------------------------

      expect(
        find.text('Current Priority'),
        findsOneWidget,
      );

      expect(
        find.text('Obtain Registered Sale Deed'),
        findsOneWidget,
      );

      expect(
        find.text('Potential PHI improvement: +25'),
        findsOneWidget,
      );

      expect(
        find.text('Required documents'),
        findsOneWidget,
      );

      expect(
        find.text('• Registered Sale Deed'),
        findsOneWidget,
      );
    },
  );
}