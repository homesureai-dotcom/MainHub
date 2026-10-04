import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('EvidenceValidator', () {
    const validator = EvidenceValidator();

    const requirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    Evidence createEvidence({
      required EvidenceStatus status,
      String name = 'Occupancy Certificate.pdf',
    }) {
      return Evidence(
        id: 'EVIDENCE_${status.name}',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.document,
        name: name,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );
    }

    test('returns missing when no matching evidence exists', () {
      final result = validator.validate(
        requirement,
        const [],
      );

      expect(
        result.status,
        EvidenceValidationStatus.missing,
      );
      expect(result.isSatisfied, isFalse);
      expect(
        result.message,
        'Required evidence has not been provided.',
      );
    });

    test('returns provided when evidence is supplied but unverified', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.provided,
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.provided,
      );
      expect(result.isSatisfied, isFalse);
      expect(
        result.message,
        'Evidence has been provided but is not verified.',
      );
    });

    test('returns satisfied when evidence is verified', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.satisfied,
      );
      expect(result.isSatisfied, isTrue);
      expect(
        result.message,
        'Evidence requirement is satisfied.',
      );
    });

    test('returns needsReview when matching evidence needs review', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.needsReview,
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.needsReview,
      );
      expect(result.isSatisfied, isFalse);
      expect(
        result.message,
        'Evidence requires review.',
      );
    });

    test('returns rejected when matching evidence is rejected', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.rejected,
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.rejected,
      );
      expect(result.isSatisfied, isFalse);
      expect(
        result.message,
        'Evidence was rejected.',
      );
    });

    test('verified evidence takes precedence over provided evidence', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.provided,
          ),
          createEvidence(
            status: EvidenceStatus.verified,
            name: 'Occupancy Certificate verified.pdf',
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.satisfied,
      );
      expect(result.isSatisfied, isTrue);
    });

    test('verified evidence takes precedence over needsReview evidence',
        () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.needsReview,
          ),
          createEvidence(
            status: EvidenceStatus.verified,
            name: 'Occupancy Certificate verified.pdf',
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.satisfied,
      );
      expect(result.isSatisfied, isTrue);
    });

    test('needsReview takes precedence over provided evidence', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.provided,
          ),
          createEvidence(
            status: EvidenceStatus.needsReview,
            name: 'Occupancy Certificate review.pdf',
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.needsReview,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('provided takes precedence over rejected evidence', () {
      final result = validator.validate(
        requirement,
        [
          createEvidence(
            status: EvidenceStatus.rejected,
          ),
          createEvidence(
            status: EvidenceStatus.provided,
            name: 'Occupancy Certificate replacement.pdf',
          ),
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.provided,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('unrelated evidence is ignored', () {
      final unrelatedEvidence = Evidence(
        id: 'EVIDENCE_UNRELATED',
        questionId: 'PHS_LEGAL_KHATA',
        type: EvidenceType.document,
        name: 'Khata Certificate.pdf',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = validator.validate(
        requirement,
        [
          unrelatedEvidence,
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.missing,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('wrong evidence type is ignored', () {
      final photograph = Evidence(
        id: 'EVIDENCE_PHOTO',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.photograph,
        name: 'Occupancy Certificate.jpg',
        status: EvidenceStatus.verified,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = validator.validate(
        requirement,
        [
          photograph,
        ],
      );

      expect(
        result.status,
        EvidenceValidationStatus.missing,
      );
      expect(result.isSatisfied, isFalse);
    });

    test('validateAll returns one result per requirement', () {
      const secondRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'OC approval/reference details',
        type: EvidenceType.document,
      );

      final results = validator.validateAll(
        [
          requirement,
          secondRequirement,
        ],
        [
          createEvidence(
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

    test('validateAll preserves requirement order', () {
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

      final results = validator.validateAll(
        [
          firstRequirement,
          secondRequirement,
        ],
        const [],
      );

      expect(
        results.map((result) => result.requirement),
        [
          firstRequirement,
          secondRequirement,
        ],
      );
    });
  });
}