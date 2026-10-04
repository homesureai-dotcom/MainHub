import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceValidationResult', () {
    const requirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    test('can represent a satisfied evidence requirement', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );

      expect(result.requirement, requirement);
      expect(
        result.status,
        EvidenceValidationStatus.satisfied,
      );
      expect(
        result.message,
        'Evidence requirement is satisfied.',
      );
      expect(result.isSatisfied, isTrue);
    });

    test('can represent a missing evidence requirement', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.missing,
        message: 'Required evidence has not been provided.',
      );

      expect(
        result.status,
        EvidenceValidationStatus.missing,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('can represent a provided but unverified requirement', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.provided,
        message: 'Evidence has been provided but is not verified.',
      );

      expect(
        result.status,
        EvidenceValidationStatus.provided,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('can represent an evidence requirement needing review', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.needsReview,
        message: 'Evidence requires review.',
      );

      expect(
        result.status,
        EvidenceValidationStatus.needsReview,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('can represent a rejected evidence requirement', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.rejected,
        message: 'Evidence was rejected.',
      );

      expect(
        result.status,
        EvidenceValidationStatus.rejected,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('supports value equality', () {
      const first = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );

      const second = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different validation results are not equal', () {
      const satisfied = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );

      const missing = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.missing,
        message: 'Required evidence has not been provided.',
      );

      expect(satisfied, isNot(missing));
    });

    test('toString contains the key validation information', () {
      const result = EvidenceValidationResult(
        requirement: requirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      );

      final output = result.toString();

      expect(output, contains('LEGAL_OC'));
      expect(output, contains('Occupancy Certificate'));
      expect(output, contains('satisfied'));
    });
  });
}