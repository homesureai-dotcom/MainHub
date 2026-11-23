import 'assessment_summary.dart';
import 'compliance_summary.dart';
import 'document_summary.dart';
import 'krera_project_models.dart';

class Property {
  final String id;

  final String name;

  final String builderName;

  final String ownerName;

  final Address address;

  final PropertyType type;

  final int yearOfConstruction;

  final double carpetArea;

  final int totalUnits;

  /// Official K-RERA registration number (`PRM/KA/RERA/...`).
  final String reraNumber;

  /// Official K-RERA acknowledgement number (`PR/KN/...`).
  final String acknowledgementNumber;

  /// Official K-RERA status (`APPROVED`, `EXTENDED`, etc.).
  final String regulatoryStatus;

  /// Proposed completion date from K-RERA (`YYYY-MM-DD`).
  final String proposedCompletionDate;

  /// Extracted K-RERA summary metrics with explicit [ObservationState].
  final Map<String, RegulatoryMetric> summaryMetrics;

  /// Unit-hierarchy availability status (`Project -> Phase -> Tower -> Unit`).
  final UnitHierarchyStatus unitHierarchyStatus;

  /// Provenance depth tier (`deep_extracted` or `catalogue_summary`).
  final String dataTier;

  bool get isCatalogueSummary =>
      dataTier.trim().toLowerCase() == 'catalogue_summary';

  bool get isDeepExtracted =>
      dataTier.trim().toLowerCase() == 'deep_extracted';

  /// Optional specific unit being evaluated by the buyer.
  final ProjectUnitRecord? selectedUnit;

  /// Current compliance status
  final ComplianceSummary compliance;

  /// Latest assessment information
  final AssessmentSummary assessment;

  /// Document status
  final DocumentSummary documents;

  const Property({
    required this.id,
    required this.name,
    required this.builderName,
    required this.ownerName,
    required this.address,
    required this.type,
    required this.yearOfConstruction,
    required this.carpetArea,
    required this.totalUnits,
    this.reraNumber = '',
    this.acknowledgementNumber = '',
    this.regulatoryStatus = '',
    this.proposedCompletionDate = '',
    this.summaryMetrics = const {},
    this.unitHierarchyStatus = const UnitHierarchyStatus(),
    this.dataTier = '',
    this.selectedUnit,
    required this.compliance,
    required this.assessment,
    required this.documents,
  });

  Property copyWith({
    String? dataTier,
    ProjectUnitRecord? selectedUnit,
    bool clearSelectedUnit = false,
    ComplianceSummary? compliance,
    AssessmentSummary? assessment,
    DocumentSummary? documents,
  }) {
    return Property(
      id: id,
      name: name,
      builderName: builderName,
      ownerName: ownerName,
      address: address,
      type: type,
      yearOfConstruction: yearOfConstruction,
      carpetArea: carpetArea,
      totalUnits: totalUnits,
      reraNumber: reraNumber,
      acknowledgementNumber: acknowledgementNumber,
      regulatoryStatus: regulatoryStatus,
      proposedCompletionDate: proposedCompletionDate,
      summaryMetrics: summaryMetrics,
      unitHierarchyStatus: unitHierarchyStatus,
      dataTier: dataTier ?? this.dataTier,
      selectedUnit: clearSelectedUnit ? null : (selectedUnit ?? this.selectedUnit),
      compliance: compliance ?? this.compliance,
      assessment: assessment ?? this.assessment,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toPersistenceMap() {
    return {
      'id': id,
      'name': name,
      'builderName': builderName,
      'ownerName': ownerName,
      'address': {
        'line1': address.line1,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
      },
      'type': type.name,
      'yearOfConstruction': yearOfConstruction,
      'carpetArea': carpetArea,
      'totalUnits': totalUnits,
      'reraNumber': reraNumber,
      'acknowledgementNumber': acknowledgementNumber,
      'regulatoryStatus': regulatoryStatus,
      'proposedCompletionDate': proposedCompletionDate,
      if (dataTier.isNotEmpty) 'dataTier': dataTier,
      'compliance': {
        'verifiedCount': compliance.verifiedCount,
        'pendingCount': compliance.pendingCount,
        'issueCount': compliance.issueCount,
        'compliancePercentage': compliance.compliancePercentage,
      },
      'documents': {
        'verifiedDocuments': documents.verifiedDocuments,
        'pendingDocuments': documents.pendingDocuments,
        'missingDocuments': documents.missingDocuments,
      },
    };
  }

  factory Property.fromPersistenceMap(Map<String, dynamic> map) {
    final addrMap = (map['address'] as Map?) ?? const {};
    final compMap = (map['compliance'] as Map?) ?? const {};
    final docsMap = (map['documents'] as Map?) ?? const {};
    final typeName = (map['type'] ?? '').toString();
    final parsedType = PropertyType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => PropertyType.apartment,
    );

    int toInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse((val ?? '').toString()) ?? 0;
    }

    double toDouble(dynamic val) {
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return double.tryParse((val ?? '').toString()) ?? 0;
    }

    return Property(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      builderName: (map['builderName'] ?? '').toString(),
      ownerName: (map['ownerName'] ?? '').toString(),
      address: Address(
        line1: (addrMap['line1'] ?? '').toString(),
        city: (addrMap['city'] ?? 'Bengaluru').toString(),
        state: (addrMap['state'] ?? 'Karnataka').toString(),
        pincode: (addrMap['pincode'] ?? '').toString(),
      ),
      type: parsedType,
      yearOfConstruction: toInt(map['yearOfConstruction']),
      carpetArea: toDouble(map['carpetArea']),
      totalUnits: toInt(map['totalUnits']),
      reraNumber: (map['reraNumber'] ?? '').toString(),
      acknowledgementNumber: (map['acknowledgementNumber'] ?? '').toString(),
      regulatoryStatus: (map['regulatoryStatus'] ?? '').toString(),
      proposedCompletionDate: (map['proposedCompletionDate'] ?? '').toString(),
      dataTier: (map['dataTier'] ?? '').toString(),
      compliance: ComplianceSummary(
        verifiedCount: toInt(compMap['verifiedCount']),
        pendingCount: toInt(compMap['pendingCount']),
        issueCount: toInt(compMap['issueCount']),
        compliancePercentage: toDouble(compMap['compliancePercentage']),
      ),
      assessment: const AssessmentSummary(),
      documents: DocumentSummary(
        verifiedDocuments: toInt(docsMap['verifiedDocuments']),
        pendingDocuments: toInt(docsMap['pendingDocuments']),
        missingDocuments: toInt(docsMap['missingDocuments']),
      ),
    );
  }
}

class Address {
  final String line1;

  final String city;

  final String state;

  final String pincode;

  const Address({
    required this.line1,
    required this.city,
    required this.state,
    required this.pincode,
  });

  String get formatted => "$line1, $city, $state - $pincode";
}

enum PropertyType { apartment, villa, plot, commercial }
