import '../../../models/property.dart' as legacy;

import 'assessment_summary.dart';
import 'compliance_summary.dart';
import 'document_summary.dart';
import 'property.dart';

/// Converts the legacy onboarding Property model into
/// the canonical feature Property model used by
/// PropertyState and the dashboard.
///
/// This adapter is retained for legacy properties that
/// do not yet exist in the canonical PropertyState.
///
/// When a canonical property already exists, the onboarding
/// flow should use that canonical property directly instead
/// of creating a reduced copy through this adapter.
class PropertyAdapter {
  const PropertyAdapter._();

  static Property fromLegacy(
    legacy.Property property,
  ) {
    return Property(
      id: property.id,
      name: property.name,
      builderName: property.builder,
      ownerName: '',
      address: Address(
        line1: '',
        city: property.city,
        state: '',
        pincode: '',
      ),
      type: PropertyType.apartment,
      yearOfConstruction: 0,
      carpetArea: 0,
      totalUnits: 0,
      compliance: ComplianceSummary(
        verifiedCount: property.verified ? 1 : 0,
        pendingCount: 0,
        issueCount: 0,
        compliancePercentage:
            property.verified ? 100 : 0,
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