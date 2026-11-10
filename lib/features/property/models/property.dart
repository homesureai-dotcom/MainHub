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
    this.selectedUnit,
    required this.compliance,
    required this.assessment,
    required this.documents,
  });

  Property copyWith({
    ProjectUnitRecord? selectedUnit,
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
      selectedUnit: selectedUnit ?? this.selectedUnit,
      compliance: compliance ?? this.compliance,
      assessment: assessment ?? this.assessment,
      documents: documents ?? this.documents,
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
