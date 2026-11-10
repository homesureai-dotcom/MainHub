import '../../../models/property.dart' as legacy;

import 'assessment_summary.dart';
import 'compliance_summary.dart';
import 'document_summary.dart';
import 'property.dart';

/// Converts the onboarding/catalogue [legacy.Property] model into
/// the canonical feature [Property] model used by
/// `PropertyState` and the dashboard.
///
/// Catalogue inclusion and the legacy verification flag
/// are not proof of legal or regulatory compliance.
/// Compliance must be based on independently reviewed evidence.
class PropertyAdapter {
  const PropertyAdapter._();

  static Property fromLegacy(legacy.Property property) {
    final lowerType = property.projectType.toLowerCase();
    PropertyType mappedType = PropertyType.apartment;
    if (lowerType.contains('plot')) {
      mappedType = PropertyType.plot;
    } else if (lowerType.contains('commercial')) {
      mappedType = PropertyType.commercial;
    } else if (lowerType.contains('villa')) {
      mappedType = PropertyType.villa;
    }

    int parsedUnits = 0;
    final unitsMetric = property.summaryMetrics['total_units_inventories'];
    if (unitsMetric != null && unitsMetric.observationState.hasData) {
      parsedUnits = int.tryParse(unitsMetric.value?.toString() ?? '') ?? 0;
    }

    double parsedCarpet = 0;
    final carpetMetric = property.summaryMetrics['total_carpet_area_sq_m'];
    if (carpetMetric != null && carpetMetric.observationState.hasData) {
      final cleaned = (carpetMetric.value?.toString() ?? '').replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      parsedCarpet = double.tryParse(cleaned) ?? 0;
    }

    int parsedYear = 0;
    if (property.proposedCompletionDate.length >= 4) {
      parsedYear =
          int.tryParse(property.proposedCompletionDate.substring(0, 4)) ?? 0;
    }

    final totalDocs = property.regulatoryCounts['total_documents'] ?? 0;

    return Property(
      id: property.id,
      name: property.name,
      builderName: property.builder,
      ownerName: '',
      address: Address(
        line1: property.locality,
        city: property.city,
        state: 'Karnataka',
        pincode: '',
      ),
      type: mappedType,
      yearOfConstruction: parsedYear,
      carpetArea: parsedCarpet,
      totalUnits: parsedUnits,
      reraNumber: property.reraNumber,
      acknowledgementNumber: property.acknowledgementNumber,
      regulatoryStatus: property.regulatoryStatus,
      proposedCompletionDate: property.proposedCompletionDate,
      summaryMetrics: property.summaryMetrics,
      unitHierarchyStatus: property.unitHierarchyStatus,
      compliance: const ComplianceSummary(
        verifiedCount: 0,
        pendingCount: 1,
        issueCount: 0,
        compliancePercentage: 0,
      ),
      assessment: const AssessmentSummary(),
      documents: DocumentSummary(
        verifiedDocuments: 0,
        pendingDocuments: totalDocs,
        missingDocuments: 0,
      ),
    );
  }
}
