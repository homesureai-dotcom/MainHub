import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_data.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/features/property/models/assessment_summary.dart';
import 'package:homesure_ai/features/property/models/compliance_summary.dart';
import 'package:homesure_ai/features/property/models/document_summary.dart';
import 'package:homesure_ai/features/property/models/property.dart';
import 'package:homesure_ai/features/surebot/builders/surebot_context_builder.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';

void main() {
  const property = Property(
    id: 'PROP-001',
    name: 'HomeSure Residency',
    builderName: 'ABC Builders',
    ownerName: 'Vinod',
    address: Address(
      line1: '123 Main Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560001',
    ),
    type: PropertyType.apartment,
    yearOfConstruction: 2022,
    carpetArea: 708,
    totalUnits: 333,
    compliance: ComplianceSummary(
      verifiedCount: 8,
      pendingCount: 2,
      issueCount: 1,
      compliancePercentage: 72.7,
    ),
    assessment: AssessmentSummary(),
    documents: DocumentSummary(
      verifiedDocuments: 7,
      pendingDocuments: 3,
      missingDocuments: 1,
    ),
  );

  const priority = DashboardPriority(
    id: 'OBTAIN_SD',
    title: 'Obtain Registered Sale Deed',
    description:
        'Obtain and verify the registered Sale Deed for the property.',
    priority: RecommendationPriority.critical,
    estimatedPHIGain: 25,
    requiredDocuments: [
      'Registered Sale Deed',
    ],
  );

  const evidenceCoverage = EvidenceCoverage(
    totalRequirements: 5,
    satisfiedRequirements: 2,
    providedRequirements: 1,
    needsReviewRequirements: 1,
    missingRequirements: 1,
    rejectedRequirements: 0,
    coveragePercentage: 40,
  );

  const evidenceSummary = AssessmentEvidenceSummary(
    overallCoverage: evidenceCoverage,
    validationResults: [],
    riskSignals: [],
    categoryCoverage: [],
  );

  DashboardData buildDashboardData() {
    return DashboardData(
      property: property,
      evidenceSummary: evidenceSummary,
      priorities: const [priority],
    );
  }

  group('SureBotContextBuilder', () {
    const builder = SureBotContextBuilder();

    test(
      'builds property context from DashboardData',
      () {
        final context = builder.build(
          buildDashboardData(),
        );

        expect(
          context.property.id,
          'PROP-001',
        );
        expect(
          context.property.name,
          'HomeSure Residency',
        );
        expect(
          context.property.builderName,
          'ABC Builders',
        );
        expect(
          context.property.ownerName,
          'Vinod',
        );
        expect(
          context.property.city,
          'Bengaluru',
        );
        expect(
          context.property.state,
          'Karnataka',
        );
        expect(
          context.property.propertyType,
          'Apartment',
        );
        expect(
          context.property.yearOfConstruction,
          2022,
        );
      },
    );

    test(
      'builds health context when no assessment exists',
      () {
        final context = builder.build(
          buildDashboardData(),
        );

        expect(
          context.health.hasAssessment,
          false,
        );
        expect(
          context.health.score,
          isNull,
        );
        expect(
          context.health.grade,
          isNull,
        );
        expect(
          context.health.isComplete,
          false,
        );
        expect(
          context.health.riskCount,
          0,
        );
        expect(
          context.health.recommendationCount,
          0,
        );
      },
    );

    test(
      'builds evidence context from DashboardData',
      () {
        final context = builder.build(
          buildDashboardData(),
        );

        expect(
          context.evidence.coveragePercentage,
          40,
        );
        expect(
          context.evidence.totalRequirements,
          5,
        );
        expect(
          context.evidence.satisfiedRequirements,
          2,
        );
        expect(
          context.evidence.providedRequirements,
          1,
        );
        expect(
          context.evidence.needsReviewRequirements,
          1,
        );
        expect(
          context.evidence.missingRequirements,
          1,
        );
        expect(
          context.evidence.rejectedRequirements,
          0,
        );
        expect(
          context.evidence.hasGaps,
          true,
        );
      },
    );

    test(
      'builds priority context when a priority is supplied',
      () {
        final context = builder.build(
          buildDashboardData(),
          currentPriority: priority,
        );

        expect(
          context.hasPriority,
          true,
        );

        expect(
          context.currentPriority!.id,
          'OBTAIN_SD',
        );

        expect(
          context.currentPriority!.title,
          'Obtain Registered Sale Deed',
        );

        expect(
          context.currentPriority!.description,
          'Obtain and verify the registered Sale Deed for the property.',
        );

        expect(
          context.currentPriority!.priority,
          RecommendationPriority.critical,
        );

        expect(
          context.currentPriority!.estimatedPHIGain,
          25,
        );

        expect(
          context.currentPriority!.requiredDocuments,
          ['Registered Sale Deed'],
        );
      },
    );

    test(
      'does not create priority context when none is supplied',
      () {
        final context = builder.build(
          buildDashboardData(),
        );

        expect(
          context.hasPriority,
          false,
        );

        expect(
          context.currentPriority,
          isNull,
        );
      },
    );
  });
}
