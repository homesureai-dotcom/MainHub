import '../models/assessment_summary.dart';
import '../models/compliance_summary.dart';
import '../models/document_summary.dart';
import '../models/property.dart';

class PropertyRepository {
  PropertyRepository._();

  static final PropertyRepository instance = PropertyRepository._();

  Property _selectedProperty = Property(
    id: "P001",
    name: "Casagrand Aquene",
    builderName: "Casagrand",
    ownerName: "Vinod",
    address: const Address(
      line1: "Kengeri",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560060",
    ),
    type: PropertyType.apartment,
    yearOfConstruction: 2025,
    carpetArea: 708,
    totalUnits: 333,

    compliance: const ComplianceSummary(
      verifiedCount: 24,
      pendingCount: 5,
      issueCount: 2,
      compliancePercentage: 82,
    ),

    assessment: const AssessmentSummary(
      latestAssessment: null,
      lastAssessmentDate: null,
    ),

    documents: const DocumentSummary(
      verifiedDocuments: 18,
      pendingDocuments: 4,
      missingDocuments: 3,
    ),
  );

  Property get selectedProperty => _selectedProperty;

  void selectProperty(Property property) {
    _selectedProperty = property;
  }
}