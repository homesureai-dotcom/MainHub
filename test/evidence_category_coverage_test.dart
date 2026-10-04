import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceCategoryCoverage', () {
    const firstRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const secondRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    EvidenceValidationResult result(
      EvidenceRequirement requirement,
      EvidenceValidationStatus status,
    ) {
      return EvidenceValidationResult(
        requirement: requirement,
        status: status,
        message: status.name,
      );
    }

    test('calculates complete category coverage', () {
      final coverage = EvidenceCategoryCoverage.calculate(
        categoryId: 'legal_ownership',
        results: [
          result(
            firstRequirement,
            EvidenceValidationStatus.satisfied,
          ),
          result(
            secondRequirement,
            EvidenceValidationStatus.satisfied,
          ),
        ],
      );

      expect(coverage.categoryId, 'legal_ownership');
      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 2);
      expect(coverage.providedRequirements, 0);
      expect(coverage.needsReviewRequirements, 0);
      expect(coverage.missingRequirements, 0);
      expect(coverage.rejectedRequirements, 0);
      expect(coverage.coveragePercentage, 100);
      expect(coverage.isComplete, isTrue);
      expect(coverage.hasEvidenceGaps, isFalse);
    });

    test('calculates partial category coverage', () {
      final coverage = EvidenceCategoryCoverage.calculate(
        categoryId: 'legal_ownership',
        results: [
          result(
            firstRequirement,
            EvidenceValidationStatus.satisfied,
          ),
          result(
            secondRequirement,
            EvidenceValidationStatus.missing,
          ),
        ],
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isTrue);
    });

    test('tracks all validation states separately', () {
      final requirements = [
        firstRequirement,
        secondRequirement,
        const EvidenceRequirement(
          questionId: 'PHS_LEGAL_OC',
          label: 'OC inspection record',
          type: EvidenceType.document,
        ),
        const EvidenceRequirement(
          questionId: 'PHS_LEGAL_OC',
          label: 'OC rejection record',
          type: EvidenceType.document,
        ),
        const EvidenceRequirement(
          questionId: 'PHS_LEGAL_OC',
          label: 'OC review record',
          type: EvidenceType.document,
        ),
      ];

      final coverage = EvidenceCategoryCoverage.calculate(
        categoryId: 'legal_ownership',
        results: [
          result(
            requirements[0],
            EvidenceValidationStatus.satisfied,
          ),
          result(
            requirements[1],
            EvidenceValidationStatus.provided,
          ),
          result(
            requirements[2],
            EvidenceValidationStatus.missing,
          ),
          result(
            requirements[3],
            EvidenceValidationStatus.rejected,
          ),
          result(
            requirements[4],
            EvidenceValidationStatus.needsReview,
          ),
        ],
      );

      expect(coverage.totalRequirements, 5);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.providedRequirements, 1);
      expect(coverage.needsReviewRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.rejectedRequirements, 1);
      expect(coverage.coveragePercentage, 20);
    });

    test('empty category has zero coverage', () {
      final coverage = EvidenceCategoryCoverage.calculate(
        categoryId: 'construction_quality',
        results: const [],
      );

      expect(coverage.categoryId, 'construction_quality');
      expect(coverage.totalRequirements, 0);
      expect(coverage.satisfiedRequirements, 0);
      expect(coverage.coveragePercentage, 0);
      expect(coverage.isComplete, isFalse);
      expect(coverage.hasEvidenceGaps, isFalse);
    });

    test('calculateForRequirements filters unrelated validation results',
        () {
      const unrelatedRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_KHATA',
        label: 'Khata certificate',
        type: EvidenceType.document,
      );

      final coverage =
          EvidenceCategoryCoverage.calculateForRequirements(
        categoryId: 'legal_ownership',
        requirements: [
          firstRequirement,
        ],
        results: [
          result(
            firstRequirement,
            EvidenceValidationStatus.satisfied,
          ),
          result(
            unrelatedRequirement,
            EvidenceValidationStatus.missing,
          ),
        ],
      );

      expect(coverage.totalRequirements, 1);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 0);
      expect(coverage.coveragePercentage, 100);
    });

    test('calculateForRequirements preserves matching requirement identity',
        () {
      final coverage =
          EvidenceCategoryCoverage.calculateForRequirements(
        categoryId: 'legal_ownership',
        requirements: [
          firstRequirement,
          secondRequirement,
        ],
        results: [
          result(
            firstRequirement,
            EvidenceValidationStatus.satisfied,
          ),
          result(
            secondRequirement,
            EvidenceValidationStatus.missing,
          ),
        ],
      );

      expect(coverage.totalRequirements, 2);
      expect(coverage.satisfiedRequirements, 1);
      expect(coverage.missingRequirements, 1);
      expect(coverage.coveragePercentage, 50);
    });

    test('value equality works for identical category coverage', () {
      const first = EvidenceCategoryCoverage(
        categoryId: 'legal_ownership',
        totalRequirements: 4,
        satisfiedRequirements: 2,
        providedRequirements: 1,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      const second = EvidenceCategoryCoverage(
        categoryId: 'legal_ownership',
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

    test('different category coverage values are not equal', () {
      const legal = EvidenceCategoryCoverage(
        categoryId: 'legal_ownership',
        totalRequirements: 2,
        satisfiedRequirements: 2,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 100,
      );

      const construction = EvidenceCategoryCoverage(
        categoryId: 'construction_quality',
        totalRequirements: 2,
        satisfiedRequirements: 1,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      expect(legal, isNot(construction));
    });

    test('toString contains category coverage information', () {
      const coverage = EvidenceCategoryCoverage(
        categoryId: 'legal_ownership',
        totalRequirements: 4,
        satisfiedRequirements: 2,
        providedRequirements: 1,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      );

      final output = coverage.toString();

      expect(output, contains('legal_ownership'));
      expect(output, contains('totalRequirements: 4'));
      expect(output, contains('satisfiedRequirements: 2'));
      expect(output, contains('coveragePercentage: 50.0'));
    });

    test('requirement keys distinguish requirements with different labels',
        () {
      final firstKey =
          EvidenceRequirementKey.fromRequirement(firstRequirement);

      final secondKey =
          EvidenceRequirementKey.fromRequirement(secondRequirement);

      expect(firstKey, isNot(secondKey));
    });

    test('requirement keys are equal for the same question and label', () {
      final firstKey =
          EvidenceRequirementKey.fromRequirement(firstRequirement);

      const equivalentRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'Occupancy Certificate',
        type: EvidenceType.document,
      );

      final secondKey =
          EvidenceRequirementKey.fromRequirement(equivalentRequirement);

      expect(firstKey, secondKey);
      expect(firstKey.hashCode, secondKey.hashCode);
    });
  });
}