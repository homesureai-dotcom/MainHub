import 'assessment_summary.dart';
import 'compliance_summary.dart';
import 'document_summary.dart';

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
    required this.compliance,
    required this.assessment,
    required this.documents,
  });
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

  String get formatted =>
      "$line1, $city, $state - $pincode";
}

enum PropertyType {
  apartment,
  villa,
  plot,
  commercial,
}