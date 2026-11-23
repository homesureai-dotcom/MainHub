import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/property.dart' as legacy;
import '../models/assessment_summary.dart';
import '../models/compliance_summary.dart';
import '../models/document_summary.dart';
import '../models/krera_project_models.dart';
import '../models/property.dart';
import '../models/property_adapter.dart';

/// Gateway abstraction for querying the canonical K-RERA property catalogue
/// and unit-level records from Cloud Firestore.
abstract class PropertyCatalogueGateway {
  /// Fetch initial or filtered projects from the `projects` collection.
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  });

  /// Fetch canonical builders/developers from the catalogue, optionally filtered
  /// by [searchQuery] (matching builder name, legal promoter entity, locality, or project name).
  Future<List<BuilderCatalogueEntry>> fetchBuilders({String searchQuery = ''}) async {
    final projects = await fetchCatalogueProjects(searchQuery: '', limit: 250);
    return PropertyRepository.groupProjectsIntoBuilders(
      projects,
      searchQuery: searchQuery,
    );
  }

  /// Fetch all K-RERA projects belonging to [builder], optionally filtered by [searchQuery].
  Future<List<legacy.Property>> fetchProjectsForBuilder(
    BuilderCatalogueEntry builder, {
    String searchQuery = '',
  }) async {
    final allProjects = await fetchCatalogueProjects(searchQuery: '', limit: 250);
    final idSet = builder.projectIds.toSet();
    final matched = allProjects.where((p) {
      if (idSet.contains(p.id)) return true;
      if (p.builderId.trim().isNotEmpty) {
        return p.builderId.trim() == builder.builderId;
      }
      final resolved = BuilderCatalogueEntry.resolveCanonicalBrand(
        promoterName: p.builder,
        projectName: p.name,
      );
      return resolved.id == builder.builderId;
    }).toList();
    return PropertyRepository.filterBuilderProjects(
      matched.isNotEmpty
          ? matched
          : builder.projects
                .map(
                  (s) => PropertyRepository.propertyFromBuilderSummary(
                    s,
                    builderId: builder.builderId,
                    canonicalBuilderName: builder.builderName,
                    needsManualReview: builder.isProvisional,
                  ),
                )
                .toList(),
      searchQuery: searchQuery,
    );
  }

  /// Fetch a single project by its deterministic `project_id` or RERA number.
  Future<legacy.Property?> fetchProjectById(String projectId);

  /// Fetch the deep regulatory detail bundle (`sections`, `documents`, `complaints`, `towers`)
  /// for a project from `projects/{projectId}/regulatory_tabs/bundle_all`.
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  );

  /// Fetch buyer-provided or portal unit records under `projects/{projectId}/units`.
  Future<List<ProjectUnitRecord>> fetchProjectUnits(String projectId);

  /// Save a buyer-provided unit evaluation record under `projects/{projectId}/units/{unitId}`.
  Future<ProjectUnitRecord> saveBuyerUnit({
    required String projectId,
    required String unitNumber,
    String? towerName,
    String? floorNumber,
    String? unitConfiguration,
    double? carpetAreaSqM,
  });
}

class PropertyRepository implements PropertyCatalogueGateway {
  PropertyRepository._({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestoreOverride = firestore,
      _authOverride = auth;

  /// Create a repository instance bound to a specific [FirebaseFirestore]
  /// (useful for unit tests with `FakeFirebaseFirestore`).
  factory PropertyRepository.withFirestore(
    FirebaseFirestore firestore, {
    FirebaseAuth? auth,
  }) {
    return PropertyRepository._(firestore: firestore, auth: auth);
  }

  static final PropertyRepository instance = PropertyRepository._();

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  /// In-memory cache of loaded catalogue projects for instant client-side filtering
  /// once initial catalogue batch is fetched.
  List<legacy.Property> _cachedCatalogue = [];

  /// In-memory cache of the canonical builders catalog loaded from `/builders`.
  List<BuilderCatalogueEntry> _cachedBuilders = [];

  /// Last observed `_catalog_meta.updated_at` timestamp so stale caches are invalidated automatically.
  String? _cachedCatalogUpdatedAt;

  Property _selectedProperty = const Property(
    id: 'UNSELECTED',
    name: 'No Project Selected',
    builderName: '',
    ownerName: '',
    address: Address(
      line1: '',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '',
    ),
    type: PropertyType.apartment,
    yearOfConstruction: 0,
    carpetArea: 0,
    totalUnits: 0,
    compliance: ComplianceSummary(
      verifiedCount: 0,
      pendingCount: 0,
      issueCount: 0,
      compliancePercentage: 0,
    ),
    assessment: AssessmentSummary(
      latestAssessment: null,
      lastAssessmentDate: null,
    ),
    documents: DocumentSummary(
      verifiedDocuments: 0,
      pendingDocuments: 0,
      missingDocuments: 0,
    ),
  );

  Property get selectedProperty => _selectedProperty;

  void selectProperty(Property property) {
    _selectedProperty = property;
  }

  void selectLegacyProperty(legacy.Property property) {
    _selectedProperty = PropertyAdapter.fromLegacy(property);
  }

  @override
  Future<List<legacy.Property>> fetchCatalogueProjects({
    String searchQuery = '',
    int limit = 60,
  }) async {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      final snapshot = await _firestore
          .collection('projects')
          .limit(limit)
          .get();

      final loaded = snapshot.docs
          .map((doc) => legacy.Property.fromFirestoreMap(doc.data(), documentId: doc.id))
          .toList();

      loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _cachedCatalogue = loaded;
      return loaded;
    }

    // Extract primary search token (normalized alphanumeric word >= 2 chars) for Firestore arrayContains
    final normQueryForTokens = normalizeSearchText(searchQuery);
    final tokens = (normQueryForTokens.isNotEmpty ? normQueryForTokens : normalizedQuery)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 2 && t != 'and')
        .toList();

    final resultsById = <String, legacy.Property>{};

    // 1. Check Firestore via search_tokens arrayContains for the most specific token
    if (tokens.isNotEmpty) {
      tokens.sort((a, b) => b.length.compareTo(a.length));
      final primaryToken = tokens.first.length > 8
          ? tokens.first
          : tokens.first;

      final tokenSnapshot = await _firestore
          .collection('projects')
          .where('search_metadata.search_tokens', arrayContains: primaryToken)
          .limit(limit)
          .get();

      for (final doc in tokenSnapshot.docs) {
        final prop = legacy.Property.fromFirestoreMap(
          doc.data(),
          documentId: doc.id,
        );
        if (_matchesQuery(prop, normalizedQuery)) {
          resultsById[prop.id] = prop;
        }
      }
    }

    // 2. Also check in-memory cached catalogue so multi-word or partial substring matches work seamlessly
    for (final cached in _cachedCatalogue) {
      if (_matchesQuery(cached, normalizedQuery)) {
        resultsById[cached.id] = cached;
      }
    }

    // 3. If still empty and query looks like a RERA number or substring, scan a broader batch
    if (resultsById.isEmpty) {
      final fallbackSnapshot = await _firestore
          .collection('projects')
          .limit(200)
          .get();
      for (final doc in fallbackSnapshot.docs) {
        final prop = legacy.Property.fromFirestoreMap(
          doc.data(),
          documentId: doc.id,
        );
        if (_matchesQuery(prop, normalizedQuery)) {
          resultsById[prop.id] = prop;
        }
      }
    }

    final results = resultsById.values.toList();
    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results;
  }

  /// Clears in-memory caches (useful after re-ingestion or in unit tests).
  void clearCaches() {
    _cachedCatalogue = [];
    _cachedBuilders = [];
    _cachedCatalogUpdatedAt = null;
  }

  @override
  Future<List<BuilderCatalogueEntry>> fetchBuilders({
    String searchQuery = '',
  }) async {
    final trimmed = searchQuery.trim();
    List<String> chunkIdsToFetch = const <String>[];
    String? latestMetaUpdatedAt;

    if (_cachedBuilders.isEmpty || trimmed.isEmpty) {
      try {
        final metaSnap =
            await _firestore.collection('builders').doc('_catalog_meta').get();
        if (metaSnap.exists && metaSnap.data() != null) {
          final meta = metaSnap.data()!;
          latestMetaUpdatedAt = meta['updated_at']?.toString();
          if (_cachedBuilders.isNotEmpty &&
              latestMetaUpdatedAt != null &&
              latestMetaUpdatedAt.isNotEmpty &&
              _cachedCatalogUpdatedAt != null &&
              latestMetaUpdatedAt != _cachedCatalogUpdatedAt) {
            clearCaches();
          }
          final rawChunkIds =
              (meta['chunk_ids'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
          if (rawChunkIds.isNotEmpty) {
            chunkIdsToFetch = rawChunkIds;
          } else {
            final totalChunks = (meta['total_chunks'] as num?)?.toInt() ?? 0;
            if (totalChunks > 0) {
              chunkIdsToFetch = List.generate(
                totalChunks,
                (idx) => '_catalog_chunk_${idx + 1}',
              );
            }
          }
        }
      } catch (_) {
        // Fall through to sequential chunk probing below when _catalog_meta is unavailable.
      }
    }

    if (_cachedBuilders.isEmpty) {
      final loadedFromChunks = <BuilderCatalogueEntry>[];
      void ingestChunkSnap(DocumentSnapshot<Map<String, dynamic>> chunk) {
        if (!chunk.exists || chunk.data() == null) return;
        final rawBuilders =
            (chunk.data()!['builders'] as List<dynamic>?) ?? const [];
        for (final item in rawBuilders) {
          if (item is Map) {
            loadedFromChunks.add(
              BuilderCatalogueEntry.fromMap(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      if (chunkIdsToFetch.isNotEmpty) {
        // 2a. Fetch all meta-declared canonical builder catalog chunks in parallel
        final chunkDocs = await Future.wait(
          chunkIdsToFetch.map(
            (id) => _firestore.collection('builders').doc(id).get(),
          ),
        );
        for (final chunk in chunkDocs) {
          ingestChunkSnap(chunk);
        }
      } else {
        // 2b. Sequential probing fallback when `_catalog_meta` is absent so chunks >= 4 are never dropped
        const int maxChunkProbe = 50;
        for (var chunkIdx = 1; chunkIdx <= maxChunkProbe; chunkIdx++) {
          final snap = await _firestore
              .collection('builders')
              .doc('_catalog_chunk_$chunkIdx')
              .get();
          if (!snap.exists || snap.data() == null) {
            break;
          }
          ingestChunkSnap(snap);
        }
      }

      if (loadedFromChunks.isNotEmpty) {
        _cachedBuilders = loadedFromChunks;
        _cachedCatalogUpdatedAt = latestMetaUpdatedAt;
      } else {
        // 3. Fallback: group projects from `/projects` collection dynamically
        final projects = await fetchCatalogueProjects(
          searchQuery: '',
          limit: 500,
        );
        _cachedBuilders = groupProjectsIntoBuilders(projects, searchQuery: '');
        _cachedCatalogUpdatedAt = latestMetaUpdatedAt;
      }
    }

    if (trimmed.isEmpty) {
      return List<BuilderCatalogueEntry>.unmodifiable(_cachedBuilders);
    }

    return _cachedBuilders
        .where((builder) => builder.matchesSearchQuery(trimmed))
        .toList();
  }

  @override
  Future<List<legacy.Property>> fetchProjectsForBuilder(
    BuilderCatalogueEntry builder, {
    String searchQuery = '',
  }) async {
    final loadedById = <String, legacy.Property>{};

    // Fetch full project documents in parallel batches of 10 from `/projects`
    // Fault-tolerant per batch so a single transient error falls back cleanly per ID.
    final ids = builder.projectIds.where((id) => id.trim().isNotEmpty).toList();
    final batchFutures = <Future<List<legacy.Property>>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final batchIds = ids.sublist(
        i,
        i + 10 > ids.length ? ids.length : i + 10,
      );
      batchFutures.add(() async {
        try {
          final snap = await _firestore
              .collection('projects')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          return snap.docs
              .map(
                (doc) => legacy.Property.fromFirestoreMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
              .toList();
        } catch (_) {
          return const <legacy.Property>[];
        }
      }());
    }
    if (batchFutures.isNotEmpty) {
      final batchResults = await Future.wait(batchFutures);
      for (final batchProps in batchResults) {
        for (final prop in batchProps) {
          loadedById[prop.id] = prop;
        }
      }
    }

    // For any project IDs not found in `/projects` (or if embedded summaries exist),
    // fallback to converting the embedded BuilderProjectSummary
    for (final summary in builder.projects) {
      if (!loadedById.containsKey(summary.projectId)) {
        loadedById[summary.projectId] = propertyFromBuilderSummary(
          summary,
          builderId: builder.builderId,
          canonicalBuilderName: builder.builderName,
          needsManualReview: builder.isProvisional,
        );
      }
    }

    final allBuilderProjects = loadedById.values.toList();
    allBuilderProjects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return filterBuilderProjects(allBuilderProjects, searchQuery: searchQuery);
  }

  /// Converts a lightweight [BuilderProjectSummary] into a [legacy.Property].
  static legacy.Property propertyFromBuilderSummary(
    BuilderProjectSummary summary, {
    String builderId = '',
    String canonicalBuilderName = '',
    bool needsManualReview = false,
  }) {
    return legacy.Property(
      id: summary.projectId,
      name: summary.projectName,
      builder: summary.promoterName,
      city: summary.city.isEmpty ? 'Bengaluru' : summary.city,
      locality: summary.taluk.isNotEmpty ? summary.taluk : summary.district,
      reraNumber: summary.registrationNumber,
      acknowledgementNumber: summary.acknowledgementNumber,
      projectType: summary.projectType,
      regulatoryStatus: summary.regulatoryStatus,
      approvedOn: summary.approvedOn,
      proposedCompletionDate: summary.proposedCompletionDate,
      projectStartDate: summary.projectStartDate,
      officialProjectName: summary.officialProjectName,
      normalizedProjectName: summary.normalizedProjectName,
      builderId: builderId,
      canonicalBuilderName: canonicalBuilderName,
      needsManualReview: needsManualReview,
      projectAliases: summary.projectAliases,
      normalizedTaluk: summary.normalizedTaluk,
      dataTier: summary.dataTier,
      regulatoryCounts: {
        'total_units': summary.totalUnits,
        'total_towers': summary.totalTowers,
      },
      verified: summary.registrationNumber.isNotEmpty,
    );
  }

  /// Groups a list of [legacy.Property] records into canonical [BuilderCatalogueEntry]
  /// records sorted by featured brand status, project count descending, and name.
  static List<BuilderCatalogueEntry> groupProjectsIntoBuilders(
    List<legacy.Property> projects, {
    String searchQuery = '',
  }) {
    final groups = <String, _BuilderGroupAccumulator>{};

    for (final p in projects) {
      final hasMigratedId = p.builderId.trim().isNotEmpty;
      final resolved = hasMigratedId
          ? (
              id: p.builderId.trim(),
              name: p.canonicalBuilderName.trim().isNotEmpty
                  ? p.canonicalBuilderName.trim()
                  : (p.normalizedBuilderName.trim().isNotEmpty
                      ? p.normalizedBuilderName.trim()
                      : p.builder.trim()),
              isBrand: false,
            )
          : BuilderCatalogueEntry.resolveCanonicalBrand(
              promoterName: p.builder,
              projectName: p.name,
            );
      final acc = groups.putIfAbsent(
        resolved.id,
        () => _BuilderGroupAccumulator(
          builderId: resolved.id,
          builderName: resolved.name,
          isFeaturedBrand: resolved.isBrand,
          provisionalIdentity: p.isProvisionalIdentity,
          identityReviewRequired: p.needsManualReview || p.isProvisionalIdentity,
        ),
      );
      if (p.isProvisionalIdentity) {
        acc.provisionalIdentity = true;
      }
      if (p.needsManualReview || p.isProvisionalIdentity) {
        acc.identityReviewRequired = true;
      }
      if (p.builder.trim().isNotEmpty) {
        acc.legalPromoters.add(p.builder.trim());
      }
      if (p.builderAliases.isNotEmpty) {
        acc.builderAliases.addAll(p.builderAliases);
      }
      if (p.normalizedBuilderName.trim().isNotEmpty &&
          acc.normalizedBuilderName.isEmpty) {
        acc.normalizedBuilderName = p.normalizedBuilderName.trim();
      }
      if (p.locality.trim().isNotEmpty) {
        acc.localities.add(p.locality.trim());
      }
      acc.projectIds.add(p.id);
      acc.projects.add(
        BuilderProjectSummary(
          projectId: p.id,
          projectName: p.name,
          officialProjectName: p.officialProjectName.isNotEmpty
              ? p.officialProjectName
              : p.name,
          normalizedProjectName: p.normalizedProjectName.isNotEmpty
              ? p.normalizedProjectName
              : normalizeSearchText(p.name).toUpperCase(),
          projectAliases: p.projectAliases,
          promoterName: p.builder,
          registrationNumber: p.reraNumber,
          acknowledgementNumber: p.acknowledgementNumber,
          projectType: p.projectType,
          regulatoryStatus: p.regulatoryStatus,
          taluk: p.locality,
          normalizedTaluk: p.normalizedTaluk.isNotEmpty
              ? p.normalizedTaluk
              : p.locality,
          city: p.city,
          approvedOn: p.approvedOn,
          proposedCompletionDate: p.proposedCompletionDate,
          projectStartDate: p.projectStartDate,
          totalUnits: p.regulatoryCounts['total_units'] ?? 0,
          totalTowers: p.towersSummary.length,
          dataTier: p.dataTier,
        ),
      );
    }

    final entries = groups.values.map((acc) {
      acc.projects.sort(
        (a, b) =>
            a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()),
      );
      return BuilderCatalogueEntry(
        builderId: acc.builderId,
        builderName: acc.builderName,
        normalizedBuilderName: acc.normalizedBuilderName.isNotEmpty
            ? acc.normalizedBuilderName
            : normalizeSearchText(acc.builderName).toUpperCase(),
        builderAliases: acc.builderAliases.toList()..sort(),
        isFeaturedBrand: acc.isFeaturedBrand,
        projectCount: acc.projects.length,
        legalPromoterNames: acc.legalPromoters.toList()..sort(),
        localities: acc.localities.toList()..sort(),
        projectIds: acc.projectIds,
        projects: acc.projects,
        provisionalIdentity: acc.provisionalIdentity,
        identityReviewRequired: acc.identityReviewRequired,
      );
    }).toList();

    entries.sort((a, b) {
      final aMajor = a.isFeaturedBrand || a.projectCount >= 2 ? 0 : 1;
      final bMajor = b.isFeaturedBrand || b.projectCount >= 2 ? 0 : 1;
      if (aMajor != bMajor) return aMajor.compareTo(bMajor);
      if (a.projectCount != b.projectCount) {
        return b.projectCount.compareTo(a.projectCount);
      }
      return a.builderName.toLowerCase().compareTo(b.builderName.toLowerCase());
    });

    final trimmed = searchQuery.trim();
    if (trimmed.isEmpty) return entries;
    return entries.where((b) => b.matchesSearchQuery(trimmed)).toList();
  }

  /// Returns `true` if [property] belongs to the given [talukFilter].
  static bool propertyMatchesTaluk(
    legacy.Property property,
    BengaluruTalukFilter talukFilter,
  ) {
    if (talukFilter == BengaluruTalukFilter.all) return true;
    if (property.normalizedTaluk.isNotEmpty &&
        talukFilter.matchesTaluk(property.normalizedTaluk)) {
      return true;
    }
    if (talukFilter.matchesTaluk(property.locality)) return true;
    final metricTaluk = property.summaryMetrics['taluk']?.formattedValue;
    return talukFilter.matchesTaluk(metricTaluk);
  }

  /// Returns `true` if [property] belongs to at least one filter in [talukFilters].
  static bool propertyMatchesTaluks(
    legacy.Property property,
    Set<BengaluruTalukFilter> talukFilters,
  ) {
    if (talukFilters.isEmpty ||
        talukFilters.contains(BengaluruTalukFilter.all)) {
      return true;
    }
    return talukFilters.any((f) => propertyMatchesTaluk(property, f));
  }

  /// Filters a builder's project list by optional [searchQuery] and taluk filters.
  static List<legacy.Property> filterBuilderProjects(
    List<legacy.Property> projects, {
    String searchQuery = '',
    BengaluruTalukFilter talukFilter = BengaluruTalukFilter.all,
    Set<BengaluruTalukFilter> talukFilters = const {},
  }) {
    final effectiveFilters = talukFilters.isNotEmpty
        ? talukFilters
        : (talukFilter == BengaluruTalukFilter.all
            ? const <BengaluruTalukFilter>{}
            : {talukFilter});
    final lower = searchQuery.trim().toLowerCase();
    final normQuery = normalizeSearchText(searchQuery);
    return projects.where((p) {
      if (!propertyMatchesTaluks(p, effectiveFilters)) {
        return false;
      }
      if (lower.isEmpty || normQuery.isEmpty) return true;
      return _matchesPropertyQuery(p, lower, normQuery);
    }).toList();
  }

  static bool _matchesPropertyQuery(
    legacy.Property property,
    String lowerQuery,
    String normQuery,
  ) {
    if (lowerQuery.isEmpty || normQuery.isEmpty) return true;
    final candidateText = [
      property.name,
      property.officialProjectName,
      property.normalizedProjectName,
      ...property.projectAliases,
      property.builder,
      property.officialBuilderName,
      property.normalizedBuilderName,
      ...property.builderAliases,
      property.locality,
      property.normalizedTaluk,
      property.city,
      property.projectType,
      property.reraNumber,
      property.acknowledgementNumber,
    ].where((e) => e.trim().isNotEmpty).join(' ');

    return matchesNormalizedSearchTokens(
      candidateText,
      lowerQuery,
      registrationNumber: property.reraNumber,
    );
  }

  bool _matchesQuery(legacy.Property property, String lowerQuery) {
    return _matchesPropertyQuery(
      property,
      lowerQuery,
      normalizeSearchText(lowerQuery),
    );
  }

  @override
  Future<legacy.Property?> fetchProjectById(String projectId) async {
    final trimmed = projectId.trim();
    if (trimmed.isEmpty) return null;

    final doc = await _firestore.collection('projects').doc(trimmed).get();
    if (doc.exists && doc.data() != null) {
      return legacy.Property.fromFirestoreMap(doc.data()!, documentId: doc.id);
    }

    // Fallback lookup by registration_number if caller passed a raw RERA registration number
    final byRera = await _firestore
        .collection('projects')
        .where('registration_number', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (byRera.docs.isNotEmpty) {
      final d = byRera.docs.first;
      return legacy.Property.fromFirestoreMap(d.data(), documentId: d.id);
    }

    return null;
  }

  @override
  Future<ProjectRegulatoryDetailBundle?> fetchProjectRegulatoryDetail(
    String projectId,
  ) async {
    final trimmed = projectId.trim();
    if (trimmed.isEmpty) return null;

    final bundleDoc = await _firestore
        .collection('projects')
        .doc(trimmed)
        .collection('regulatory_tabs')
        .doc('bundle_all')
        .get();

    if (bundleDoc.exists && bundleDoc.data() != null) {
      return ProjectRegulatoryDetailBundle.fromMap(
        bundleDoc.data()!,
        projectId: trimmed,
      );
    }
    return null;
  }

  @override
  Future<List<ProjectUnitRecord>> fetchProjectUnits(String projectId) async {
    final trimmed = projectId.trim();
    if (trimmed.isEmpty) return const [];

    final snapshot = await _firestore
        .collection('projects')
        .doc(trimmed)
        .collection('units')
        .get();

    return snapshot.docs
        .map((d) => ProjectUnitRecord.fromMap(d.data()))
        .toList();
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
    final userId = _auth.currentUser?.uid ?? 'anonymous_buyer';
    final sanitizedUnit = unitNumber
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final unitId = 'unit_${userId}_$sanitizedUnit';
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final record = ProjectUnitRecord(
      unitId: unitId,
      projectId: projectId,
      towerName: towerName?.trim().isEmpty == true ? null : towerName?.trim(),
      unitNumber: unitNumber.trim(),
      floorNumber: floorNumber?.trim().isEmpty == true
          ? null
          : floorNumber?.trim(),
      unitConfiguration: unitConfiguration?.trim().isEmpty == true
          ? null
          : unitConfiguration?.trim(),
      carpetAreaSqM: carpetAreaSqM,
      sourceType: EvidenceSourceType.buyerProvided,
      createdByUserId: userId,
      observationState: ObservationState.presentWithData,
      createdAtIso: nowIso,
    );

    if (_auth.currentUser != null) {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('units')
          .doc(unitId)
          .set(record.toMap());
    }

    return record;
  }
}

class _BuilderGroupAccumulator {
  final String builderId;
  final String builderName;
  final bool isFeaturedBrand;
  bool provisionalIdentity;
  bool identityReviewRequired;
  String normalizedBuilderName = '';
  final Set<String> builderAliases = {};
  final Set<String> legalPromoters = {};
  final Set<String> localities = {};
  final List<String> projectIds = [];
  final List<BuilderProjectSummary> projects = [];

  _BuilderGroupAccumulator({
    required this.builderId,
    required this.builderName,
    required this.isFeaturedBrand,
    this.provisionalIdentity = false,
    this.identityReviewRequired = false,
  });
}
