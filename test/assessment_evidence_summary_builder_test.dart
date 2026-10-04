import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary_builder.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';

void main() {
  group('AssessmentEvidenceSummaryBuilder', () {
    late AssessmentEvidenceSummaryBuilder builder;

    const occupancyRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const ocReferenceRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    const saleDeedRequirement = EvidenceRequirement(
      questionId: 'LEGAL_SD',
      label: 'Registered Sale Deed',
      type: EvidenceType.document,
    );

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String questionId,
      required String label,
      EvidenceStatus status = EvidenceStatus.verified,
    }) {
      return Evidence(
        id: id,
        questionId: questionId,
        requirementId: Evidence.requirementKey(
          questionId: questionId,
          label: label,
        ),
        type: EvidenceType.document,
        name: label,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    setUp(() {
      builder = const AssessmentEvidenceSummaryBuilder(
        validator: EvidenceValidator(),
      );
    });

    test('builds a complete assessment summary', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
        ),
        createEvidence(
          id: 'E3',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.totalRequirements, 3);
      expect(summary.satisfiedRequirements, 3);
      expect(summary.missingRequirements, 0);
      expect(summary.coveragePercentage, 100);
      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.validationResults.length, 3);
      expect(summary.riskSignals.length, 3);
      expect(summary.activeRiskSignalCount, 0);
      expect(summary.hasEvidenceRisk, isFalse);
      expect(summary.categoryCoverage, isEmpty);
    });

    test('builds a summary containing missing evidence', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.missingRequirements, 1);
      expect(summary.coveragePercentage, 50);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
      expect(summary.hasEvidenceRisk, isTrue);
      expect(summary.activeRiskSignalCount, 1);
    });

    test('builds a summary containing provided but unverified evidence',
        () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          status: EvidenceStatus.provided,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.providedRequirements, 1);
      expect(summary.missingRequirements, 0);
      expect(summary.coveragePercentage, 50);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
      expect(summary.activeRiskSignalCount, 1);
    });

    test('builds a summary containing evidence needing review', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          status: EvidenceStatus.needsReview,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.needsReviewRequirements, 1);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.coveragePercentage, 50);
      expect(summary.hasEvidenceRisk, isTrue);
      expect(summary.activeRiskSignalCount, 1);
    });

    test('builds a summary containing rejected evidence', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
          status: EvidenceStatus.rejected,
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.rejectedRequirements, 1);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.coveragePercentage, 50);
      expect(summary.hasEvidenceRisk, isTrue);
      expect(summary.activeRiskSignalCount, 1);
    });

    test('builds category coverage when category requirements are supplied',
        () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        createEvidence(
          id: 'E2',
          questionId: 'LEGAL_OC',
          label: 'OC approval/reference details',
        ),
        createEvidence(
          id: 'E3',
          questionId: 'LEGAL_SD',
          label: 'Registered Sale Deed',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
          saleDeedRequirement,
        ],
        evidence: evidence,
        categoryRequirements: {
          'LEGAL_OWNERSHIP': [
            occupancyRequirement,
            ocReferenceRequirement,
          ],
          'LEGAL_DOCUMENTATION': [
            saleDeedRequirement,
          ],
        },
      );

      expect(summary.categoryCoverage.length, 2);

      final ownershipCoverage =
          summary.categoryCoverage.firstWhere(
        (coverage) => coverage.categoryId == 'LEGAL_OWNERSHIP',
      );

      final documentationCoverage =
          summary.categoryCoverage.firstWhere(
        (coverage) => coverage.categoryId == 'LEGAL_DOCUMENTATION',
      );

      expect(
        ownershipCoverage.totalRequirements,
        2,
      );

      expect(
        ownershipCoverage.satisfiedRequirements,
        2,
      );

      expect(
        ownershipCoverage.coveragePercentage,
        100,
      );

      expect(
        documentationCoverage.totalRequirements,
        1,
      );

      expect(
        documentationCoverage.satisfiedRequirements,
        1,
      );

      expect(
        documentationCoverage.coveragePercentage,
        100,
      );
    });

    test('builds incomplete category coverage correctly', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: evidence,
        categoryRequirements: {
          'LEGAL_OWNERSHIP': [
            occupancyRequirement,
            ocReferenceRequirement,
          ],
        },
      );

      expect(summary.categoryCoverage.length, 1);

      final coverage = summary.categoryCoverage.single;

      expect(coverage.categoryId, 'LEGAL_OWNERSHIP');
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('returns an empty category coverage list when none is supplied',
        () {
      final summary = builder.build(
        requirements: [
          occupancyRequirement,
        ],
        evidence: const [],
      );

      expect(summary.categoryCoverage, isEmpty);
    });

    test('handles an empty assessment', () {
      final summary = builder.build(
        requirements: const [],
        evidence: const [],
      );

      expect(summary.totalRequirements, 0);
      expect(summary.satisfiedRequirements, 0);
      expect(summary.providedRequirements, 0);
      expect(summary.needsReviewRequirements, 0);
      expect(summary.missingRequirements, 0);
      expect(summary.rejectedRequirements, 0);
      expect(summary.coveragePercentage, 0);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.validationResults, isEmpty);
      expect(summary.riskSignals, isEmpty);
      expect(summary.categoryCoverage, isEmpty);
    });

    test('ignores evidence that does not match a requirement', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Different Document',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.totalRequirements, 1);
      expect(summary.satisfiedRequirements, 0);
      expect(summary.missingRequirements, 1);
      expect(summary.coveragePercentage, 0);
      expect(summary.hasEvidenceRisk, isTrue);
    });

    test('preserves validation result order', () {
      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          saleDeedRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
      );

      expect(
        summary.validationResults[0].requirement,
        occupancyRequirement,
      );

      expect(
        summary.validationResults[1].requirement,
        saleDeedRequirement,
      );

      expect(
        summary.validationResults[2].requirement,
        ocReferenceRequirement,
      );
    });

    test('generates one risk signal for each validation result', () {
      final summary = builder.build(
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
          saleDeedRequirement,
        ],
        evidence: const [],
      );

      expect(
        summary.riskSignals.length,
        summary.validationResults.length,
      );

      expect(
        summary.activeRiskSignalCount,
        3,
      );
    });

    test('uses satisfied evidence without generating active risks', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
      ];

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
        ],
        evidence: evidence,
      );

      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.hasEvidenceRisk, isFalse);
      expect(summary.activeRiskSignalCount, 0);
    });

    test('supports multiple evidence items for the same requirement',
        () {
      final firstEvidence = createEvidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
        status: EvidenceStatus.provided,
      );

      final secondEvidence = createEvidence(
        id: 'E2',
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
        status: EvidenceStatus.verified,
      );

      final summary = builder.build(
        requirements: [
          occupancyRequirement,
        ],
        evidence: [
          firstEvidence,
          secondEvidence,
        ],
      );

      expect(summary.satisfiedRequirements, 1);
      expect(summary.providedRequirements, 0);
      expect(summary.missingRequirements, 0);
      expect(summary.coveragePercentage, 100);
      expect(summary.isComplete, isTrue);
    });
  });
}