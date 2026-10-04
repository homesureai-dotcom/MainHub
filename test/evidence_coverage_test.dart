import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceCoverage', () {
    const requirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    EvidenceValidationResult result(
      EvidenceValidationStatus status,
    ) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: status,
        message: status.name,
      );
    }

    test('calculates 100 percent coverage when all requirements are satisfied',
        () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.satisfied),
        result(EvidenceValidationStatus.satisfied),
        result(EvidenceValidationStatus.satisfied),
      ]);

      expect(coverage.totalRequirements, 3);
      expect(coverage.satisfiedRequirements, 3);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
      expect(coverage.hasEvidenceGaps, isFalse);
    });

    test('calculates partial coverage correctly', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.satisfied),
        result(EvidenceValidationStatus.provided),
        result(EvidenceValidationStatus.missing),
        result(EvidenceValidationStatus.rejected),
      ]);

      expect(coverage.totalRequirements, 4);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.providedRequirements, 1);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 1);
      expect(coverage.rejectedRequirements, 1);
      expect(coverage.coveragePercentage, 25);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('counts needs-review requirements separately', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.satisfied),
        result(EvidenceValidationStatus.needsReview),
        result(EvidenceValidationStatus.needsReview),
      ]);

      expect(coverage.totalRequirements, 3);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 2);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(
        coverage.coveragePercentage,
        closeTo(33.333333, 0.000001),
      );
    });

    test('counts provided requirements separately', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.provided),
        result(EvidenceValidationStatus.provided),
      ]);

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.providedRequirements, 2);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('counts missing requirements separately', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.missing),
        result(EvidenceValidationStatus.missing),
      ]);

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 2);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('counts rejected requirements separately', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.rejected),
      ]);

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 1);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('returns zero coverage for an empty result list', () {
      final coverage = EvidenceCoverage.calculate(const []);

      expect(coverage.totalRequirements, 0);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isFalse);
    });

    test('only satisfied requirements contribute to coverage', () {
      final coverage = EvidenceCoverage.calculate([
        result(EvidenceValidationStatus.satisfied),
        result(EvidenceValidationStatus.provided),
        result(EvidenceValidationStatus.needsReview),
        result(EvidenceValidationStatus.missing),
        result(EvidenceValidationStatus.rejected),
      ]);

      expect(coverage.totalRequirements, 5);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.coveragePercentage, 20);
    });

    test('value equality works for identical coverage results', () {
      const first = EvidenceCoverage(
        totalRequirements: 4,
        satisfiedRequirements: 2,
        providedRequirements: 1,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      const second = EvidenceCoverage(
        totalRequirements: 4,
        satisfiedRequirements: 2,
        providedRequirements: 1,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different coverage results are not equal', () {
      const complete = EvidenceCoverage(
        totalRequirements: 2,
        satisfiedRequirements: 2,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 100,
      );

      const partial = EvidenceCoverage(
        totalRequirements: 2,
        satisfiedRequirements: 1,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      expect(complete, isNot(partial));
    });

    test('toString contains coverage information', () {
      const coverage = EvidenceCoverage(
        totalRequirements: 4,
        satisfiedRequirements: 2,
        providedRequirements: 1,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      final output = coverage.toString();

      expect(output, contains('totalRequirements: 4'));
      expect(output, contains('satisfiedRequirements: 2'));
      expect(output, contains('providedRequirements: 1'));
      expect(output, contains('missingRequirements: 1'));
      expect(output, contains('coveragePercentage: 50.0'));
    });
  });
}