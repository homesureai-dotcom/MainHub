import '../features/property/models/krera_project_models.dart';

class Property {
  final String id;
  final String name;
  final String builder;
  final String city;

  /// Locality or neighbourhood (or K-RERA taluk) where the project is located.
  final String locality;

  /// RERA registration number, when available.
  final String reraNumber;

  /// K-RERA acknowledgement number, when available.
  final String acknowledgementNumber;

  /// Official K-RERA project type (`Residential/Group Housing`, `Plotted Development`, `Commercial`, etc.).
  final String projectType;

  /// Official K-RERA regulatory status (`APPROVED`, `EXTENDED`, `COMPLETED`, etc.).
  final String regulatoryStatus;

  /// Approved date (ISO `YYYY-MM-DD` or raw K-RERA date string).
  final String approvedOn;

  /// Proposed project completion date (ISO `YYYY-MM-DD` or raw K-RERA date string).
  final String proposedCompletionDate;

  /// Project start date (ISO `YYYY-MM-DD` or raw K-RERA date string).
  final String projectStartDate;

  /// Key K-RERA summary metrics with explicit [ObservationState].
  final Map<String, RegulatoryMetric> summaryMetrics;

  /// Summary of visible K-RERA tabs and their [ObservationState].
  final Map<String, RegulatoryTabSummary> tabObservations;

  /// Summary of unlinked K-RERA DOM panes and their [ObservationState].
  final Map<String, RegulatoryTabSummary> unlinkedPaneObservations;

  /// Registered inventory configurations (`1 BHK`, `2 BHK`, `3 BHK`, etc.) from K-RERA.
  final List<InventoryConfiguration> inventoryConfigurations;

  /// Registered towers/blocks from K-RERA.
  final List<ProjectTowerRecord> towersSummary;

  /// Unit-hierarchy availability status (`Project -> Phase -> Tower -> Unit`).
  final UnitHierarchyStatus unitHierarchyStatus;

  /// Aggregate counts from K-RERA (`total_documents`, `total_complaints`, `total_fields`, etc.).
  final Map<String, int> regulatoryCounts;

  /// Provenance source (`KRERA_PORTAL`, `BUYER_PROVIDED`, `SYSTEM_DERIVED`).
  final EvidenceSourceType sourceType;

  final int overallScore;
  final int legalScore;
  final int utilityScore;
  final int safetyScore;
  final int builderScore;

  /// Official portal project name and normalized canonical variant.
  final String officialProjectName;
  final String normalizedProjectName;

  /// Official portal promoter name and normalized canonical variant.
  final String officialBuilderName;
  final String normalizedBuilderName;

  /// Canonical/provisional builder ID (`builder_id`) and display name (`canonical_builder_name`).
  final String builderId;
  final String canonicalBuilderName;

  /// True when the project's promoter identity is retained provisionally pending review.
  final bool needsManualReview;

  bool get isProvisionalIdentity =>
      needsManualReview || builderId.contains('_provisional_');

  /// Search aliases for builder & project (preserving official names untouched).
  final List<String> builderAliases;
  final List<String> projectAliases;

  /// Canonical Bengaluru taluk name (e.g. Anekal, Yelahanka, Bengaluru East).
  final String normalizedTaluk;

  /// Provenance tier (`deep_extracted` or `catalogue_summary`).
  final String dataTier;

  bool get isCatalogueSummary =>
      dataTier.trim().toLowerCase() == 'catalogue_summary';

  bool get isDeepExtracted =>
      dataTier.trim().toLowerCase() == 'deep_extracted';

  /// Indicates the existing catalogue verification flag.
  /// This must not be treated as proof of legal compliance
  /// without independently reviewed supporting evidence.
  final bool verified;

  const Property({
    required this.id,
    required this.name,
    required this.builder,
    required this.city,
    this.locality = '',
    this.reraNumber = '',
    this.acknowledgementNumber = '',
    this.projectType = '',
    this.regulatoryStatus = '',
    this.approvedOn = '',
    this.proposedCompletionDate = '',
    this.projectStartDate = '',
    this.summaryMetrics = const {},
    this.tabObservations = const {},
    this.unlinkedPaneObservations = const {},
    this.inventoryConfigurations = const [],
    this.towersSummary = const [],
    this.unitHierarchyStatus = const UnitHierarchyStatus(),
    this.regulatoryCounts = const {},
    this.sourceType = EvidenceSourceType.kreraPortal,
    this.overallScore = 0,
    this.legalScore = 0,
    this.utilityScore = 0,
    this.safetyScore = 0,
    this.builderScore = 0,
    this.officialProjectName = '',
    this.normalizedProjectName = '',
    this.officialBuilderName = '',
    this.normalizedBuilderName = '',
    this.builderId = '',
    this.canonicalBuilderName = '',
    this.needsManualReview = false,
    this.builderAliases = const [],
    this.projectAliases = const [],
    this.normalizedTaluk = '',
    this.dataTier = '',
    required this.verified,
  });

  static Map<String, dynamic> _asStringMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Deserialize a canonical `projects/{projectId}` Firestore document into [Property].
  factory Property.fromFirestoreMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final docId =
        (documentId ?? map['project_id'] ?? map['id'] ?? '').toString();
    final rawMetrics = _asStringMap(map['summary_metrics']);
    final parsedMetrics = <String, RegulatoryMetric>{};
    for (final entry in rawMetrics.entries) {
      if (entry.value is Map) {
        parsedMetrics[entry.key] = RegulatoryMetric.fromMap(
          entry.key,
          _asStringMap(entry.value),
        );
      }
    }

    final rawTabs = _asStringMap(map['tab_observations_summary']);
    final parsedTabs = <String, RegulatoryTabSummary>{};
    for (final entry in rawTabs.entries) {
      if (entry.value is Map) {
        parsedTabs[entry.key] = RegulatoryTabSummary.fromMap(
          entry.key,
          _asStringMap(entry.value),
        );
      }
    }

    final rawPanes = _asStringMap(map['unlinked_pane_summary']);
    final parsedPanes = <String, RegulatoryTabSummary>{};
    for (final entry in rawPanes.entries) {
      if (entry.value is Map) {
        parsedPanes[entry.key] = RegulatoryTabSummary.fromMap(
          entry.key,
          _asStringMap(entry.value),
        );
      }
    }

    final rawInv =
        (map['inventory_configurations'] as List<dynamic>?) ?? const [];
    final parsedInv = rawInv
        .whereType<Map>()
        .map((e) => InventoryConfiguration.fromMap(_asStringMap(e)))
        .toList();

    final rawTowers = (map['towers_summary'] as List<dynamic>?) ?? const [];
    final parsedTowers = rawTowers
        .whereType<Map>()
        .map(
          (e) => ProjectTowerRecord.fromMap(
            _asStringMap(e),
            defaultProjectId: docId,
          ),
        )
        .toList();

    final rawCounts = _asStringMap(map['counts']);
    final parsedCounts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final v = entry.value;
      if (v is int) {
        parsedCounts[entry.key] = v;
      } else if (v is num) {
        parsedCounts[entry.key] = v.toInt();
      } else if (v is String) {
        parsedCounts[entry.key] = int.tryParse(v) ?? 0;
      }
    }

    final provenance = _asStringMap(map['provenance']);
    final identityVer = _asStringMap(map['identity_verification']);

    final rawBuilderAliases =
        (map['builderAliases'] as List<dynamic>?) ?? const [];
    final rawProjectAliases =
        (map['projectAliases'] as List<dynamic>?) ?? const [];

    return Property(
      id: docId,
      name: (map['project_name'] ?? map['name'] ?? '').toString(),
      builder: (map['promoter_name'] ?? map['builder'] ?? '').toString(),
      city: (map['city'] ?? 'Bengaluru').toString(),
      locality: (map['taluk'] ?? map['locality'] ?? map['district'] ?? '')
          .toString(),
      reraNumber:
          (map['registration_number'] ?? map['reraNumber'] ?? '').toString(),
      acknowledgementNumber: (map['acknowledgement_number'] ?? '').toString(),
      projectType: (map['project_type'] ?? '').toString(),
      regulatoryStatus:
          (map['regulatory_status'] ?? map['status'] ?? '').toString(),
      approvedOn:
          (map['approved_on_iso'] ?? map['approved_on_raw'] ?? '').toString(),
      proposedCompletionDate:
          (map['proposed_completion_date_iso'] ??
                  map['proposed_completion_date_raw'] ??
                  '')
              .toString(),
      projectStartDate: (map['project_start_date_iso'] ?? '').toString(),
      summaryMetrics: parsedMetrics,
      tabObservations: parsedTabs,
      unlinkedPaneObservations: parsedPanes,
      inventoryConfigurations: parsedInv,
      towersSummary: parsedTowers,
      unitHierarchyStatus: UnitHierarchyStatus.fromMap(
        map['unit_hierarchy_status'] is Map
            ? Map<String, dynamic>.from(map['unit_hierarchy_status'] as Map)
            : null,
      ),
      regulatoryCounts: parsedCounts,
      sourceType: EvidenceSourceType.fromWire(
        provenance['source_type']?.toString(),
      ),
      overallScore: 0,
      legalScore: 0,
      utilityScore: 0,
      safetyScore: 0,
      builderScore: 0,
      officialProjectName: (map['officialProjectName'] ?? '').toString(),
      normalizedProjectName: (map['normalizedProjectName'] ?? '').toString(),
      officialBuilderName: (map['officialBuilderName'] ?? '').toString(),
      normalizedBuilderName: (map['normalizedBuilderName'] ?? '').toString(),
      builderId: (map['builder_id'] ?? map['builderId'] ?? '').toString(),
      canonicalBuilderName:
          (map['canonical_builder_name'] ?? map['canonicalBuilderName'] ?? '')
              .toString(),
      needsManualReview: map['needsManualReview'] == true,
      builderAliases: rawBuilderAliases.map((e) => e.toString()).toList(),
      projectAliases: rawProjectAliases.map((e) => e.toString()).toList(),
      normalizedTaluk: (map['normalizedTaluk'] ?? '').toString(),
      dataTier: (provenance['data_tier'] ?? '').toString(),
      verified: identityVer['is_verified'] == true,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'project_id': id,
      'project_name': name,
      'promoter_name': builder,
      'city': city,
      'taluk': locality,
      'registration_number': reraNumber,
      'acknowledgement_number': acknowledgementNumber,
      'project_type': projectType,
      'regulatory_status': regulatoryStatus,
      'approved_on_iso': approvedOn,
      'proposed_completion_date_iso': proposedCompletionDate,
      'project_start_date_iso': projectStartDate,
      if (officialProjectName.isNotEmpty)
        'officialProjectName': officialProjectName,
      if (normalizedProjectName.isNotEmpty)
        'normalizedProjectName': normalizedProjectName,
      if (officialBuilderName.isNotEmpty)
        'officialBuilderName': officialBuilderName,
      if (normalizedBuilderName.isNotEmpty)
        'normalizedBuilderName': normalizedBuilderName,
      if (builderId.isNotEmpty) 'builder_id': builderId,
      if (canonicalBuilderName.isNotEmpty)
        'canonical_builder_name': canonicalBuilderName,
      if (needsManualReview) 'needsManualReview': true,
      if (builderAliases.isNotEmpty) 'builderAliases': builderAliases,
      if (projectAliases.isNotEmpty) 'projectAliases': projectAliases,
      if (normalizedTaluk.isNotEmpty) 'normalizedTaluk': normalizedTaluk,
      'summary_metrics': summaryMetrics.map((k, v) => MapEntry(k, v.toMap())),
      'tab_observations_summary': tabObservations.map(
        (k, v) => MapEntry(k, v.toMap()),
      ),
      'unlinked_pane_summary': unlinkedPaneObservations.map(
        (k, v) => MapEntry(k, v.toMap()),
      ),
      'inventory_configurations': inventoryConfigurations
          .map((e) => e.toMap())
          .toList(),
      'towers_summary': towersSummary.map((e) => e.toMap()).toList(),
      'unit_hierarchy_status': unitHierarchyStatus.toMap(),
      'counts': regulatoryCounts,
      'provenance': {
        'source_type': sourceType.wireValue,
        if (dataTier.isNotEmpty) 'data_tier': dataTier,
      },
      'identity_verification': {'is_verified': verified},
    };
  }
}
