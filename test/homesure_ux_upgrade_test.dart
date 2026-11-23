import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/localization/app_locale_controller.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/data/phs_questions.dart';
import 'package:homesure_ai/features/assessment/localization/assessment_content_translations.dart';
import 'package:homesure_ai/features/auth/state/user_profile_state.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/krera_project_models.dart';
import 'package:homesure_ai/features/property/models/property.dart' as feature;
import 'package:homesure_ai/features/property/services/property_repository.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/features/property_submission/services/property_submission_service.dart';
import 'package:homesure_ai/models/property.dart' as legacy;
import 'package:homesure_ai/screens/assessment/assessment_screen.dart';
import 'package:homesure_ai/screens/assessment/surebot_screen.dart';
import 'package:homesure_ai/screens/home_screen_v2.dart';
import 'package:homesure_ai/screens/main_shell.dart';
import 'package:homesure_ai/screens/onboarding/property_search_screen.dart';
import 'package:homesure_ai/screens/property/property_details_screen.dart';
import 'package:homesure_ai/state/assessment_state.dart';

class _NoopSubmissionGateway implements PropertySubmissionGateway {
  @override
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
  }) async =>
      'noop';
}

class _TalukCatalogueGateway extends PropertyCatalogueGateway {
  final List<legacy.Property> projects;
  final ProjectRegulatoryDetailBundle? detailBundle;

  _TalukCatalogueGateway({
    required this.projects,
    this.detailBundle,
  });

  @override
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  }) async {
    return projects;
  }

  @override
  Future<legacy.Property?> fetchProjectById(String projectId) async {
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  @override
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  ) async {
    return detailBundle ?? ProjectRegulatoryDetailBundle(projectId: projectId);
  }

  @override
  Future<List<ProjectUnitRecord>> fetchProjectUnits(String projectId) async =>
      const [];

  @override
  Future<ProjectUnitRecord> saveBuyerUnit({
    required String projectId,
    required String unitNumber,
    String? towerName,
    String? floorNumber,
    String? unitConfiguration,
    double? carpetAreaSqM,
    String? existingUnitId,
  }) async {
    return ProjectUnitRecord(
      unitId: 'u1',
      projectId: projectId,
      unitNumber: unitNumber,
      sourceType: EvidenceSourceType.buyerProvided,
    );
  }
}

void main() {
  setUp(() async {
    await AppLocaleController.instance.setLanguage('en');
    AssessmentState.instance.clearAssessment();
    SureBotConversationHistory.clear();
    PropertyState.instance.clear();
    UserProfileState.instance.clear();
  });

  tearDown(() {
    AssessmentState.instance.clearAssessment();
    SureBotConversationHistory.clear();
    PropertyState.instance.clear();
    UserProfileState.instance.clear();
  });

  group('Navigation & Floating SureBot Assistant', () {
    testWidgets(
      'MainShell has 5 tabs without AI tab and FloatingSureBotButton opens/dismisses/reopens with history',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainShell()));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, 5);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Properties'), findsOneWidget);
        expect(find.text('Health'), findsOneWidget);
        expect(find.text('Residents'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('AI'),
          ),
          findsNothing,
        );

        final floatingBtn = find.byKey(
          const ValueKey<String>('floating-surebot-button'),
        );
        expect(floatingBtn, findsOneWidget);

        await tester.tap(floatingBtn);
        await tester.pumpAndSettle();

        expect(find.text('SureBot'), findsOneWidget);
        final inputField = find.byType(TextField);
        expect(inputField, findsOneWidget);
        await tester.enterText(inputField, 'Check my score');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Check my score'), findsOneWidget);

        // Dismiss via leading close button and verify reopening preserves history.
        await tester.tap(find.byTooltip('Dismiss SureBot'));
        await tester.pumpAndSettle();
        expect(find.byType(MainShell), findsOneWidget);

        await tester.tap(floatingBtn);
        await tester.pumpAndSettle();
        expect(find.text('Check my score'), findsOneWidget);
      },
    );
  });

  group('Assessment Screen Live PHI Scoring & Preservation', () {
    testWidgets(
      'matches HTML pillar + stacked questions layout, recalculates live PHI on Yes/No/Unsure/Clear, and preserves explanation & 4 evidence options',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: AssessmentScreen()));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Classic / Premium toggle removed per HTML structure.
        expect(find.text('Classic'), findsNothing);
        expect(find.text('Premium'), findsNothing);
        expect(find.text('Assessment pillars'), findsOneWidget);
        expect(find.text('ACTIVE ASSESSMENT PILLAR'), findsOneWidget);

        // Multiple questions in the active pillar render vertically for scrolling.
        final legalQuestions = phsQuestions
            .where((q) => q.category == PHSCategory.legalOwnership)
            .toList();
        expect(legalQuestions.length, greaterThanOrEqualTo(2));
        expect(
          find.textContaining('QUESTION 1 OF ${legalQuestions.length}'),
          findsOneWidget,
        );
        expect(
          find.textContaining('QUESTION 2 OF ${legalQuestions.length}'),
          findsOneWidget,
        );

        final phiBadge = find.byKey(
          const ValueKey<String>('assessment-phi-top-right'),
        );
        expect(phiBadge, findsOneWidget);
        expect(
          find.descendant(of: phiBadge, matching: find.text('0 out of 100')),
          findsOneWidget,
        );

        final firstCard = find.byKey(
          ValueKey<String>('assessment-qcard-${legalQuestions.first.id}'),
        );
        expect(firstCard, findsOneWidget);

        // Yes -> 100 out of 100
        final yesBtn = find.descendant(
          of: firstCard,
          matching: find.text('Yes'),
        );
        await tester.ensureVisible(yesBtn);
        await tester.tap(yesBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: phiBadge, matching: find.text('100 out of 100')),
          findsOneWidget,
        );

        // Changing same question to No -> 0 out of 100 (no duplicate score)
        final noBtn = find.descendant(
          of: firstCard,
          matching: find.text('No'),
        );
        await tester.ensureVisible(noBtn);
        await tester.tap(noBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: phiBadge, matching: find.text('0 out of 100')),
          findsOneWidget,
        );

        // I'm Not Sure -> 50 out of 100
        final unsureBtn = find.descendant(
          of: firstCard,
          matching: find.text("I'm Not Sure"),
        );
        await tester.ensureVisible(unsureBtn);
        await tester.tap(unsureBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: phiBadge, matching: find.text('50 out of 100')),
          findsOneWidget,
        );

        // Clear answer -> back to 0 out of 100
        final clearBtn = find.descendant(
          of: firstCard,
          matching: find.text('Clear answer'),
        );
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: phiBadge, matching: find.text('0 out of 100')),
          findsOneWidget,
        );

        // Learn why this matters preserves exact existing text
        final expectedWhy = AssessmentContentTranslations(
          'en',
        ).whyItMatters(phsQuestions.first);
        final learnWhy = find.descendant(
          of: firstCard,
          matching: find.text('Learn why this matters'),
        );
        await tester.ensureVisible(learnWhy);
        await tester.tap(learnWhy);
        await tester.pumpAndSettle();
        expect(find.text(expectedWhy), findsOneWidget);
        await tester.tap(find.text('Back to question'));
        await tester.pumpAndSettle();

        // Add Evidence keeps all 4 options
        final addEvidence = find.descendant(
          of: firstCard,
          matching: find.text('Add Evidence'),
        );
        await tester.ensureVisible(addEvidence);
        await tester.tap(addEvidence);
        await tester.pumpAndSettle();
        final sheet = find.byType(BottomSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(of: sheet, matching: find.text('Document')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('Photograph')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('Video')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('Manual Entry')),
          findsOneWidget,
        );
      },
    );
  });

  group('Property Details Consolidation & Newly Exposed Firestore Fields', () {
    testWidgets(
      'displays 5 unified sections, newly mapped summary_metrics and regulatory sections without legacy tab clutter',
      (tester) async {
        final project = legacy.Property.fromFirestoreMap({
          'project_id': 'PRJ_AUDIT_1',
          'registration_number': 'PRM/KA/RERA/TEST/001',
          'project_name': 'Prestige Alpine Ridge',
          'promoter_name': 'Prestige Estates Projects Limited',
          'city': 'Bengaluru',
          'taluk': 'Yelahanka',
          'project_type': 'Residential/Group Housing',
          'regulatory_status': 'APPROVED',
          'summary_metrics': {
            'project_start_date': {
              'value': '01-02-2023',
              'raw_label': 'Project Start Date',
              'observation_state': 'present_with_data',
            },
            'total_project_cost_inr': {
              'value': '₹ 420 Cr',
              'raw_label': 'Total Project Cost',
              'observation_state': 'present_with_data',
            },
            'escrow_bank_name': {
              'value': 'HDFC Bank Ltd',
              'raw_label': 'Escrow Bank',
              'observation_state': 'present_with_data',
            },
          },
          'counts': {'total_documents': 1, 'total_complaints': 0},
        });

        final bundle = ProjectRegulatoryDetailBundle.fromMap({
          'key_sections': [
            {
              'tab_label': 'Promoter Details',
              'section_label': 'Promoter Capital Profile',
              'section_type': 'key_value',
              'observation_state': 'present_with_data',
              'field_count': 1,
              'table_row_count': 0,
              'document_count': 0,
              'fields': [
                {'raw_label': 'Entity Type', 'value': 'Public Limited'},
              ],
            },
          ],
          'regulatory_documents': [
            {
              'document_id': 'doc_plan',
              'project_id': 'PRJ_AUDIT_1',
              'document_category': 'Sanctioned Building Plan',
              'displayed_filename': 'plan_sanction.pdf',
              'has_downloadable_file': true,
              'observation_state': 'present_with_data',
              'source_tab': 'Uploaded Documents',
              'source_section': 'Plan Approval',
            },
          ],
        }, projectId: 'PRJ_AUDIT_1');

        final gateway = _TalukCatalogueGateway(
          projects: [project],
          detailBundle: bundle,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PropertyDetailsScreen(
              property: project,
              catalogueGateway: gateway,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Legal'), findsOneWidget);
        expect(find.text('Development'), findsOneWidget);
        expect(find.text('Documents'), findsOneWidget);
        expect(find.text('Issues'), findsOneWidget);
        expect(find.text('Location & Land'), findsNothing);
        expect(find.text('My Apartment'), findsNothing);

        expect(find.text('01-02-2023'), findsOneWidget);
        expect(find.text('₹ 420 Cr'), findsOneWidget);
        expect(find.text('HDFC Bank Ltd'), findsOneWidget);
        expect(find.text('Promoter Capital Profile'), findsOneWidget);
        expect(find.text('Sanctioned Building Plan'), findsOneWidget);
        expect(
          find.text('No registered K-RERA complaints found on this project.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Bengaluru Taluk Locality Filters', () {
    test('normalizes taluk variants accurately', () {
      expect(
        BengaluruTalukFilter.normalize('Anekal'),
        BengaluruTalukFilter.anekal,
      );
      expect(
        BengaluruTalukFilter.normalize('Bengaluru East'),
        BengaluruTalukFilter.east,
      );
      expect(
        BengaluruTalukFilter.normalize('Bangalore North'),
        BengaluruTalukFilter.north,
      );
      expect(
        BengaluruTalukFilter.normalize('Bengaluru South'),
        BengaluruTalukFilter.south,
      );
      expect(
        BengaluruTalukFilter.normalize('Yelahanka'),
        BengaluruTalukFilter.yelahanka,
      );
    });

    testWidgets(
      'opens filter modal from Filters button, supports multi-select taluks staged until Apply, filters 2 and 3 taluks together, and combines with search query',
      (tester) async {
        final gateway = _TalukCatalogueGateway(
          projects: const [
            legacy.Property(
              id: 'p_anekal',
              name: 'Alpine Greens',
              builder: 'Alpine Developers Pvt Ltd',
              city: 'Bengaluru',
              locality: 'Anekal',
              reraNumber: 'RERA/ANEKAL/1',
              verified: true,
            ),
            legacy.Property(
              id: 'p_east',
              name: 'Godrej Woods',
              builder: 'GODREJ PROPERTIES LIMITED',
              city: 'Bengaluru',
              locality: 'Bengaluru East',
              reraNumber: 'RERA/EAST/1',
              verified: true,
            ),
            legacy.Property(
              id: 'p_north',
              name: 'North Crest',
              builder: 'Northcrest Builders',
              city: 'Bengaluru',
              locality: 'Bengaluru North',
              reraNumber: 'RERA/NORTH/1',
              verified: true,
            ),
            legacy.Property(
              id: 'p_south',
              name: 'South Park',
              builder: 'Southpark Homes',
              city: 'Bengaluru',
              locality: 'Bengaluru South',
              reraNumber: 'RERA/SOUTH/1',
              verified: true,
            ),
            legacy.Property(
              id: 'p_yelahanka',
              name: 'Yelahanka Lakeview',
              builder: 'Lakeview Infra',
              city: 'Bengaluru',
              locality: 'Yelahanka',
              reraNumber: 'RERA/YEL/1',
              verified: true,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PropertySearchScreen(
              submissionGateway: _NoopSubmissionGateway(),
              catalogueGateway: gateway,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('5 Builders'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('locality-filter-anekal')),
          findsNothing,
        );

        // 1. Open modal, select Anekal + East simultaneously; list must wait for Apply.
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Filter Properties'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-anekal')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-east')),
        );
        await tester.pumpAndSettle();
        expect(find.text('5 Builders'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-apply')),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 Builders'), findsOneWidget);
        expect(find.text('Filters (2)'), findsOneWidget);
        expect(find.text('Alpine Developers Pvt Ltd'), findsOneWidget);
        expect(find.text('Godrej Properties'), findsOneWidget);
        expect(find.text('Northcrest Builders'), findsNothing);

        // 2. Re-open modal and also select North (Anekal + East + North = 3 builders).
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-north')),
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-apply')),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 Builders'), findsOneWidget);
        expect(find.text('Filters (3)'), findsOneWidget);
        expect(find.text('Alpine Developers Pvt Ltd'), findsOneWidget);
        expect(find.text('Godrej Properties'), findsOneWidget);
        expect(find.text('Northcrest Builders'), findsOneWidget);
        expect(find.text('Southpark Homes'), findsNothing);

        // 3. Combine active filters with mismatched search query -> empty + reset link.
        await tester.enterText(find.byType(TextField), 'Nonexistent');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(find.text('Show all localities'), findsOneWidget);

        // 4. Reset via modal back to All and clear query -> all 5 builders restored.
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-all')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('locality-filter-apply')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(find.text('5 Builders'), findsOneWidget);
      },
    );
  });

  group('Profile Personalisation, Property Context & Health Tab Guard', () {
    feature.Property sampleCanonicalProperty() {
      return feature.Property(
        id: 'PRJ_PERSIST_1',
        name: 'Godrej United',
        builderName: 'Godrej Properties',
        ownerName: '',
        address: const feature.Address(
          line1: 'Whitefield',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560066',
        ),
        type: feature.PropertyType.apartment,
        yearOfConstruction: 2022,
        carpetArea: 1450,
        totalUnits: 340,
        reraNumber: 'PRM/KA/RERA/TEST/003',
        compliance: const ComplianceSummary(
          verifiedCount: 10,
          pendingCount: 2,
          issueCount: 0,
          compliancePercentage: 83,
        ),
        assessment: const AssessmentSummary(),
        documents: const DocumentSummary(
          verifiedDocuments: 10,
          pendingDocuments: 2,
          missingDocuments: 0,
        ),
      );
    }

    testWidgets(
      'Health tab hides questions and prompts to select property until a property is selected',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AssessmentScreen(embeddedInTab: true)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('assessment-no-property-selected'),
          ),
          findsOneWidget,
        );
        expect(find.text('Select a Property First'), findsOneWidget);
        expect(find.textContaining('QUESTION 1 OF'), findsNothing);

        PropertyState.instance.selectProperty(sampleCanonicalProperty());
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('assessment-no-property-selected'),
          ),
          findsNothing,
        );
        expect(find.textContaining('QUESTION 1 OF'), findsOneWidget);
      },
    );

    testWidgets(
      'reflects user First/Last name and DOB across Home greeting, SureBot greeting, and editable Profile tab',
      (tester) async {
        UserProfileState.instance.setProfile(
          const UserProfileData(
            firstName: 'Aarav',
            lastName: 'Sharma',
            dateOfBirth: '15/08/1995',
            email: 'aarav@example.com',
          ),
        );
        PropertyState.instance.selectProperty(sampleCanonicalProperty());

        // 1. HomeScreenV2 displays the user's real name instead of Vinod.
        await tester.pumpWidget(const MaterialApp(home: HomeScreenV2()));
        await tester.pumpAndSettle();
        expect(find.text('Aarav Sharma'), findsOneWidget);
        expect(find.text('Vinod'), findsNothing);

        // 2. SureBot displays "Hi <FirstName> 👋".
        await tester.pumpWidget(
          const MaterialApp(home: SureBotScreen(openAsAssistant: true)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hi Aarav 👋'), findsOneWidget);

        // 3. Profile tab displays Name & DOB and Edit sheet updates UserProfileState live.
        PropertyState.instance.clear();
        await tester.pumpWidget(const MaterialApp(home: MainShell()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Aarav Sharma'), findsOneWidget);
        expect(find.text('DOB: 15/08/1995'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('profile-edit-button')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey<String>('profile-edit-first-name')),
          'Rohan',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('profile-edit-save')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rohan Sharma'), findsOneWidget);
        expect(UserProfileState.instance.firstNameOrDisplay, 'Rohan');
      },
    );

    test('Property.toPersistenceMap and fromPersistenceMap round-trip cleanly', () {
      final original = sampleCanonicalProperty();
      final decoded = feature.Property.fromPersistenceMap(
        original.toPersistenceMap(),
      );
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.builderName, original.builderName);
      expect(decoded.address.city, original.address.city);
      expect(decoded.reraNumber, original.reraNumber);
      expect(decoded.totalUnits, original.totalUnits);
    });
  });
}
