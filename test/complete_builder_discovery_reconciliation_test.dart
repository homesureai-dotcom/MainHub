// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property/models/krera_project_models.dart';
import 'package:homesure_ai/features/property/services/property_repository.dart';
import 'package:homesure_ai/features/property_submission/services/property_submission_service.dart';
import 'package:homesure_ai/models/property.dart' as legacy;
import 'package:homesure_ai/screens/onboarding/property_search_screen.dart';

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

class _FakeQueryDocSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  _FakeQueryDocSnapshot(this.id, this._data);

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Future<QuerySnapshot<Map<String, dynamic>>> Function() _loader;

  _FakeQuery(this._loader);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      _loader();
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
  final String? failBatchContainingId;

  _FakeCollectionRef(this.docs, {this.failBatchContainingId});

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final id = path ?? '';
    return _FakeDocRef(id, docs[id]);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (field == FieldPath.documentId && whereIn != null) {
      final ids = whereIn.map((e) => e.toString()).toList();
      return _FakeQuery(() async {
        if (failBatchContainingId != null && ids.contains(failBatchContainingId)) {
          throw Exception('Simulated transient Firestore batch error');
        }
        final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final id in ids) {
          final data = docs[id];
          if (data != null) {
            matched.add(_FakeQueryDocSnapshot(id, data));
          }
        }
        return _FakeQuerySnapshot(matched);
      });
    }
    return _FakeQuery(() async => _FakeQuerySnapshot(const []));
  }
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> collections;
  final String? failProjectsBatchContainingId;

  _FakeFirestore(this.collections, {this.failProjectsBatchContainingId});

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionRef(
      collections[collectionPath] ?? const {},
      failBatchContainingId:
          collectionPath == 'projects' ? failProjectsBatchContainingId : null,
    );
  }
}

class _NoopSubmissionGateway implements PropertySubmissionGateway {
  @override
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
    bool requestOnly = false,
  }) async =>
      'noop';
}

void main() {
  group('Complete Builder-to-Project Discovery Reconciliation', () {
    test('fetchBuilders probes chunks sequentially beyond chunk 3 even when _catalog_meta is missing', () async {
      final db = _FakeFirestore({
        'builders': {
          '_catalog_chunk_1': {
            'builders': [
              {'builder_id': 'b1', 'builder_name': 'Builder One', 'project_count': 1, 'projects': []},
            ],
          },
          '_catalog_chunk_2': {
            'builders': [
              {'builder_id': 'b2', 'builder_name': 'Builder Two', 'project_count': 1, 'projects': []},
            ],
          },
          '_catalog_chunk_3': {
            'builders': [
              {'builder_id': 'b3', 'builder_name': 'Builder Three', 'project_count': 1, 'projects': []},
            ],
          },
          '_catalog_chunk_4': {
            'builders': [
              {'builder_id': 'b4', 'builder_name': 'Builder Four', 'project_count': 1, 'projects': []},
            ],
          },
          '_catalog_chunk_5': {
            'builders': [
              {'builder_id': 'b5', 'builder_name': 'Builder Five', 'project_count': 1, 'projects': []},
            ],
          },
        },
      });

      final repo = PropertyRepository.withFirestore(db);
      final builders = await repo.fetchBuilders();
      expect(builders.map((b) => b.builderId), ['b5', 'b4', 'b1', 'b3', 'b2']);
    });

    test('fetchProjectsForBuilder retrieves both deep_extracted and catalogue_summary across >10 batches with batch-failure fallback', () async {
      final projectIds = List.generate(15, (i) => 'REG_P_${i + 1}');
      final projectDocs = <String, Map<String, dynamic>>{};
      final summaries = <Map<String, dynamic>>[];

      for (var i = 0; i < 15; i++) {
        final pid = projectIds[i];
        final isDeep = i < 5;
        final tier = isDeep ? 'deep_extracted' : 'catalogue_summary';
        final taluks = ['Anekal', 'Bengaluru East', 'Bengaluru North', 'Bengaluru South', 'Yelahanka'];
        final taluk = taluks[i % taluks.length];
        final doc = {
          'project_id': pid,
          'project_name': 'Builder Project ${i + 1}',
          'promoter_name': 'TEST BUILDER LTD',
          'builder_id': 'builder_test',
          'registration_number': 'PRM/KA/RERA/TEST/${i + 1}',
          'regulatory_status': 'APPROVED',
          'district': 'Bengaluru Urban',
          'taluk': taluk,
          'normalizedTaluk': taluk,
          'provenance': {'data_tier': tier},
        };
        projectDocs[pid] = doc;
        summaries.add({
          'project_id': pid,
          'project_name': 'Builder Project ${i + 1}',
          'promoter_name': 'TEST BUILDER LTD',
          'registration_number': 'PRM/KA/RERA/TEST/${i + 1}',
          'taluk': taluk,
          'normalized_taluk': taluk,
          'data_tier': tier,
        });
      }

      // Simulate batch #2 failing (REG_P_12 is in batch 11..15)
      final db = _FakeFirestore(
        {
          'builders': {
            '_catalog_meta': {
              'chunk_ids': ['_catalog_chunk_1'],
            },
            '_catalog_chunk_1': {
              'builders': [
                {
                  'builder_id': 'builder_test',
                  'builder_name': 'Test Builder',
                  'project_count': 15,
                  'project_ids': projectIds,
                  'projects': summaries,
                },
              ],
            },
          },
          'projects': projectDocs,
        },
        failProjectsBatchContainingId: 'REG_P_12',
      );

      final repo = PropertyRepository.withFirestore(db);
      final builders = await repo.fetchBuilders();
      expect(builders.length, 1);

      final props = await repo.fetchProjectsForBuilder(builders.first);
      expect(props.length, 15);
      expect(props.where((p) => p.isDeepExtracted).length, 5);
      expect(props.where((p) => p.isCatalogueSummary).length, 10);
      expect(props.map((p) => p.id).toSet(), projectIds.toSet());
    });

    test('All 5 canonical Bengaluru Urban taluks partition projects cleanly without drops', () {
      const talukInputs = [
        'Anekal',
        'Bengaluru East',
        'Bengaluru North',
        'Bengaluru South',
        'Yelahanka',
      ];
      final props = [
        for (var i = 0; i < talukInputs.length; i++)
          legacy.Property(
            id: 'p_$i',
            name: 'Project $i',
            builder: 'Promoter $i',
            city: 'Bengaluru',
            locality: talukInputs[i],
            normalizedTaluk: talukInputs[i],
            reraNumber: 'RERA_$i',
            dataTier: i.isEven ? 'deep_extracted' : 'catalogue_summary',
            verified: true,
          ),
      ];

      final filters = [
        BengaluruTalukFilter.anekal,
        BengaluruTalukFilter.east,
        BengaluruTalukFilter.north,
        BengaluruTalukFilter.south,
        BengaluruTalukFilter.yelahanka,
      ];

      final coveredIds = <String>{};
      for (var i = 0; i < filters.length; i++) {
        final matched = PropertyRepository.filterBuilderProjects(
          props,
          talukFilter: filters[i],
        );
        expect(matched.length, 1);
        expect(matched.single.id, 'p_$i');
        coveredIds.add(matched.single.id);
      }
      expect(coveredIds.length, 5);
    });

    test('groupProjectsIntoBuilders preserves dataTier, projectAliases, and normalizedTaluk', () {
      const deep = legacy.Property(
        id: 'p_deep',
        name: 'Assetz 63 Degree East - Tower A',
        officialProjectName: '63 Degree East - Tower A',
        normalizedProjectName: '63 DEGREE EAST TOWER A',
        projectAliases: ['ASSETZ 63 DEGREES EAST'],
        builder: 'APG Intelli Homes Private Limited',
        normalizedBuilderName: 'APG INTELLI',
        builderAliases: ['ASSETZ', 'ASSETZ PROPERTY GROUP'],
        city: 'Bengaluru',
        locality: 'Bengaluru East',
        normalizedTaluk: 'Bengaluru East',
        reraNumber: 'PRM/KA/RERA/1251/446/PR/240122/004656',
        dataTier: 'deep_extracted',
        verified: true,
      );
      const summary = legacy.Property(
        id: 'p_sum',
        name: 'Assetz Marq Phase 4',
        builder: 'Assetz Whitefield Homes Pvt Ltd',
        city: 'Bengaluru',
        locality: 'Bengaluru East',
        normalizedTaluk: 'Bengaluru East',
        reraNumber: 'PRM/KA/RERA/TEST/999',
        dataTier: 'catalogue_summary',
        verified: false,
      );

      final builders = PropertyRepository.groupProjectsIntoBuilders([deep, summary]);
      expect(builders.length, 1);
      final b = builders.single;
      expect(b.projects.length, 2);
      expect(b.projects.where((p) => p.dataTier == 'deep_extracted').length, 1);
      expect(b.projects.where((p) => p.dataTier == 'catalogue_summary').length, 1);
      expect(
        b.projects.firstWhere((p) => p.projectId == 'p_deep').projectAliases,
        contains('ASSETZ 63 DEGREES EAST'),
      );
      expect(
        PropertyRepository.propertyFromBuilderSummary(
          b.projects.firstWhere((p) => p.projectId == 'p_sum'),
        ).isCatalogueSummary,
        isTrue,
      );
    });

    testWidgets(
      'Navigating from taluk-filtered PropertySearchScreen retains builder projects in all taluks when filter is cleared in BuilderProjectsScreen',
      (tester) async {
        final db = _FakeFirestore({
          'builders': {
            '_catalog_meta': {
              'chunk_ids': ['_catalog_chunk_1'],
            },
            '_catalog_chunk_1': {
              'builders': [
                {
                  'builder_id': 'builder_sobha_limited',
                  'builder_name': 'Sobha Limited',
                  'is_featured_brand': true,
                  'project_count': 2,
                  'localities': ['Anekal', 'Bengaluru East'],
                  'project_ids': ['P_ANEKAL', 'P_EAST'],
                  'projects': [
                    {
                      'project_id': 'P_ANEKAL',
                      'project_name': 'Sobha Brooklyn Towers Phase 1',
                      'promoter_name': 'SOBHA LIMITED',
                      'registration_number': 'PRM/KA/RERA/ANEKAL/001',
                      'taluk': 'Anekal',
                      'normalized_taluk': 'Anekal',
                      'data_tier': 'deep_extracted',
                    },
                    {
                      'project_id': 'P_EAST',
                      'project_name': 'Sobha Neopolis Phase 1',
                      'promoter_name': 'SOBHA LIMITED',
                      'registration_number': 'PRM/KA/RERA/EAST/002',
                      'taluk': 'Bengaluru East',
                      'normalized_taluk': 'Bengaluru East',
                      'data_tier': 'catalogue_summary',
                    },
                  ],
                },
              ],
            },
          },
          'projects': {
            'P_ANEKAL': {
              'project_id': 'P_ANEKAL',
              'project_name': 'Sobha Brooklyn Towers Phase 1',
              'promoter_name': 'SOBHA LIMITED',
              'builder_id': 'builder_sobha_limited',
              'registration_number': 'PRM/KA/RERA/ANEKAL/001',
              'regulatory_status': 'APPROVED',
              'taluk': 'Anekal',
              'normalizedTaluk': 'Anekal',
              'provenance': {'data_tier': 'deep_extracted'},
            },
            'P_EAST': {
              'project_id': 'P_EAST',
              'project_name': 'Sobha Neopolis Phase 1',
              'promoter_name': 'SOBHA LIMITED',
              'builder_id': 'builder_sobha_limited',
              'registration_number': 'PRM/KA/RERA/EAST/002',
              'regulatory_status': 'APPROVED',
              'taluk': 'Bengaluru East',
              'normalizedTaluk': 'Bengaluru East',
              'provenance': {'data_tier': 'catalogue_summary'},
            },
          },
        });

        final repo = PropertyRepository.withFirestore(db);
        await tester.pumpWidget(
          MaterialApp(
            home: PropertySearchScreen(
              catalogueGateway: repo,
              submissionGateway: _NoopSubmissionGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 Builders'), findsOneWidget);
        expect(find.text('2 Projects'), findsOneWidget);

        // Apply Taluk: Anekal on Find Your Property screen
        await tester.tap(find.byKey(const ValueKey<String>('locality-filter-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('locality-filter-anekal')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('locality-filter-apply')));
        await tester.pumpAndSettle();

        expect(find.text('1 Project'), findsOneWidget);

        // Tap Sobha Limited -> BuilderProjectsScreen should show 1 of 2 initially
        await tester.tap(find.text('Sobha Limited'));
        await tester.pumpAndSettle();

        expect(find.text('Showing 1 of 2'), findsOneWidget);
        expect(find.text('Sobha Brooklyn Towers Phase 1'), findsOneWidget);
        expect(find.text('Sobha Neopolis Phase 1'), findsNothing);

        // Clear the taluk chip inside BuilderProjectsScreen -> both projects appear!
        await tester.tap(
          find.byKey(const ValueKey<String>('builder-locality-filter-clear-anekal')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Showing 2 of 2'), findsOneWidget);
        expect(find.text('Sobha Brooklyn Towers Phase 1'), findsOneWidget);
        expect(find.text('Sobha Neopolis Phase 1'), findsOneWidget);
        expect(find.text('Full K-RERA Dossier'), findsOneWidget);
        expect(find.text('Catalogue Summary'), findsOneWidget);
      },
    );

    test(
      'Phase 4.2G: _catalog_meta.updated_at invalidates stale builder cache and honors migrated builder_id & provisional flags',
      () async {
        final collections = <String, Map<String, Map<String, dynamic>>>{
          'builders': {
            '_catalog_meta': {
              'chunk_ids': ['_catalog_chunk_1'],
              'updated_at': '2026-11-22T00:00:00Z',
            },
            '_catalog_chunk_1': {
              'builders': [
                {
                  'builder_id': 'builder_vaishnavi_group',
                  'builder_name': 'Vaishnavi Group',
                  'project_count': 1,
                  'project_ids': ['REG_PRM_KA_RERA_1251_446_PR_270325_007631'],
                  'projects': [],
                },
              ],
            },
          },
          'projects': {},
        };

        final db = _FakeFirestore(collections);
        final repo = PropertyRepository.withFirestore(db);

        final initial = await repo.fetchBuilders();
        expect(initial.map((b) => b.builderId), ['builder_vaishnavi_group']);

        // Update _catalog_meta.updated_at and chunk_1 to Phase 4.2G migrated state
        collections['builders']!['_catalog_meta'] = {
          'chunk_ids': ['_catalog_chunk_1'],
          'updated_at': '2026-11-23T12:15:00Z',
        };
        collections['builders']!['_catalog_chunk_1'] = {
          'builders': [
            {
              'builder_id': 'builder_affinity_projects',
              'builder_name': 'Affinity Projects',
              'project_count': 1,
              'project_ids': ['REG_PRM_KA_RERA_1251_446_PR_270325_007631'],
              'projects': [],
              'provisional_identity': false,
            },
            {
              'builder_id': 'builder_affinity_projects_provisional_005163',
              'builder_name': 'Affinity Projects',
              'project_count': 1,
              'project_ids': ['REG_PRM_KA_RERA_1251_309_PR_180822_005163'],
              'projects': [],
              'provisional_identity': true,
              'identity_review_required': true,
              'identity_review_reason': 'FORM_A_CONTINUITY_NOT_VERIFIED',
            },
          ],
        };

        final refreshed = await repo.fetchBuilders();
        expect(
          refreshed.map((b) => b.builderId),
          [
            'builder_affinity_projects',
            'builder_affinity_projects_provisional_005163',
          ],
        );
        expect(refreshed[0].isProvisional, isFalse);
        expect(refreshed[1].isProvisional, isTrue);

        // Verify groupProjectsIntoBuilders honors migrated builder_id on Vaishnavi Harmony (007631)
        final vaishnaviHarmony = legacy.Property.fromFirestoreMap({
          'project_id': 'REG_PRM_KA_RERA_1251_446_PR_270325_007631',
          'project_name': 'Vaishnavi Harmony',
          'promoter_name': 'AFFINITY PROJECTS',
          'builder_id': 'builder_affinity_projects',
          'canonical_builder_name': 'Affinity Projects',
          'registration_number': 'PRM/KA/RERA/1251/446/PR/270325/007631',
          'taluk': 'Bengaluru East',
          'normalizedTaluk': 'Bengaluru East',
          'provenance': {'data_tier': 'deep_extracted'},
          'identity_verification': {'is_verified': true},
        });
        final grouped = PropertyRepository.groupProjectsIntoBuilders([
          vaishnaviHarmony,
        ]);
        expect(grouped.single.builderId, 'builder_affinity_projects');
        expect(grouped.single.builderName, 'Affinity Projects');
      },
    );

    testWidgets(
      'Phase 4.2G UI: PropertySearchScreen and BuilderProjectsScreen render Provisional Identity and Canonical Builder badges cleanly',
      (WidgetTester tester) async {
        final db = _FakeFirestore({
          'builders': {
            '_catalog_meta': {
              'chunk_ids': ['_catalog_chunk_1'],
              'updated_at': '2026-11-23T12:17:00Z',
            },
            '_catalog_chunk_1': {
              'builders': [
                {
                  'builder_id': 'builder_rajiv_gandhi_housing',
                  'builder_name': 'Rajiv Gandhi Housing Corporation Limited',
                  'project_count': 1,
                  'localities': ['Anekal'],
                  'project_ids': ['REG_PRM_KA_RERA_1251_308_PR_210702_004171'],
                  'projects': [
                    {
                      'project_id': 'REG_PRM_KA_RERA_1251_308_PR_210702_004171',
                      'project_name':
                          '1 Lakh Multi Storey Bengaluru Housing Programme',
                      'promoter_name':
                          'Rajiv Gandhi Housing Corporation Limlted',
                      'registration_number':
                          'PRM/KA/RERA/1251/308/PR/210702/004171',
                      'taluk': 'Anekal',
                      'normalized_taluk': 'Anekal',
                      'data_tier': 'deep_extracted',
                    },
                  ],
                  'provisional_identity': false,
                },
                {
                  'builder_id': 'builder_affinity_projects_provisional_005163',
                  'builder_name': 'Affinity Projects (005163)',
                  'project_count': 1,
                  'localities': ['Bengaluru North'],
                  'project_ids': ['REG_PRM_KA_RERA_1251_309_PR_180822_005163'],
                  'projects': [
                    {
                      'project_id': 'REG_PRM_KA_RERA_1251_309_PR_180822_005163',
                      'project_name': 'AFFINITY BRUNDAAVANA',
                      'promoter_name': 'AFFINITY PROJECTS',
                      'registration_number':
                          'PRM/KA/RERA/1251/309/PR/180822/005163',
                      'taluk': 'Bengaluru North',
                      'normalized_taluk': 'Bengaluru North',
                      'data_tier': 'catalogue_summary',
                    },
                  ],
                  'provisional_identity': true,
                  'identity_review_required': true,
                },
              ],
            },
          },
          'projects': {
            'REG_PRM_KA_RERA_1251_308_PR_210702_004171': {
              'project_id': 'REG_PRM_KA_RERA_1251_308_PR_210702_004171',
              'project_name': '1 Lakh Multi Storey Bengaluru Housing Programme',
              'promoter_name': 'Rajiv Gandhi Housing Corporation Limlted',
              'builder_id': 'builder_rajiv_gandhi_housing',
              'canonical_builder_name':
                  'Rajiv Gandhi Housing Corporation Limited',
              'registration_number': 'PRM/KA/RERA/1251/308/PR/210702/004171',
              'regulatory_status': 'APPROVED',
              'taluk': 'Anekal',
              'normalizedTaluk': 'Anekal',
              'provenance': {'data_tier': 'deep_extracted'},
            },
            'REG_PRM_KA_RERA_1251_309_PR_180822_005163': {
              'project_id': 'REG_PRM_KA_RERA_1251_309_PR_180822_005163',
              'project_name': 'AFFINITY BRUNDAAVANA',
              'promoter_name': 'AFFINITY PROJECTS',
              'builder_id': 'builder_affinity_projects_provisional_005163',
              'canonical_builder_name': 'Affinity Projects',
              'needsManualReview': true,
              'registration_number': 'PRM/KA/RERA/1251/309/PR/180822/005163',
              'regulatory_status': 'APPROVED',
              'taluk': 'Bengaluru North',
              'normalizedTaluk': 'Bengaluru North',
              'provenance': {'data_tier': 'catalogue_summary'},
            },
          },
        });

        final repo = PropertyRepository.withFirestore(db);
        await tester.pumpWidget(
          MaterialApp(
            home: PropertySearchScreen(
              catalogueGateway: repo,
              submissionGateway: _NoopSubmissionGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Rajiv Gandhi Housing Corporation Limited'),
          findsOneWidget,
        );
        expect(find.text('Affinity Projects (005163)'), findsOneWidget);
        expect(find.text('Provisional Identity'), findsOneWidget);

        // Open RGHCL builder projects screen -> verify exact official promoter spelling + Canonical Builder display
        await tester.tap(find.text('Rajiv Gandhi Housing Corporation Limited'));
        await tester.pumpAndSettle();

        expect(
          find.text('1 Lakh Multi Storey Bengaluru Housing Programme'),
          findsOneWidget,
        );
        expect(
          find.text('Rajiv Gandhi Housing Corporation Limlted'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Canonical Builder: Rajiv Gandhi Housing Corporation Limited',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PropertySearchScreen sorts builders alphabetically A to Z regardless of Firestore chunk order',
      (WidgetTester tester) async {
        final db = _FakeFirestore({
          'builders': {
            '_catalog_meta': {
              'chunk_ids': ['_catalog_chunk_1'],
            },
            '_catalog_chunk_1': {
              'builders': [
                {
                  'builder_id': 'b_z',
                  'builder_name': 'Zed Enterprises',
                  'project_count': 10,
                  'projects': [],
                },
                {
                  'builder_id': 'b_a',
                  'builder_name': 'Aashish Developers',
                  'project_count': 1,
                  'projects': [],
                },
                {
                  'builder_id': 'b_m',
                  'builder_name': 'Mantri Developers',
                  'project_count': 25,
                  'is_featured_brand': true,
                  'projects': [],
                },
              ],
            },
          },
          'projects': {},
        });

        final repo = PropertyRepository.withFirestore(db);
        await tester.pumpWidget(
          MaterialApp(
            home: PropertySearchScreen(
              catalogueGateway: repo,
              submissionGateway: _NoopSubmissionGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final aTop = tester.getTopLeft(find.text('Aashish Developers')).dy;
        final mTop = tester.getTopLeft(find.text('Mantri Developers')).dy;
        final zTop = tester.getTopLeft(find.text('Zed Enterprises')).dy;
        expect(aTop, lessThan(mTop));
        expect(mTop, lessThan(zTop));
      },
    );
  });
}
