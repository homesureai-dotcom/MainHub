import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage_calculator.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceCoverageCalculator', () {
    const calculator = EvidenceCoverageCalculator();

    const occupancyRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const approvalRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    Evidence createEvidence({
      required String id,
      required String name,
      required EvidenceStatus status,
    }) {
      return Evidence(
        id: id,
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: name,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );
    }

    test('calculates complete coverage from requirements and evidence', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
          approvalRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_001',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.verified,
          ),
          createEvidence(
            id: 'EVIDENCE_002',
            name: 'OC approval/reference details.pdf',
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 2);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
    });

    test('calculates partial coverage correctly', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
          approvalRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_003',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
      expect(coverage.isComplete, isFalse);
    });

    test('provided evidence is visible but does not count as coverage', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_004',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.provided,
          ),
        ],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.providedRequirements, 1);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('needs-review evidence is visible but does not count as coverage',
        () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_005',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.needsReview,
          ),
        ],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.needsReviewRequirements, 1);
      expect(coverage.coveragePercentage, 0);
    });

    test('rejected evidence is visible but does not count as coverage', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_006',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.rejected,
          ),
        ],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.rejectedRequirements, 1);
      expect(coverage.coveragePercentage, 0);
    });

    test('missing evidence is reported correctly', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
        ],
        evidence: const [],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 0);
    });

    test('empty requirements return empty coverage', () {
      final coverage = calculator.calculate(
        requirements: const [],
        evidence: const [],
      );

      expect(
        coverage,
        const EvidenceCoverage(
          totalRequirements: 0,
          satisfiedRequirements: 0,
          providedRequirements: 0,
          needsReviewRequirements: 0,
          missingRequirements: 0,
          rejectedRequirements: 0,
          coveragePercentage: 0,
        ),
      );
    });

    test('calculateFromResults aggregates existing validation results', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Satisfied',
        ),
        EvidenceValidationResult(
          requirement: approvalRequirement,
          status: EvidenceValidationStatus.missing,
          message: 'Missing',
        ),
      ];

      final coverage = calculator.calculateFromResults(results);

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
    });

    test('validate returns requirement-level validation results', () {
      final results = calculator.validate(
        [
          occupancyRequirement,
          approvalRequirement,
        ],
        [
          createEvidence(
            id: 'EVIDENCE_007',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(results.length, 2);

      expect(
        results[0].status,
        EvidenceValidationStatus.satisfied,
      );

      expect(
        results[1].status,
        EvidenceValidationStatus.missing,
      );
    });

    test('validate preserves requirement order', () {
      final results = calculator.validate(
        [
          approvalRequirement,
          occupancyRequirement,
        ],
        const [],
      );

      expect(
        results.map((result) => result.requirement),
        [
          approvalRequirement,
          occupancyRequirement,
        ],
      );
    });

    test('duplicate evidence does not inflate coverage', () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_008',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.verified,
          ),
          createEvidence(
            id: 'EVIDENCE_009',
            name: 'Occupancy Certificate copy.pdf',
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.coveragePercentage, 100);
    });

    test('same-type document evidence does not satisfy another document requirement',
        () {
      final coverage = calculator.calculate(
        requirements: [
          occupancyRequirement,
          approvalRequirement,
        ],
        evidence: [
          createEvidence(
            id: 'EVIDENCE_010',
            name: 'Occupancy Certificate.pdf',
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
    });
  });
}