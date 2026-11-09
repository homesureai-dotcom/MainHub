import '../../../models/property.dart' as legacy;

import 'assessment_summary.dart';
import 'compliance_summary.dart';
import 'document_summary.dart';
import 'property.dart';

/// Converts the legacy onboarding Property model into
/// the canonical feature Property model used by
/// PropertyState and the dashboard.
///
/// Catalogue inclusion and the legacy verification flag
/// are not proof of legal or regulatory compliance.
/// Compliance must be based on independently reviewed evidence.
class PropertyAdapter {
  const PropertyAdapter._();

  static Property fromLegacy(legacy.Property property) {
    return Property(
      id: property.id,
      name: property.name,
      builderName: property.builder,
      ownerName: '',
      address: Address(
        line1: property.locality,
        city: property.city,
        state: '',
        pincode: '',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 0,
      carpetArea: 0,
      totalUnits: 0,
      compliance: const ComplianceSummary(
        verifiedCount: 0,
        pendingCount: 1,
        issueCount: 0,
        compliancePercentage: 0,
      ),
      assessment: const AssessmentSummary(),
      documents: const DocumentSummary(
        verifiedDocuments: 0,
        pendingDocuments: 0,
        missingDocuments: 0,
      ),
    );
  }
}
