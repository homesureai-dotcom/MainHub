/// Canonical K-RERA project intelligence and unit-hierarchy models for HomeSure Phase 1.
///
/// Preserves all six [ObservationState] values and explicit provenance
/// ([EvidenceSourceType.kreraPortal] vs [EvidenceSourceType.buyerProvided]).
library;

/// Official six observation states from the K-RERA extraction pipeline.
/// Must never be collapsed into a generic null or boolean.
enum ObservationState {
  presentWithData('present_with_data'),
  presentEmpty('present_empty'),
  notPresent('not_present'),
  notApplicable('not_applicable'),
  notAvailable('not_available'),
  extractionFailed('extraction_failed');

  final String wireValue;
  const ObservationState(this.wireValue);

  static ObservationState fromWire(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return ObservationState.notPresent;
    }
    final normalized = raw.trim().toLowerCase();
    for (final state in ObservationState.values) {
      if (state.wireValue == normalized) {
        return state;
      }
    }
    return ObservationState.notPresent;
  }

  String get displayLabel {
    switch (this) {
      case ObservationState.presentWithData:
        return 'Available in K-RERA';
      case ObservationState.presentEmpty:
        return 'Published Empty in K-RERA';
      case ObservationState.notPresent:
        return 'Not Present on Portal';
      case ObservationState.notApplicable:
        return 'Not Applicable';
      case ObservationState.notAvailable:
        return 'Not Available in K-RERA';
      case ObservationState.extractionFailed:
        return 'Extraction Failed';
    }
  }

  bool get hasData => this == ObservationState.presentWithData;
}

/// Provenance source for project, document, or unit-level data.
enum EvidenceSourceType {
  kreraPortal('KRERA_PORTAL'),
  buyerProvided('BUYER_PROVIDED'),
  systemDerived('SYSTEM_DERIVED');

  final String wireValue;
  const EvidenceSourceType(this.wireValue);

  static EvidenceSourceType fromWire(String? raw) {
    if (raw == null) return EvidenceSourceType.kreraPortal;
    final upper = raw.trim().toUpperCase();
    for (final s in EvidenceSourceType.values) {
      if (s.wireValue == upper) return s;
    }
    return EvidenceSourceType.kreraPortal;
  }

  String get displayLabel {
    switch (this) {
      case EvidenceSourceType.kreraPortal:
        return 'Official K-RERA Portal';
      case EvidenceSourceType.buyerProvided:
        return 'Buyer Provided';
      case EvidenceSourceType.systemDerived:
        return 'System Derived';
    }
  }
}

/// A single summary metric extracted from K-RERA tabs with explicit [ObservationState].
class RegulatoryMetric {
  final String key;
  final dynamic value;
  final String? rawValue;
  final String rawLabel;
  final ObservationState observationState;
  final String? sourceTab;
  final String? sourceSection;

  const RegulatoryMetric({
    required this.key,
    required this.value,
    this.rawValue,
    required this.rawLabel,
    required this.observationState,
    this.sourceTab,
    this.sourceSection,
  });

  factory RegulatoryMetric.fromMap(String key, Map<String, dynamic>? map) {
    if (map == null) {
      return RegulatoryMetric(
        key: key,
        value: null,
        rawLabel: key,
        observationState: ObservationState.notPresent,
      );
    }
    return RegulatoryMetric(
      key: key,
      value: map['value'],
      rawValue: map['raw_value']?.toString(),
      rawLabel: (map['raw_label'] ?? key).toString(),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
      sourceTab: map['source_tab']?.toString(),
      sourceSection: map['source_section']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'value': value,
    'raw_value': rawValue,
    'raw_label': rawLabel,
    'observation_state': observationState.wireValue,
    'source_tab': sourceTab,
    'source_section': sourceSection,
  };

  String get formattedValue {
    if (observationState != ObservationState.presentWithData || value == null) {
      return observationState.displayLabel;
    }
    final str = value.toString().trim();
    if (str.isEmpty) return observationState.displayLabel;
    return str;
  }
}

/// Summary of a visible tab or unlinked DOM pane on the K-RERA portal.
class RegulatoryTabSummary {
  final String tabKey;
  final String label;
  final String? tabIdentifier;
  final bool isVisibleTab;
  final ObservationState observationState;
  final int sectionCount;
  final int fieldCount;
  final int tableCount;
  final int documentCount;

  const RegulatoryTabSummary({
    required this.tabKey,
    required this.label,
    this.tabIdentifier,
    required this.isVisibleTab,
    required this.observationState,
    required this.sectionCount,
    required this.fieldCount,
    required this.tableCount,
    required this.documentCount,
  });

  factory RegulatoryTabSummary.fromMap(String key, Map<String, dynamic> map) {
    return RegulatoryTabSummary(
      tabKey: key,
      label: (map['label'] ?? key).toString(),
      tabIdentifier: map['tab_identifier']?.toString(),
      isVisibleTab: map['is_visible_tab'] == true,
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
      sectionCount: _toInt(map['section_count']),
      fieldCount: _toInt(map['field_count']),
      tableCount: _toInt(map['table_count']),
      documentCount: _toInt(map['document_count']),
    );
  }

  Map<String, dynamic> toMap() => {
    'label': label,
    'tab_identifier': tabIdentifier,
    'is_visible_tab': isVisibleTab,
    'observation_state': observationState.wireValue,
    'section_count': sectionCount,
    'field_count': fieldCount,
    'table_count': tableCount,
    'document_count': documentCount,
  };
}

/// Registered apartment/plot inventory configuration in K-RERA Development Details.
class InventoryConfiguration {
  final String typeOfInventory;
  final int? numberOfInventory;
  final String? carpetAreaSqM;
  final String? balconyAreaSqM;
  final String? terraceAreaSqM;
  final EvidenceSourceType sourceType;
  final ObservationState observationState;

  const InventoryConfiguration({
    required this.typeOfInventory,
    this.numberOfInventory,
    this.carpetAreaSqM,
    this.balconyAreaSqM,
    this.terraceAreaSqM,
    this.sourceType = EvidenceSourceType.kreraPortal,
    this.observationState = ObservationState.presentWithData,
  });

  factory InventoryConfiguration.fromMap(Map<String, dynamic> map) {
    return InventoryConfiguration(
      typeOfInventory: (map['type_of_inventory'] ?? '').toString(),
      numberOfInventory: _toNullableInt(map['no_of_inventory']),
      carpetAreaSqM: map['carpet_area_sq_m']?.toString(),
      balconyAreaSqM: map['balcony_area_sq_m']?.toString(),
      terraceAreaSqM: map['terrace_area_sq_m']?.toString(),
      sourceType: EvidenceSourceType.fromWire(map['source_type']?.toString()),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'type_of_inventory': typeOfInventory,
    'no_of_inventory': numberOfInventory,
    'carpet_area_sq_m': carpetAreaSqM,
    'balcony_area_sq_m': balconyAreaSqM,
    'terrace_area_sq_m': terraceAreaSqM,
    'source_type': sourceType.wireValue,
    'observation_state': observationState.wireValue,
  };
}

/// Phase-level hierarchy model (`Project -> Phase`).
class ProjectPhaseRecord {
  final String phaseId;
  final String projectId;
  final String phaseName;
  final String? reraRegistrationNumber;
  final String? status;
  final String? proposedCompletionDate;
  final EvidenceSourceType sourceType;
  final ObservationState observationState;

  const ProjectPhaseRecord({
    required this.phaseId,
    required this.projectId,
    required this.phaseName,
    this.reraRegistrationNumber,
    this.status,
    this.proposedCompletionDate,
    this.sourceType = EvidenceSourceType.kreraPortal,
    this.observationState = ObservationState.presentWithData,
  });

  factory ProjectPhaseRecord.fromMap(Map<String, dynamic> map) {
    return ProjectPhaseRecord(
      phaseId: (map['phase_id'] ?? '').toString(),
      projectId: (map['project_id'] ?? '').toString(),
      phaseName: (map['phase_name'] ?? '').toString(),
      reraRegistrationNumber: map['rera_registration_number']?.toString(),
      status: map['status']?.toString(),
      proposedCompletionDate: map['proposed_completion_date']?.toString(),
      sourceType: EvidenceSourceType.fromWire(map['source_type']?.toString()),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'phase_id': phaseId,
    'project_id': projectId,
    'phase_name': phaseName,
    'rera_registration_number': reraRegistrationNumber,
    'status': status,
    'proposed_completion_date': proposedCompletionDate,
    'source_type': sourceType.wireValue,
    'observation_state': observationState.wireValue,
  };
}

/// Tower/Block-level hierarchy model (`Project -> Phase -> Tower/Block`).
class ProjectTowerRecord {
  final String towerId;
  final String projectId;
  final String? phaseId;
  final String towerName;
  final String? towerType;
  final int? totalFloors;
  final int? totalUnits;
  final int? stilts;
  final int? basements;
  final int? totalParking;
  final String? heightMeters;
  final EvidenceSourceType sourceType;
  final ObservationState observationState;

  const ProjectTowerRecord({
    required this.towerId,
    required this.projectId,
    this.phaseId,
    required this.towerName,
    this.towerType,
    this.totalFloors,
    this.totalUnits,
    this.stilts,
    this.basements,
    this.totalParking,
    this.heightMeters,
    this.sourceType = EvidenceSourceType.kreraPortal,
    this.observationState = ObservationState.presentWithData,
  });

  factory ProjectTowerRecord.fromMap(
    Map<String, dynamic> map, {
    String defaultProjectId = '',
  }) {
    return ProjectTowerRecord(
      towerId: (map['tower_id'] ?? '').toString(),
      projectId: (map['project_id'] ?? defaultProjectId).toString(),
      phaseId: map['phase_id']?.toString(),
      towerName: (map['tower_name'] ?? '').toString(),
      towerType: map['tower_type']?.toString(),
      totalFloors: _toNullableInt(map['total_floors']),
      totalUnits: _toNullableInt(map['total_units']),
      stilts: _toNullableInt(map['stilts']),
      basements: _toNullableInt(map['basements']),
      totalParking: _toNullableInt(map['total_parking']),
      heightMeters: map['height_meters']?.toString(),
      sourceType: EvidenceSourceType.fromWire(map['source_type']?.toString()),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'tower_id': towerId,
    'project_id': projectId,
    'phase_id': phaseId,
    'tower_name': towerName,
    'tower_type': towerType,
    'total_floors': totalFloors,
    'total_units': totalUnits,
    'stilts': stilts,
    'basements': basements,
    'total_parking': totalParking,
    'height_meters': heightMeters,
    'source_type': sourceType.wireValue,
    'observation_state': observationState.wireValue,
  };
}

/// Individual apartment/plot/villa unit record (`Project -> Phase -> Tower/Block -> Unit`).
///
/// Supports both buyer-provided unit evaluations ([EvidenceSourceType.buyerProvided])
/// and portal unit rows ([EvidenceSourceType.kreraPortal]). Never fabricated.
class ProjectUnitRecord {
  final String unitId;
  final String projectId;
  final String? phaseId;
  final String? towerId;
  final String? towerName;
  final String unitNumber;
  final String? floorNumber;
  final String? unitConfiguration;
  final double? carpetAreaSqM;
  final double? superBuiltUpAreaSqM;
  final String? facing;
  final String? parkingAllocation;
  final EvidenceSourceType sourceType;
  final String? createdByUserId;
  final ObservationState observationState;
  final String? createdAtIso;

  const ProjectUnitRecord({
    required this.unitId,
    required this.projectId,
    this.phaseId,
    this.towerId,
    this.towerName,
    required this.unitNumber,
    this.floorNumber,
    this.unitConfiguration,
    this.carpetAreaSqM,
    this.superBuiltUpAreaSqM,
    this.facing,
    this.parkingAllocation,
    required this.sourceType,
    this.createdByUserId,
    this.observationState = ObservationState.presentWithData,
    this.createdAtIso,
  });

  factory ProjectUnitRecord.fromMap(Map<String, dynamic> map) {
    return ProjectUnitRecord(
      unitId: (map['unit_id'] ?? '').toString(),
      projectId: (map['project_id'] ?? '').toString(),
      phaseId: map['phase_id']?.toString(),
      towerId: map['tower_id']?.toString(),
      towerName: map['tower_name']?.toString(),
      unitNumber: (map['unit_number'] ?? '').toString(),
      floorNumber: map['floor_number']?.toString(),
      unitConfiguration: map['unit_configuration']?.toString(),
      carpetAreaSqM: _toNullableDouble(map['carpet_area_sq_m']),
      superBuiltUpAreaSqM: _toNullableDouble(map['super_built_up_area_sq_m']),
      facing: map['facing']?.toString(),
      parkingAllocation: map['parking_allocation']?.toString(),
      sourceType: EvidenceSourceType.fromWire(map['source_type']?.toString()),
      createdByUserId: map['created_by_user_id']?.toString(),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
      createdAtIso: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'unit_id': unitId,
    'project_id': projectId,
    'phase_id': phaseId,
    'tower_id': towerId,
    'tower_name': towerName,
    'unit_number': unitNumber,
    'floor_number': floorNumber,
    'unit_configuration': unitConfiguration,
    'carpet_area_sq_m': carpetAreaSqM,
    'super_built_up_area_sq_m': superBuiltUpAreaSqM,
    'facing': facing,
    'parking_allocation': parkingAllocation,
    'source_type': sourceType.wireValue,
    'created_by_user_id': createdByUserId,
    'observation_state': observationState.wireValue,
    'created_at': createdAtIso,
  };
}

/// Unit-hierarchy availability status for a project.
class UnitHierarchyStatus {
  final ObservationState phasesState;
  final ObservationState towersState;
  final int towersCount;
  final ObservationState inventoryConfigsState;
  final int inventoryConfigsCount;
  final ObservationState portalUnitRowsState;
  final int portalUnitRowsCount;
  final bool buyerUnitsEnabled;
  final String? notes;

  const UnitHierarchyStatus({
    this.phasesState = ObservationState.notAvailable,
    this.towersState = ObservationState.notAvailable,
    this.towersCount = 0,
    this.inventoryConfigsState = ObservationState.notAvailable,
    this.inventoryConfigsCount = 0,
    this.portalUnitRowsState = ObservationState.notAvailable,
    this.portalUnitRowsCount = 0,
    this.buyerUnitsEnabled = true,
    this.notes,
  });

  factory UnitHierarchyStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UnitHierarchyStatus();
    return UnitHierarchyStatus(
      phasesState: ObservationState.fromWire(map['phases_state']?.toString()),
      towersState: ObservationState.fromWire(map['towers_state']?.toString()),
      towersCount: _toInt(map['towers_count']),
      inventoryConfigsState: ObservationState.fromWire(
        map['inventory_configs_state']?.toString(),
      ),
      inventoryConfigsCount: _toInt(map['inventory_configs_count']),
      portalUnitRowsState: ObservationState.fromWire(
        map['portal_unit_rows_state']?.toString(),
      ),
      portalUnitRowsCount: _toInt(map['portal_unit_rows_count']),
      buyerUnitsEnabled: map['buyer_units_enabled'] != false,
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'phases_state': phasesState.wireValue,
    'towers_state': towersState.wireValue,
    'towers_count': towersCount,
    'inventory_configs_state': inventoryConfigsState.wireValue,
    'inventory_configs_count': inventoryConfigsCount,
    'portal_unit_rows_state': portalUnitRowsState.wireValue,
    'portal_unit_rows_count': portalUnitRowsCount,
    'buyer_units_enabled': buyerUnitsEnabled,
    'notes': notes,
  };
}

/// Regulatory document metadata record extracted from K-RERA.
class RegulatoryDocumentRecord {
  final String documentId;
  final String projectId;
  final String documentCategory;
  final String? displayedFilename;
  final String? approvalDate;
  final String? sourceUrl;
  final bool hasDownloadableFile;
  final ObservationState observationState;
  final String sourceTab;
  final String sourceSection;
  final EvidenceSourceType sourceType;
  final int displayOrder;

  const RegulatoryDocumentRecord({
    required this.documentId,
    required this.projectId,
    required this.documentCategory,
    this.displayedFilename,
    this.approvalDate,
    this.sourceUrl,
    required this.hasDownloadableFile,
    required this.observationState,
    required this.sourceTab,
    required this.sourceSection,
    this.sourceType = EvidenceSourceType.kreraPortal,
    this.displayOrder = 0,
  });

  factory RegulatoryDocumentRecord.fromMap(Map<String, dynamic> map) {
    final url = map['source_url']?.toString();
    return RegulatoryDocumentRecord(
      documentId: (map['document_id'] ?? '').toString(),
      projectId: (map['project_id'] ?? '').toString(),
      documentCategory:
          (map['document_category'] ?? map['category'] ?? 'Document')
              .toString(),
      displayedFilename:
          (map['displayed_filename'] ?? map['filename'])?.toString(),
      approvalDate:
          (map['approval_date_normalized'] ??
                  map['approval_date_raw'] ??
                  map['approval_date'])
              ?.toString(),
      sourceUrl: url,
      hasDownloadableFile:
          map['has_downloadable_file'] == true ||
          (url != null && url.trim().isNotEmpty),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
      sourceTab: (map['source_tab'] ?? '').toString(),
      sourceSection: (map['source_section'] ?? '').toString(),
      sourceType: EvidenceSourceType.fromWire(map['source_type']?.toString()),
      displayOrder: _toInt(map['display_order']),
    );
  }

  Map<String, dynamic> toMap() => {
    'document_id': documentId,
    'project_id': projectId,
    'document_category': documentCategory,
    'displayed_filename': displayedFilename,
    'approval_date_normalized': approvalDate,
    'source_url': sourceUrl,
    'has_downloadable_file': hasDownloadableFile,
    'observation_state': observationState.wireValue,
    'source_tab': sourceTab,
    'source_section': sourceSection,
    'source_type': sourceType.wireValue,
    'display_order': displayOrder,
  };
}

/// Official K-RERA complaint record associated with a project or promoter.
class RegulatoryComplaintRecord {
  final String complaintId;
  final String projectId;
  final String complaintScope; // 'PROJECT' or 'PROMOTER'
  final String sectionLabel;
  final String? complaintNumber;
  final String? complainantName;
  final String? complaintDate;
  final String? complaintSubject;
  final String? complaintStatus;
  final String? orderBy;
  final ObservationState observationState;

  const RegulatoryComplaintRecord({
    required this.complaintId,
    required this.projectId,
    required this.complaintScope,
    required this.sectionLabel,
    this.complaintNumber,
    this.complainantName,
    this.complaintDate,
    this.complaintSubject,
    this.complaintStatus,
    this.orderBy,
    this.observationState = ObservationState.presentWithData,
  });

  factory RegulatoryComplaintRecord.fromMap(Map<String, dynamic> map) {
    return RegulatoryComplaintRecord(
      complaintId: (map['complaint_id'] ?? '').toString(),
      projectId: (map['project_id'] ?? '').toString(),
      complaintScope: (map['complaint_scope'] ?? 'PROJECT').toString(),
      sectionLabel: (map['section_label'] ?? 'Complaints').toString(),
      complaintNumber: map['complaint_number']?.toString(),
      complainantName: map['complainant_name']?.toString(),
      complaintDate: map['complaint_date']?.toString(),
      complaintSubject: map['complaint_subject']?.toString(),
      complaintStatus: map['complaint_status']?.toString(),
      orderBy: map['order_by']?.toString(),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'complaint_id': complaintId,
    'project_id': projectId,
    'complaint_scope': complaintScope,
    'section_label': sectionLabel,
    'complaint_number': complaintNumber,
    'complainant_name': complainantName,
    'complaint_date': complaintDate,
    'complaint_subject': complaintSubject,
    'complaint_status': complaintStatus,
    'order_by': orderBy,
    'observation_state': observationState.wireValue,
  };
}

/// Section-level field and table bundle loaded from `regulatory_tabs/bundle_all`.
class RegulatorySectionRecord {
  final String tabLabel;
  final String sectionLabel;
  final String sectionType;
  final ObservationState observationState;
  final String? emptyMessage;
  final int fieldCount;
  final int tableRowCount;
  final int documentCount;
  final List<Map<String, dynamic>> fields;
  final List<String> tableHeaders;
  final List<Map<String, dynamic>> tableRowsPreview;

  const RegulatorySectionRecord({
    required this.tabLabel,
    required this.sectionLabel,
    required this.sectionType,
    required this.observationState,
    this.emptyMessage,
    required this.fieldCount,
    required this.tableRowCount,
    required this.documentCount,
    required this.fields,
    required this.tableHeaders,
    required this.tableRowsPreview,
  });

  factory RegulatorySectionRecord.fromMap(Map<String, dynamic> map) {
    final rawFields = (map['fields'] as List<dynamic>?) ?? const [];
    final rawHeaders = (map['table_headers'] as List<dynamic>?) ?? const [];
    final rawRows = (map['table_rows_preview'] as List<dynamic>?) ?? const [];
    return RegulatorySectionRecord(
      tabLabel: (map['tab_label'] ?? '').toString(),
      sectionLabel: (map['section_label'] ?? '').toString(),
      sectionType: (map['section_type'] ?? 'key_value').toString(),
      observationState: ObservationState.fromWire(
        map['observation_state']?.toString(),
      ),
      emptyMessage: map['empty_message']?.toString(),
      fieldCount: _toInt(map['field_count']),
      tableRowCount: _toInt(map['table_row_count']),
      documentCount: _toInt(map['document_count']),
      fields: rawFields
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      tableHeaders: rawHeaders.map((e) => e.toString()).toList(),
      tableRowsPreview: rawRows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

/// Complete detail bundle loaded on-demand for `PropertyDetailsScreen`.
class ProjectRegulatoryDetailBundle {
  final String projectId;
  final List<RegulatorySectionRecord> sections;
  final List<RegulatoryDocumentRecord> documents;
  final List<RegulatoryComplaintRecord> complaints;
  final List<ProjectTowerRecord> towers;
  final List<InventoryConfiguration> inventoryConfigurations;

  const ProjectRegulatoryDetailBundle({
    required this.projectId,
    this.sections = const [],
    this.documents = const [],
    this.complaints = const [],
    this.towers = const [],
    this.inventoryConfigurations = const [],
  });

  factory ProjectRegulatoryDetailBundle.fromMap(
    Map<String, dynamic> map, {
    required String projectId,
  }) {
    final rawSections = (map['key_sections'] as List<dynamic>?) ?? const [];
    final rawDocs = (map['regulatory_documents'] as List<dynamic>?) ?? const [];
    final rawComplaints =
        (map['complaints_records'] as List<dynamic>?) ?? const [];
    final rawTowers = (map['towers_summary'] as List<dynamic>?) ?? const [];
    final rawInv =
        (map['inventory_configurations'] as List<dynamic>?) ?? const [];

    return ProjectRegulatoryDetailBundle(
      projectId: projectId,
      sections: rawSections
          .whereType<Map>()
          .map(
            (e) =>
                RegulatorySectionRecord.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      documents: rawDocs
          .whereType<Map>()
          .map(
            (e) =>
                RegulatoryDocumentRecord.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      complaints: rawComplaints
          .whereType<Map>()
          .map(
            (e) => RegulatoryComplaintRecord.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      towers: rawTowers
          .whereType<Map>()
          .map(
            (e) => ProjectTowerRecord.fromMap(
              Map<String, dynamic>.from(e),
              defaultProjectId: projectId,
            ),
          )
          .toList(),
      inventoryConfigurations: rawInv
          .whereType<Map>()
          .map(
            (e) => InventoryConfiguration.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

/// Lightweight project entry embedded inside a [BuilderCatalogueEntry].
class BuilderProjectSummary {
  final String projectId;
  final String projectName;
  final String promoterName;
  final String registrationNumber;
  final String acknowledgementNumber;
  final String projectType;
  final String regulatoryStatus;
  final String district;
  final String taluk;
  final String city;
  final String approvedOn;
  final String proposedCompletionDate;
  final String projectStartDate;
  final int totalUnits;
  final int totalTowers;

  const BuilderProjectSummary({
    required this.projectId,
    required this.projectName,
    required this.promoterName,
    this.registrationNumber = '',
    this.acknowledgementNumber = '',
    this.projectType = '',
    this.regulatoryStatus = 'APPROVED',
    this.district = 'Bengaluru Urban',
    this.taluk = '',
    this.city = 'Bengaluru',
    this.approvedOn = '',
    this.proposedCompletionDate = '',
    this.projectStartDate = '',
    this.totalUnits = 0,
    this.totalTowers = 0,
  });

  factory BuilderProjectSummary.fromMap(Map<String, dynamic> map) {
    return BuilderProjectSummary(
      projectId: (map['project_id'] ?? map['id'] ?? '').toString(),
      projectName: (map['project_name'] ?? map['name'] ?? '').toString(),
      promoterName: (map['promoter_name'] ?? map['builder'] ?? '').toString(),
      registrationNumber:
          (map['registration_number'] ?? map['reraNumber'] ?? '').toString(),
      acknowledgementNumber:
          (map['acknowledgement_number'] ?? map['acknowledgementNumber'] ?? '')
              .toString(),
      projectType: (map['project_type'] ?? '').toString(),
      regulatoryStatus: (map['regulatory_status'] ?? 'APPROVED').toString(),
      district: (map['district'] ?? 'Bengaluru Urban').toString(),
      taluk: (map['taluk'] ?? map['locality'] ?? '').toString(),
      city: (map['city'] ?? 'Bengaluru').toString(),
      approvedOn: (map['approved_on'] ?? '').toString(),
      proposedCompletionDate:
          (map['proposed_completion_date'] ?? '').toString(),
      projectStartDate: (map['project_start_date'] ?? '').toString(),
      totalUnits: _toInt(map['total_units']),
      totalTowers: _toInt(map['total_towers']),
    );
  }

  Map<String, dynamic> toMap() => {
    'project_id': projectId,
    'project_name': projectName,
    'promoter_name': promoterName,
    'registration_number': registrationNumber,
    'acknowledgement_number': acknowledgementNumber,
    'project_type': projectType,
    'regulatory_status': regulatoryStatus,
    'district': district,
    'taluk': taluk,
    'city': city,
    'approved_on': approvedOn,
    'proposed_completion_date': proposedCompletionDate,
    'project_start_date': projectStartDate,
    'total_units': totalUnits,
    'total_towers': totalTowers,
  };
}

/// Canonical Builder / Developer group entry in the K-RERA catalogue.
///
/// Groups all K-RERA projects registered under a builder brand or legal promoter
/// entity so users can search by builder name first, view all projects under
/// that builder, and then open a specific project's details.
class BuilderCatalogueEntry {
  final String builderId;
  final String builderName;
  final bool isFeaturedBrand;
  final int projectCount;
  final List<String> legalPromoterNames;
  final List<String> localities;
  final List<String> projectIds;
  final List<BuilderProjectSummary> projects;
  final List<String> searchTokens;

  const BuilderCatalogueEntry({
    required this.builderId,
    required this.builderName,
    this.isFeaturedBrand = false,
    required this.projectCount,
    this.legalPromoterNames = const [],
    this.localities = const [],
    this.projectIds = const [],
    this.projects = const [],
    this.searchTokens = const [],
  });

  factory BuilderCatalogueEntry.fromMap(Map<String, dynamic> map) {
    final rawPromoters =
        (map['legal_promoter_names'] as List<dynamic>?) ?? const [];
    final rawLocalities = (map['localities'] as List<dynamic>?) ?? const [];
    final rawProjectIds = (map['project_ids'] as List<dynamic>?) ?? const [];
    final rawProjects = (map['projects'] as List<dynamic>?) ?? const [];
    final rawTokens = (map['search_tokens'] as List<dynamic>?) ?? const [];

    final parsedProjects = rawProjects
        .whereType<Map>()
        .map((e) => BuilderProjectSummary.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return BuilderCatalogueEntry(
      builderId: (map['builder_id'] ?? '').toString(),
      builderName: (map['builder_name'] ?? '').toString(),
      isFeaturedBrand: map['is_featured_brand'] == true,
      projectCount: _toInt(map['project_count'] ?? parsedProjects.length),
      legalPromoterNames: rawPromoters.map((e) => e.toString()).toList(),
      localities: rawLocalities.map((e) => e.toString()).toList(),
      projectIds: rawProjectIds.map((e) => e.toString()).toList(),
      projects: parsedProjects,
      searchTokens: rawTokens.map((e) => e.toString()).toList(),
    );
  }

  bool matchesSearchQuery(String rawQuery) {
    final lower = rawQuery.trim().toLowerCase();
    if (lower.isEmpty) return true;

    if (builderName.toLowerCase().contains(lower)) return true;
    for (final legal in legalPromoterNames) {
      if (legal.toLowerCase().contains(lower)) return true;
    }
    for (final loc in localities) {
      if (loc.toLowerCase().contains(lower)) return true;
    }
    for (final proj in projects) {
      if (proj.projectName.toLowerCase().contains(lower) ||
          proj.promoterName.toLowerCase().contains(lower) ||
          proj.registrationNumber.toLowerCase().contains(lower)) {
        return true;
      }
    }

    final words = lower
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length > 1) {
      final combined =
          '$builderName ${legalPromoterNames.join(' ')} ${localities.join(' ')} ${projects.map((p) => p.projectName).join(' ')}'
              .toLowerCase();
      return words.every((w) => combined.contains(w));
    }

    return false;
  }

  /// Resolves the canonical brand `(builderId, builderName, isFeaturedBrand)`
  /// for a given `(promoterName, projectName)` pair so SPVs under major brands
  /// (e.g. Godrej, Prestige, Brigade, Sobha, Shriram) are grouped cleanly.
  static ({String id, String name, bool isBrand}) resolveCanonicalBrand({
    required String promoterName,
    required String projectName,
  }) {
    final combined = '$promoterName $projectName';
    const rules = <({String id, String name, String pattern})>[
      (
        id: 'builder_godrej_properties',
        name: 'Godrej Properties',
        pattern: r'\bgodrej\b',
      ),
      (
        id: 'builder_prestige_group',
        name: 'Prestige Group',
        pattern: r'\bprestige\b',
      ),
      (
        id: 'builder_brigade_group',
        name: 'Brigade Group',
        pattern: r'\bbrigade\b',
      ),
      (
        id: 'builder_sobha_limited',
        name: 'Sobha Limited',
        pattern: r'\bsobha\b',
      ),
      (
        id: 'builder_shriram_properties',
        name: 'Shriram Properties',
        pattern: r'\bshriram\b',
      ),
      (
        id: 'builder_puravankara_group',
        name: 'Puravankara & Provident',
        pattern: r'\b(puravankara|provident)\b',
      ),
      (
        id: 'builder_sattva_group',
        name: 'Sattva Group (Salarpuria Sattva)',
        pattern: r'\b(sattva|salarpuria)\b',
      ),
      (
        id: 'builder_embassy_group',
        name: 'Embassy Group',
        pattern: r'\bembassy\b',
      ),
      (
        id: 'builder_total_environment',
        name: 'Total Environment',
        pattern:
            r'\b(total environment|faraway tree hospitality|autumnleaf)\b',
      ),
      (
        id: 'builder_sumadhura_group',
        name: 'Sumadhura Group',
        pattern: r'\bsumadhura\b',
      ),
      (
        id: 'builder_assetz_group',
        name: 'Assetz Property Group',
        pattern: r'\bassetz\b',
      ),
      (
        id: 'builder_century_real_estate',
        name: 'Century Real Estate',
        pattern: r'\bcentury\b',
      ),
      (id: 'builder_adarsh_group', name: 'Adarsh Group', pattern: r'\badarsh\b'),
      (
        id: 'builder_mantri_developers',
        name: 'Mantri Developers',
        pattern: r'\bmantri\b',
      ),
      (id: 'builder_rmz_corp', name: 'RMZ Corp', pattern: r'\brmz\b'),
      (
        id: 'builder_mahindra_lifespaces',
        name: 'Mahindra Lifespaces',
        pattern: r'\bmahindra\b',
      ),
      (
        id: 'builder_tata_housing',
        name: 'Tata Housing & Value Homes',
        pattern: r'\btata\b',
      ),
      (
        id: 'builder_birla_estates',
        name: 'Birla Estates',
        pattern: r'\bbirla\b',
      ),
      (id: 'builder_lodha_group', name: 'Lodha (Macrotech)', pattern: r'\blodha\b'),
      (id: 'builder_casagrand', name: 'Casagrand', pattern: r'\bcasagrand\b'),
      (
        id: 'builder_concorde_group',
        name: 'Concorde Group',
        pattern: r'\bconcorde\b',
      ),
      (id: 'builder_ds_max', name: 'DS-Max Properties', pattern: r'\bds[\s\-]*max\b'),
      (id: 'builder_mana_projects', name: 'Mana Projects', pattern: r'\bmana\b'),
      (id: 'builder_sbr_group', name: 'SBR Group', pattern: r'\bsbr\b'),
      (id: 'builder_pride_group', name: 'Pride Group', pattern: r'\bpride\b'),
      (
        id: 'builder_gopalan_enterprises',
        name: 'Gopalan Enterprises',
        pattern: r'\bgopalan\b',
      ),
      (
        id: 'builder_confident_group',
        name: 'Confident Group',
        pattern: r'\bconfident\b',
      ),
      (
        id: 'builder_vaishnavi_group',
        name: 'Vaishnavi Group',
        pattern: r'\bvaishnavi\b',
      ),
      (id: 'builder_nikoo_bhartiya', name: 'Bhartiya City', pattern: r'\bbhartiya\b'),
      (
        id: 'builder_radiance_realty',
        name: 'Radiance Realty',
        pattern: r'\bradiance\b',
      ),
      (id: 'builder_rohan_builders', name: 'Rohan Builders', pattern: r'\brohan\b'),
      (id: 'builder_sjr_primecorp', name: 'SJR Primecorp', pattern: r'\bsjr\b'),
      (id: 'builder_Vaswani_group', name: 'Vaswani Group', pattern: r'\bvaswani\b'),
    ];

    for (final rule in rules) {
      if (RegExp(rule.pattern, caseSensitive: false).hasMatch(combined)) {
        return (id: rule.id, name: rule.name, isBrand: true);
      }
    }

    final clean = promoterName.trim().isEmpty
        ? 'Independent / Unspecified Promoter'
        : promoterName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final slug = clean
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return (
      id: 'builder_${slug.isEmpty ? 'unknown' : slug}',
      name: clean,
      isBrand: false,
    );
  }
}

int _toInt(dynamic val) {
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val.trim()) ?? 0;
  return 0;
}

int? _toNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val.trim());
  return null;
}

double? _toNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val is String) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned);
  }
  return null;
}
