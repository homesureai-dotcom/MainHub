// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property/models/krera_project_models.dart';
import 'package:homesure_ai/features/property/services/property_repository.dart';
import 'package:homesure_ai/models/property.dart' as legacy;
import 'package:homesure_ai/screens/property/property_details_screen.dart';
import 'package:homesure_ai/widgets/property/property_card.dart';

class _TestCatalogueGateway extends PropertyCatalogueGateway {
  final legacy.Property? hydratedProject;
  int detailBundleCalls = 0;

  _TestCatalogueGateway({this.hydratedProject});

  @override
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  }) async =>
      const [];

  @override
  Future<legacy.Property?> fetchProjectById(String projectId) async =>
      hydratedProject;

  @override
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  ) async {
    detailBundleCalls += 1;
    return null;
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
  }) async {
    throw UnimplementedError();
  }
}

class _FakeDocSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  _FakeDocSnapshot(this.id, this._data);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String docId;
  final Map<String, dynamic>? _data;

  _FakeDocRef(this.docId, this._data);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _FakeDocSnapshot(docId, _data);
}

class _FakeCollectionRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> docs;

  _FakeCollectionRef(this.docs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final id = path ?? '';
    return _FakeDocRef(id, docs[id]);
  }
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> collections;

  _FakeFirestore(this.collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionRef(collections[collectionPath] ?? const {});
  }
}

void main() {
  group('Phase 4 Name Normalization & Brand Disambiguation', () {
    test('normalizeSearchText handles &, &amp;, degree/degrees, punctuation', () {
      expect(normalizeSearchText('ASSETZ REN &amp; REI'), 'assetz ren and rei');
      expect(normalizeSearchText('Ren & Rei'), 'ren and rei');
      expect(normalizeSearchText('63 Degrees, Sarjapur'), '63 degree sarjapur');
      expect(normalizeSearchText('63 Degree East - Tower A'), '63 degree east tower a');
    });

    test('resolveCanonicalBrand prevents Sobha Rani & Pride false positives while catching APG Assetz SPVs', () {
      final sobhaCorp = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: 'SOBHA LIMITED',
        projectName: 'Sobha Neopolis Phase 1',
      );
      expect(sobhaCorp.id, 'builder_sobha_limited');
      expect(sobhaCorp.isBrand, isTrue);

      final sobhaRani = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: 'SOBHA RANI',
        projectName: 'ADITHYA HOMES ELITE',
      );
      expect(sobhaRani.id, isNot('builder_sobha_limited'));
      expect(sobhaRani.isBrand, isFalse);

      final apg63 = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: 'APG Intelli Homes Private Limited',
        projectName: '63 Degree East - Tower A',
      );
      expect(apg63.id, 'builder_assetz_group');
      expect(apg63.isBrand, isTrue);

      final fakePride = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: 'lnsinfra',
        projectName: 'GS LNS PRIDE',
      );
      expect(fakePride.id, isNot('builder_pride_group'));
    });

    test('matchesSearchQuery & filterBuilderProjects handle Assetz 63 Degree East and Ren & Rei aliases', () {
      final assetz = BuilderCatalogueEntry.fromMap({
        'builder_id': 'builder_assetz_group',
        'builder_name': 'Assetz Property Group',
        'normalized_builder_name': 'ASSETZ',
        'builder_aliases': ['ASSETZ', 'ASSETZ PROPERTY GROUP', 'APG'],
        'is_featured_brand': true,
        'project_count': 2,
        'legal_promoter_names': [
          'APG Intelli Homes Private Limited',
          'APG PREMIUM RESIDENTIAL PRIVATE LIMITED',
        ],
        'localities': ['Bengaluru East'],
        'project_ids': ['p_63', 'p_ren'],
        'projects': [
          {
            'project_id': 'p_63',
            'project_name': '63 Degree East - Tower A',
            'official_project_name': '63 Degree East - Tower A',
            'normalized_project_name': '63 DEGREE EAST TOWER A',
            'project_aliases': [
              'ASSETZ 63 DEGREE EAST',
              'ASSETZ 63 DEGREES EAST',
              '63 DEGREES EAST',
            ],
            'promoter_name': 'APG Intelli Homes Private Limited',
            'taluk': 'Bengaluru East',
            'normalized_taluk': 'Bengaluru East',
          },
          {
            'project_id': 'p_ren',
            'project_name': 'ASSETZ REN & REI',
            'official_project_name': 'ASSETZ REN & REI',
            'normalized_project_name': 'ASSETZ REN AND REI',
            'project_aliases': ['ASSETZ REN AND REI', 'REN AND REI', 'REN & REI'],
            'promoter_name': 'APG PREMIUM RESIDENTIAL PRIVATE LIMITED',
            'taluk': 'Bengaluru East',
            'normalized_taluk': 'Bengaluru East',
          },
        ],
      });

      expect(assetz.matchesSearchQuery('Assetz 63 Degree East'), isTrue);
      expect(assetz.matchesSearchQuery('63 Degrees'), isTrue);
      expect(assetz.matchesSearchQuery('Ren and Rei'), isTrue);
      expect(assetz.matchesSearchQuery('REN & REI'), isTrue);

      final props = assetz.projects
          .map(PropertyRepository.propertyFromBuilderSummary)
          .toList();
      expect(
        PropertyRepository.filterBuilderProjects(
          props,
          searchQuery: '63 Degrees',
        ).map((e) => e.id),
        ['p_63'],
      );
      expect(
        PropertyRepository.filterBuilderProjects(
          props,
          searchQuery: 'ren and rei',
        ).map((e) => e.id),
        ['p_ren'],
      );
    });
  });

  group('Phase 4 Dynamic Multi-Chunk Builder Loading & 5-Taluk Filter', () {
    test('fetchBuilders loads all chunks listed in _catalog_meta beyond chunk 3', () async {
      final fakeDb = _FakeFirestore({
        'builders': {
          '_catalog_meta': {
            'meta_id': '_catalog_meta',
            'total_chunks': 5,
            'chunk_ids': [
              '_catalog_chunk_1',
              '_catalog_chunk_2',
              '_catalog_chunk_3',
              '_catalog_chunk_4',
              '_catalog_chunk_5',
            ],
          },
          '_catalog_chunk_1': {
            'builders': [
              {'builder_id': 'b1', 'builder_name': 'Sobha Limited', 'project_count': 102, 'projects': []},
            ],
          },
          '_catalog_chunk_2': {'builders': []},
          '_catalog_chunk_3': {'builders': []},
          '_catalog_chunk_4': {
            'builders': [
              {'builder_id': 'b4', 'builder_name': 'Chunk Four Builder', 'project_count': 1, 'projects': []},
            ],
          },
          '_catalog_chunk_5': {
            'builders': [
              {'builder_id': 'b5', 'builder_name': 'Chunk Five Builder', 'project_count': 1, 'projects': []},
            ],
          },
        },
      });

      final repo = PropertyRepository.withFirestore(fakeDb);
      final builders = await repo.fetchBuilders();
      expect(builders.map((b) => b.builderId), containsAll(['b1', 'b4', 'b5']));
      expect(builders.length, 3);
    });

    test('BengaluruTalukFilter preserves Anekal and Yelahanka distinctly', () {
      const anekalProp = legacy.Property(
        id: 'p1',
        name: 'Brillio and Commercial at Brigade Valencia',
        builder: 'Brigade Enterprises Ltd',
        city: 'Bengaluru',
        locality: 'Anekal',
        normalizedTaluk: 'Anekal',
        verified: true,
      );
      const yelahankaProp = legacy.Property(
        id: 'p2',
        name: 'Assetz Zen & Sato',
        builder: 'APG TOWNSHIPS PRIVATE LIMITED',
        city: 'Bengaluru',
        locality: 'Yelahanka',
        normalizedTaluk: 'Yelahanka',
        verified: true,
      );
      expect(
        PropertyRepository.filterBuilderProjects(
          [anekalProp, yelahankaProp],
          talukFilters: {BengaluruTalukFilter.anekal},
        ).map((e) => e.id),
        ['p1'],
      );
      expect(
        PropertyRepository.filterBuilderProjects(
          [anekalProp, yelahankaProp],
          talukFilters: {BengaluruTalukFilter.yelahanka},
        ).map((e) => e.id),
        ['p2'],
      );
    });
  });

  group('Phase 4.1 Search Precision & False-Positive Regression Tests', () {
    test('normalizeSearchText handles apostrophes, &amp;, and and-amp', () {
      expect(normalizeSearchText("Park's Ridge"), 'parks ridge');
      expect(normalizeSearchText("Park&#39;s Ridge"), 'parks ridge');
      expect(normalizeSearchText('ren and amp'), 'ren and');
      expect(normalizeSearchText("Suyug's Saffron"), 'suyugs saffron');
      expect(normalizeSearchText('Suyugs Saffron'), 'suyugs saffron');
    });

    test('matchesSearchQuery & filterBuilderProjects avoid phase-number and substring false positives', () {
      final sobha = BuilderCatalogueEntry.fromMap({
        'builder_id': 'builder_sobha_limited',
        'builder_name': 'Sobha Limited',
        'normalized_builder_name': 'SOBHA',
        'builder_aliases': ['SOBHA', 'SOBHA LIMITED', 'SOBHA LTD'],
        'is_featured_brand': true,
        'project_count': 2,
        'projects': [
          {
            'project_id': 'neo1',
            'project_name': 'Sobha Neopolis Phase 1 - W 14, 15, 16, 17, 18 &19',
            'registration_number': 'PRM/KA/RERA/1251/446/PR/200923/006269',
            'promoter_name': 'SOBHA LIMITED',
            'taluk': 'Bengaluru East',
          },
          {
            'project_id': 'neo2',
            'project_name': 'Sobha Neopolis Phase 2 - W 12 & 13',
            'registration_number': 'PRM/KA/RERA/1251/446/PR/200923/006270',
            'promoter_name': 'SOBHA LIMITED',
            'taluk': 'Bengaluru East',
          },
        ],
      });
      final bren = BuilderCatalogueEntry.fromMap({
        'builder_id': 'builder_bren_corporation',
        'builder_name': 'Bren Corporation',
        'normalized_builder_name': 'BREN',
        'builder_aliases': ['BREN', 'BREN CORPORATION'],
        'is_featured_brand': true,
        'project_count': 1,
        'projects': [
          {
            'project_id': 'bren1',
            'project_name': 'BREN ZAHARA',
            'registration_number': 'PRM/KA/RERA/1251/446/PR/000001',
            'promoter_name': 'BREN CORPORATION',
            'taluk': 'Bengaluru East',
          },
        ],
      });
      final suyug = BuilderCatalogueEntry.fromMap({
        'builder_id': 'builder_suyug',
        'builder_name': 'Suyug Constructions',
        'normalized_builder_name': 'SUYUG',
        'builder_aliases': ['SUYUG CONSTRUCTIONS'],
        'project_count': 1,
        'projects': [
          {
            'project_id': 'suyug1',
            'project_name': "SUYUG'S SAFFRON",
            'registration_number': 'PRM/KA/RERA/1251/446/PR/000002',
            'promoter_name': 'Suyug Constructions',
            'taluk': 'Bengaluru East',
          },
        ],
      });

      final sobhaProps = sobha.projects
          .map(PropertyRepository.propertyFromBuilderSummary)
          .toList();
      // Exact numeric word matching ensures Phase 1 does NOT match Phase 2 or RERA '1251'
      expect(
        PropertyRepository.filterBuilderProjects(
          sobhaProps,
          searchQuery: 'Sobha Neopolis Phase 1',
        ).map((e) => e.id),
        ['neo1'],
      );
      expect(
        PropertyRepository.filterBuilderProjects(
          sobhaProps,
          searchQuery: 'Sobha Neopolis Phase 2',
        ).map((e) => e.id),
        ['neo2'],
      );

      // 'Ren & Rei' must not falsely match 'Bren Corporation'
      expect(bren.matchesSearchQuery('Ren & Rei'), isFalse);
      expect(bren.matchesSearchQuery('ren and amp'), isFalse);

      // Apostrophe equivalence & no cross-project token leakage
      expect(suyug.matchesSearchQuery('Suyugs Saffron'), isTrue);
      expect(sobha.matchesSearchQuery('Sobha Neopolis 006270'), isTrue);

      // filteredByTaluks retains normalizedBuilderName & builderAliases
      final filteredSobha = sobha.filteredByTaluks({BengaluruTalukFilter.east});
      expect(filteredSobha.normalizedBuilderName, 'SOBHA');
      expect(filteredSobha.builderAliases, contains('SOBHA LTD'));

      // Sattva tight project prefix prevents false-positive grouping
      final nonSattva = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: 'SRI SUMERU REALTY PRIVATE LIMITED',
        projectName: 'Sri Sri Sattva',
      );
      expect(nonSattva.id, isNot('builder_sattva_group'));
    });
  });

  group('Phase 4.1 Deep-Extracted vs Catalogue-Summary UI Separation', () {
    testWidgets('PropertyCard distinguishes Full K-RERA Dossier vs Catalogue Summary', (tester) async {
      const deepProp = legacy.Property(
        id: 'p_deep',
        name: 'Sobha Neopolis Phase 1',
        builder: 'SOBHA LIMITED',
        city: 'Bengaluru',
        locality: 'Bengaluru East',
        reraNumber: 'PRM/KA/RERA/1251/446/PR/200923/006269',
        regulatoryStatus: 'APPROVED',
        dataTier: 'deep_extracted',
        verified: true,
      );
      const catProp = legacy.Property(
        id: 'p_cat',
        name: 'Prestige Avon',
        builder: 'PRESTIGE ESTATES PROJECTS LTD',
        city: 'Bengaluru',
        locality: 'Bengaluru North',
        reraNumber: 'PRM/KA/RERA/1251/309/PR/131126/009097',
        regulatoryStatus: 'APPROVED',
        dataTier: 'catalogue_summary',
        verified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PropertyCard(property: deepProp, onTap: () {}),
                PropertyCard(property: catProp, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Full K-RERA Dossier'), findsOneWidget);
      expect(find.text('Inspect Dossier'), findsOneWidget);
      expect(find.text('Catalogue Summary'), findsOneWidget);
      expect(find.text('Detailed K-RERA extraction pending'), findsOneWidget);
      expect(find.text('View Summary'), findsOneWidget);
    });

    testWidgets('PropertyDetailsScreen never presents catalogue_summary as complete analysis or ready for PHI', (tester) async {
      const catProp = legacy.Property(
        id: 'p_cat',
        name: 'Prestige Avon',
        builder: 'PRESTIGE ESTATES PROJECTS LTD',
        city: 'Bengaluru',
        locality: 'Bengaluru North',
        reraNumber: 'PRM/KA/RERA/1251/309/PR/131126/009097',
        regulatoryStatus: 'APPROVED',
        approvedOn: '2026-11-13',
        proposedCompletionDate: '2030-12-31',
        dataTier: 'catalogue_summary',
        verified: false,
      );
      final gateway = _TestCatalogueGateway(hydratedProject: catProp);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(
            property: catProp,
            catalogueGateway: gateway,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should skip wasted bundle_all read for catalogue_summary projects
      expect(gateway.detailBundleCalls, 0);

      expect(find.text('K-RERA Catalogue Summary'), findsOneWidget);
      expect(
        find.text('Catalogue Summary Only — Detailed Regulatory Extraction Pending'),
        findsOneWidget,
      );
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Not Extracted'), findsNWidgets(2));
      expect(
        find.text('Property Health Assessment Unavailable (Catalogue Summary)'),
        findsOneWidget,
      );
      expect(
        find.text('Assessment Unavailable (Catalogue Summary)'),
        findsOneWidget,
      );
      expect(find.text('Portal Sections: Verified'), findsNothing);
      expect(
        find.text('No registered K-RERA complaints found on this project.'),
        findsNothing,
      );
    });
  });
}
