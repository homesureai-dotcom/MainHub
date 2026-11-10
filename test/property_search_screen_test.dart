import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property/models/krera_project_models.dart';
import 'package:homesure_ai/features/property/services/property_repository.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/features/property_submission/services/property_submission_service.dart';
import 'package:homesure_ai/models/property.dart' as legacy;
import 'package:homesure_ai/screens/onboarding/property_search_screen.dart';

class FakePropertySubmissionGateway implements PropertySubmissionGateway {
  final List<Map<String, String>> submissions = [];
  bool shouldFail = false;

  @override
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
  }) async {
    if (shouldFail) {
      throw StateError('Test submission failure');
    }

    submissions.add({
      'name': name,
      'builder': builder,
      'locality': locality,
      'city': city,
      'reraNumber': reraNumber,
    });

    return 'test-submission-${submissions.length}';
  }
}

class FakePropertyCatalogueGateway extends PropertyCatalogueGateway {
  final List<legacy.Property> projects;
  bool shouldFail = false;

  FakePropertyCatalogueGateway({List<legacy.Property>? projects})
    : projects =
          projects ??
          const [
            legacy.Property(
              id: 'REG_PRM_KA_RERA_1251_446_PR_171010_000003',
              name: 'Godrej United',
              builder: 'United Oxygen Company Private Limited',
              city: 'Bengaluru',
              locality: 'Bengaluru East',
              reraNumber: 'PRM/KA/RERA/1251/446/PR/171010/000003',
              acknowledgementNumber: 'PR/KN/170729/000003',
              projectType: 'Residential/Group Housing',
              regulatoryStatus: 'APPROVED',
              verified: true,
            ),
            legacy.Property(
              id: 'REG_PRM_KA_RERA_1251_446_PR_190826_008878',
              name: 'Boulevard at Godrej Woodscapes',
              builder: 'GODREJ PROPERTIES LIMITED',
              city: 'Bengaluru',
              locality: 'Bengaluru East',
              reraNumber: 'PRM/KA/RERA/1251/446/PR/190826/008878',
              acknowledgementNumber: 'PR/KN/190826/008878',
              projectType: 'Residential/Group Housing',
              regulatoryStatus: 'APPROVED',
              verified: true,
            ),
            legacy.Property(
              id: 'REG_PRM_KA_RERA_1251_446_PR_170824_000057',
              name: 'PRESTIGE BOULEVARD',
              builder: 'Prestige Estates Projects Limited',
              city: 'Bengaluru',
              locality: 'Bengaluru East',
              reraNumber: 'PRM/KA/RERA/1251/446/PR/170824/000057',
              acknowledgementNumber: 'PR/KN/170726/000057',
              projectType: 'Residential/Group Housing',
              regulatoryStatus: 'APPROVED',
              verified: true,
            ),
          ];

  @override
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  }) async {
    if (shouldFail) {
      throw StateError('Firestore unavailable');
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return projects;
    return projects.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.builder.toLowerCase().contains(q) ||
          p.locality.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.reraNumber.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<legacy.Property?> fetchProjectById(String projectId) async {
    for (final p in projects) {
      if (p.id == projectId || p.reraNumber == projectId) return p;
    }
    return null;
  }

  @override
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  ) async {
    return ProjectRegulatoryDetailBundle(projectId: projectId);
  }

  @override
  Future<List<ProjectUnitRecord>> fetchProjectUnits(String projectId) async {
    return const [];
  }

  @override
  Future<ProjectUnitRecord> saveBuyerUnit({
    required String projectId,
    required String unitNumber,
    String? towerName,
    String? floorNumber,
    String? unitConfiguration,
    double? carpetAreaSqM,
  }) async {
    return ProjectUnitRecord(
      unitId: 'unit_test_$unitNumber',
      projectId: projectId,
      unitNumber: unitNumber,
      towerName: towerName,
      floorNumber: floorNumber,
      unitConfiguration: unitConfiguration,
      carpetAreaSqM: carpetAreaSqM,
      sourceType: EvidenceSourceType.buyerProvided,
    );
  }
}

void main() {
  group('PropertySearchScreen (Builder-First Flow)', () {
    late FakePropertySubmissionGateway gateway;
    late FakePropertyCatalogueGateway catalogueGateway;

    Future<void> pumpSearchScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PropertySearchScreen(
            submissionGateway: gateway,
            catalogueGateway: catalogueGateway,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('initially lists canonical builders with project counts', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      catalogueGateway = FakePropertyCatalogueGateway();
      await pumpSearchScreen(tester);

      expect(find.text('Builders in the catalogue'), findsOneWidget);
      expect(find.text('Godrej Properties'), findsOneWidget);
      expect(find.text('2 Projects'), findsOneWidget);
      expect(find.text('Prestige Group'), findsOneWidget);
      expect(find.text('1 Project'), findsOneWidget);
    });

    testWidgets('searches builders by builder name', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      catalogueGateway = FakePropertyCatalogueGateway();
      await pumpSearchScreen(tester);

      await tester.enterText(
        find.byType(TextField).first,
        'Godrej',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Godrej Properties'), findsOneWidget);
      expect(find.text('Prestige Group'), findsNothing);
    });

    testWidgets(
      'tapping a builder opens BuilderProjectsScreen and tapping a project opens PropertyDetailsScreen',
      (WidgetTester tester) async {
        gateway = FakePropertySubmissionGateway();
        catalogueGateway = FakePropertyCatalogueGateway();
        await pumpSearchScreen(tester);

        // 1. Tap on Godrej Properties builder card
        await tester.tap(find.text('Godrej Properties'));
        await tester.pumpAndSettle();

        // 2. Verify BuilderProjectsScreen lists all properties under Godrej Properties
        expect(find.text('2 Registered Projects'), findsOneWidget);
        expect(find.text('Select a Property'), findsOneWidget);
        expect(find.text('Godrej United'), findsOneWidget);
        expect(find.text('Boulevard at Godrej Woodscapes'), findsOneWidget);
        expect(find.text('Not yet assessed by HomeSureAI'), findsWidgets);

        // 3. Tap on Godrej United to open PropertyDetailsScreen
        await tester.tap(find.text('Godrej United'));
        await tester.pumpAndSettle();

        expect(
          PropertyState.instance.selectedProperty?.name,
          'Godrej United',
        );
        expect(
          find.text('PRM/KA/RERA/1251/446/PR/171010/000003'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows an empty state when no builder matches', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      catalogueGateway = FakePropertyCatalogueGateway();
      await pumpSearchScreen(tester);

      await tester.enterText(
        find.byType(TextField).first,
        'Builder That Does Not Exist',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No matching builder found'),
        findsOneWidget,
      );
      expect(find.text("My project isn't listed"), findsOneWidget);
    });

    testWidgets(
      'shows explicit error state with Retry and never falls back to demo projects when Firestore fails',
      (WidgetTester tester) async {
        gateway = FakePropertySubmissionGateway();
        catalogueGateway = FakePropertyCatalogueGateway()..shouldFail = true;
        await pumpSearchScreen(tester);

        expect(
          find.textContaining('Unable to load K-RERA builder catalogue:'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Casagrand Aquene'), findsNothing);
        expect(find.text('Prestige Lakeside Habitat'), findsNothing);
      },
    );

    testWidgets(
      'opens compact Not listed? sheet and submits an unlisted project',
      (WidgetTester tester) async {
        gateway = FakePropertySubmissionGateway();
        catalogueGateway = FakePropertyCatalogueGateway();
        await pumpSearchScreen(tester);

        await tester.tap(find.text('Not listed?'));
        await tester.pumpAndSettle();

        await tester.tap(find.text("My project isn't listed"));
        await tester.pumpAndSettle();

        expect(find.text('Enter your property'), findsOneWidget);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Green Valley Homes');
        await tester.enterText(fields.at(1), 'Example Builders');
        await tester.enterText(fields.at(2), 'Kengeri');
        await tester.enterText(fields.at(3), 'Bengaluru');
        await tester.enterText(fields.at(4), 'TEST-RERA-123');

        await tester.tap(find.text('Use property'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Property submitted for review. You can start an assessment '
            'after HomeSureAI approves it.',
          ),
          findsOneWidget,
        );

        expect(gateway.submissions, hasLength(1));
        expect(gateway.submissions.single['name'], 'Green Valley Homes');
        expect(gateway.submissions.single['builder'], 'Example Builders');
        expect(gateway.submissions.single['locality'], 'Kengeri');
        expect(gateway.submissions.single['city'], 'Bengaluru');
        expect(gateway.submissions.single['reraNumber'], 'TEST-RERA-123');
      },
    );

    testWidgets('shows an error when submission fails', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway()..shouldFail = true;
      catalogueGateway = FakePropertyCatalogueGateway();
      await pumpSearchScreen(tester);

      await tester.tap(find.text('Not listed?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("My project isn't listed"));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Green Valley Homes');
      await tester.enterText(fields.at(2), 'Kengeri');
      await tester.enterText(fields.at(3), 'Bengaluru');

      await tester.tap(find.text('Use property'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not submit property:'), findsOneWidget);
    });

    testWidgets('validates required fields in the manual property form', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      catalogueGateway = FakePropertyCatalogueGateway();
      await pumpSearchScreen(tester);

      await tester.tap(find.text('Not listed?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("My project isn't listed"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use property'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the project name'), findsOneWidget);
      expect(find.text('Enter the locality'), findsOneWidget);
    });
  });
}
