import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property/models/krera_project_models.dart';
import 'package:homesure_ai/features/property/models/property_adapter.dart';
import 'package:homesure_ai/features/property/services/property_repository.dart';
import 'package:homesure_ai/features/property/state/property_state.dart';
import 'package:homesure_ai/models/property.dart' as legacy;
import 'package:homesure_ai/screens/property/property_details_screen.dart';

class _TestCatalogueGateway extends PropertyCatalogueGateway {
  final legacy.Property project;
  final ProjectRegulatoryDetailBundle bundle;
  final List<ProjectUnitRecord> savedUnits = [];

  _TestCatalogueGateway({required this.project, required this.bundle});

  @override
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  }) async {
    return [project];
  }

  @override
  Future<legacy.Property?> fetchProjectById(String projectId) async {
    return projectId == project.id ? project : null;
  }

  @override
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  ) async {
    return projectId == project.id ? bundle : null;
  }

  @override
  Future<List<ProjectUnitRecord>> fetchProjectUnits(String projectId) async {
    return savedUnits;
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
    final record = ProjectUnitRecord(
      unitId: 'unit_buyer_$unitNumber',
      projectId: projectId,
      unitNumber: unitNumber,
      towerName: towerName,
      floorNumber: floorNumber,
      unitConfiguration: unitConfiguration,
      carpetAreaSqM: carpetAreaSqM,
      sourceType: EvidenceSourceType.buyerProvided,
      observationState: ObservationState.presentWithData,
    );
    savedUnits.add(record);
    return record;
  }
}

void main() {
  group('Phase 1 Canonical K-RERA Models & ObservationState', () {
    test('preserves all six ObservationState values without collapsing', () {
      expect(
        ObservationState.fromWire('present_with_data'),
        ObservationState.presentWithData,
      );
      expect(
        ObservationState.fromWire('present_empty'),
        ObservationState.presentEmpty,
      );
      expect(
        ObservationState.fromWire('not_present'),
        ObservationState.notPresent,
      );
      expect(
        ObservationState.fromWire('not_applicable'),
        ObservationState.notApplicable,
      );
      expect(
        ObservationState.fromWire('not_available'),
        ObservationState.notAvailable,
      );
      expect(
        ObservationState.fromWire('extraction_failed'),
        ObservationState.extractionFailed,
      );
    });

    test(
      'deserializes and round-trips canonical Firestore project document',
      () {
        final rawMap = <String, dynamic>{
          'project_id': 'REG_PRM_KA_RERA_1251_446_PR_171010_000003',
          'registration_number': 'PRM/KA/RERA/1251/446/PR/171010/000003',
          'acknowledgement_number': 'PR/KN/170729/000003',
          'project_name': 'Godrej United',
          'promoter_name': 'United Oxygen Company Private Limited',
          'city': 'Bengaluru',
          'taluk': 'Bengaluru East',
          'project_type': 'Residential/Group Housing',
          'regulatory_status': 'APPROVED',
          'approved_on_iso': '2017-10-10',
          'proposed_completion_date_iso': '2022-02-28',
          'project_start_date_iso': '2017-06-15',
          'summary_metrics': {
            'total_land_area_sq_m': {
              'value': 31808,
              'raw_value': '31808',
              'raw_label': 'Total Area Of Land (Sq Mtr)',
              'observation_state': 'present_with_data',
              'source_tab': 'Project Details',
              'source_section': 'Project Details',
            },
            'land_litigation_flag': {
              'value': null,
              'raw_value': null,
              'raw_label': 'Land Litigation Flag',
              'observation_state': 'not_present',
            },
          },
          'tab_observations_summary': {
            'Project Details': {
              'label': 'Project Details',
              'is_visible_tab': true,
              'observation_state': 'present_with_data',
              'section_count': 7,
              'field_count': 64,
              'table_count': 1,
              'document_count': 2,
            },
            'Quarterly Updates': {
              'label': 'Quarterly Updates',
              'is_visible_tab': true,
              'observation_state': 'present_empty',
              'section_count': 1,
              'field_count': 0,
              'table_count': 0,
              'document_count': 0,
            },
          },
          'inventory_configurations': [
            {
              'type_of_inventory': '1 BHK',
              'no_of_inventory': 51,
              'carpet_area_sq_m': '1919SqMtr',
              'source_type': 'KRERA_PORTAL',
              'observation_state': 'present_with_data',
            },
          ],
          'unit_hierarchy_status': {
            'phases_state': 'not_available',
            'towers_state': 'not_available',
            'towers_count': 0,
            'inventory_configs_state': 'present_with_data',
            'inventory_configs_count': 1,
            'portal_unit_rows_state': 'not_available',
            'portal_unit_rows_count': 0,
            'buyer_units_enabled': true,
          },
          'counts': {'total_documents': 91, 'total_complaints': 6},
          'provenance': {'source_type': 'KRERA_PORTAL'},
          'identity_verification': {'is_verified': true},
        };

        final prop = legacy.Property.fromFirestoreMap(rawMap);
        expect(prop.id, 'REG_PRM_KA_RERA_1251_446_PR_171010_000003');
        expect(prop.name, 'Godrej United');
        expect(prop.builder, 'United Oxygen Company Private Limited');
        expect(prop.locality, 'Bengaluru East');
        expect(prop.reraNumber, 'PRM/KA/RERA/1251/446/PR/171010/000003');
        expect(prop.acknowledgementNumber, 'PR/KN/170729/000003');
        expect(prop.regulatoryStatus, 'APPROVED');
        expect(prop.proposedCompletionDate, '2022-02-28');
        expect(
          prop.summaryMetrics['total_land_area_sq_m']?.formattedValue,
          '31808',
        );
        expect(
          prop.summaryMetrics['land_litigation_flag']?.observationState,
          ObservationState.notPresent,
        );
        expect(
          prop.tabObservations['Quarterly Updates']?.observationState,
          ObservationState.presentEmpty,
        );
        expect(prop.inventoryConfigurations.single.typeOfInventory, '1 BHK');
        expect(prop.inventoryConfigurations.single.numberOfInventory, 51);
        expect(
          prop.unitHierarchyStatus.towersState,
          ObservationState.notAvailable,
        );

        final canonical = PropertyAdapter.fromLegacy(prop);
        expect(canonical.id, prop.id);
        expect(canonical.reraNumber, prop.reraNumber);
        expect(canonical.yearOfConstruction, 2022);
        expect(canonical.documents.pendingDocuments, 91);
      },
    );
  });

  group('PropertyDetailsScreen K-RERA & Buyer Unit Integration', () {
    testWidgets(
      'displays K-RERA disclosures, tab observation states, and records buyer-provided unit',
      (WidgetTester tester) async {
        final sampleProject = legacy.Property.fromFirestoreMap({
          'project_id': 'REG_PRM_KA_RERA_1251_446_PR_171010_000003',
          'registration_number': 'PRM/KA/RERA/1251/446/PR/171010/000003',
          'acknowledgement_number': 'PR/KN/170729/000003',
          'project_name': 'Godrej United',
          'promoter_name': 'United Oxygen Company Private Limited',
          'city': 'Bengaluru',
          'taluk': 'Bengaluru East',
          'project_type': 'Residential/Group Housing',
          'regulatory_status': 'APPROVED',
          'approved_on_iso': '2017-10-10',
          'proposed_completion_date_iso': '2022-02-28',
          'summary_metrics': {
            'total_land_area_sq_m': {
              'value': '31808',
              'raw_label': 'Total Area Of Land (Sq Mtr)',
              'observation_state': 'present_with_data',
            },
            'approving_authority': {
              'value': 'BBMP - Bruhat Bengaluru Mahanagara Palike',
              'raw_label': 'Approving Authority',
              'observation_state': 'present_with_data',
            },
          },
          'tab_observations_summary': {
            'Project Details': {
              'label': 'Project Details',
              'is_visible_tab': true,
              'observation_state': 'present_with_data',
            },
            'Quarterly Updates': {
              'label': 'Quarterly Updates',
              'is_visible_tab': true,
              'observation_state': 'present_empty',
            },
          },
          'inventory_configurations': [
            {
              'type_of_inventory': '1 BHK',
              'no_of_inventory': 51,
              'source_type': 'KRERA_PORTAL',
              'observation_state': 'present_with_data',
            },
          ],
          'counts': {'total_documents': 2, 'total_complaints': 1},
          'provenance': {'source_type': 'KRERA_PORTAL'},
          'identity_verification': {'is_verified': true},
        });

        final sampleBundle = ProjectRegulatoryDetailBundle.fromMap({
          'regulatory_documents': [
            {
              'document_id': 'doc_0001',
              'project_id': sampleProject.id,
              'document_category': 'Commencement Certificate',
              'displayed_filename': 'cc.pdf',
              'source_url': '/download_jc?DOC_ID=123',
              'has_downloadable_file': true,
              'observation_state': 'present_with_data',
              'source_tab': 'Uploaded Documents',
              'source_section': 'Project Approval',
            },
          ],
          'complaints_records': [
            {
              'complaint_id': 'cmp_0001',
              'project_id': sampleProject.id,
              'complaint_scope': 'PROJECT',
              'section_label': 'Complaints On this Project',
              'complaint_number': 'CMP/211010/0008423',
              'complaint_subject': 'compensation for damages in the flat.',
              'complaint_status': 'DISPOSED AUTHORITY BENCH4',
              'observation_state': 'present_with_data',
            },
          ],
        }, projectId: sampleProject.id);

        final gateway = _TestCatalogueGateway(
          project: sampleProject,
          bundle: sampleBundle,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PropertyDetailsScreen(
              property: sampleProject,
              catalogueGateway: gateway,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Godrej United'), findsOneWidget);
        expect(
          find.text('PRM/KA/RERA/1251/446/PR/171010/000003'),
          findsOneWidget,
        );
        expect(find.text('PR/KN/170729/000003'), findsOneWidget);
        expect(find.text('31808'), findsOneWidget);
        expect(
          find.text('BBMP - Bruhat Bengaluru Mahanagara Palike'),
          findsOneWidget,
        );
        expect(find.text('1 BHK (51 units)'), findsOneWidget);
        expect(find.text('Published Empty in K-RERA'), findsOneWidget);

        // Specify a buyer unit
        final specifyBtn = find.text('Specify Apartment / Unit to Evaluate');
        await tester.ensureVisible(specifyBtn);
        await tester.tap(specifyBtn);
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Flat 402');
        await tester.enterText(fields.at(1), 'Tower A');
        await tester.enterText(fields.at(2), '4');
        await tester.enterText(fields.at(3), '3 BHK');
        await tester.enterText(fields.at(4), '145.5');

        await tester.tap(find.text('Save Unit'));
        await tester.pumpAndSettle();

        expect(find.text('Evaluating Unit: Flat 402'), findsOneWidget);
        expect(find.textContaining('Tower: Tower A'), findsOneWidget);
        expect(find.textContaining('Source: Buyer Provided'), findsOneWidget);
        expect(
          PropertyState.instance.selectedProperty?.selectedUnit?.unitNumber,
          'Flat 402',
        );
      },
    );
  });
}
