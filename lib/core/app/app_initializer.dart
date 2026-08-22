import '../../features/property/models/assessment_summary.dart';
import '../../features/property/models/compliance_summary.dart';
import '../../features/property/models/document_summary.dart';
import '../../features/property/models/property.dart';
import '../../features/property/state/property_state.dart';

class AppInitializer {
  const AppInitializer();

  Future<void> initialize() async {
    final propertyState = PropertyState.instance;

    propertyState.initialize(
      properties: [
        Property(
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

          assessment: const AssessmentSummary(),

          documents: const DocumentSummary(
            verifiedDocuments: 18,
            pendingDocuments: 4,
            missingDocuments: 3,
          ),
        ),
      ],
    );
  }
}