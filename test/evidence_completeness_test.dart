import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_completeness.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';

void main() {
  group('EvidenceCompleteness', () {
    const documentRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const approvalRequirement = EvidenceRequirement(
      questionId: 'PHS_LEGAL_OC',
      label: 'OC approval/reference details',
      type: EvidenceType.document,
    );

    final documentEvidence = Evidence(
      id: 'EVIDENCE_001',
      questionId: 'PHS_LEGAL_OC',
      type: EvidenceType.document,
      name: 'Occupancy Certificate.pdf',
      status: EvidenceStatus.provided,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 9, 19),
    );

    test('calculates complete coverage when every requirement matches',
        () {
      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
          approvalRequirement,
        ],
        evidence: [
          documentEvidence,
          Evidence(
            id: 'EVIDENCE_002',
            questionId: 'PHS_LEGAL_OC',
            type: EvidenceType.document,
            name: 'OC approval/reference details.pdf',
            status: EvidenceStatus.provided,
            source: EvidenceSource.userUpload,
            addedAt: DateTime(2026, 9, 19),
          ),
        ],
      );

      expect(result.totalRequirements, 2);
      expect(result.matchedRequirements, 2);
      expect(result.missingRequirements, 0);
      expect(result.coveragePercentage, 100);
      expect(result.isComplete, isTrue);
      expect(result.hasMissingEvidence, isFalse);
    });

    test('calculates partial coverage when some requirements match', () {
      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
          approvalRequirement,
        ],
        evidence: [
          documentEvidence,
        ],
      );

      expect(result.totalRequirements, 2);
      expect(result.matchedRequirements, 1);
      expect(result.missingRequirements, 1);
      expect(result.coveragePercentage, 50);
      expect(result.isComplete, isFalse);
      expect(result.hasMissingEvidence, isTrue);
    });

    test('calculates zero coverage when no requirements match', () {
      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
          approvalRequirement,
        ],
        evidence: const [],
      );

      expect(result.totalRequirements, 2);
      expect(result.matchedRequirements, 0);
      expect(result.missingRequirements, 2);
      expect(result.coveragePercentage, 0);
      expect(result.isComplete, isFalse);
      expect(result.hasMissingEvidence, isTrue);
    });

    test('returns zero coverage for an empty requirement list', () {
      final result = EvidenceCompleteness.calculate(
        requirements: const [],
        evidence: [
          documentEvidence,
        ],
      );

      expect(result.totalRequirements, 0);
      expect(result.matchedRequirements, 0);
      expect(result.missingRequirements, 0);
      expect(result.coveragePercentage, 0);
      expect(result.isComplete, isFalse);
      expect(result.hasMissingEvidence, isFalse);
    });

    test('duplicate evidence does not inflate requirement coverage', () {
      final duplicateEvidence = documentEvidence.copyWith(
        id: 'EVIDENCE_003',
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
        ],
        evidence: [
          documentEvidence,
          duplicateEvidence,
        ],
      );

      expect(result.totalRequirements, 1);
      expect(result.matchedRequirements, 1);
      expect(result.missingRequirements, 0);
      expect(result.coveragePercentage, 100);
    });

    test('unrelated evidence does not count toward completeness', () {
      final unrelatedEvidence = Evidence(
        id: 'EVIDENCE_004',
        questionId: 'PHS_LEGAL_KHATA',
        type: EvidenceType.document,
        name: 'Khata Certificate.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
        ],
        evidence: [
          unrelatedEvidence,
        ],
      );

      expect(result.totalRequirements, 1);
      expect(result.matchedRequirements, 0);
      expect(result.missingRequirements, 1);
      expect(result.coveragePercentage, 0);
    });

    test('different evidence type does not count toward completeness', () {
      final photographEvidence = Evidence(
        id: 'EVIDENCE_005',
        questionId: 'PHS_LEGAL_OC',
        type: EvidenceType.photograph,
        name: 'OC photograph.jpg',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
        ],
        evidence: [
          photographEvidence,
        ],
      );

      expect(result.totalRequirements, 1);
      expect(result.matchedRequirements, 0);
      expect(result.missingRequirements, 1);
      expect(result.coveragePercentage, 0);
    });

    test('coverage percentage is calculated correctly for one of three',
        () {
      final thirdRequirement = EvidenceRequirement(
        questionId: 'PHS_LEGAL_OC',
        label: 'OC reference number',
        type: EvidenceType.document,
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
          approvalRequirement,
          thirdRequirement,
        ],
        evidence: [
          documentEvidence,
        ],
      );

      expect(result.totalRequirements, 3);
      expect(result.matchedRequirements, 1);
      expect(result.missingRequirements, 2);
      expect(
        result.coveragePercentage,
        closeTo(33.333333, 0.000001),
      );
    });

    test('explicit requirement ID takes precedence over text matching', () {
      final evidence = Evidence(
        id: 'EVIDENCE_006',
        questionId: 'PHS_LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'PHS_LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'Some unrelated filename.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
        ],
        evidence: [
          evidence,
        ],
      );

      expect(result.matchedRequirements, 1);
      expect(result.missingRequirements, 0);
      expect(result.coveragePercentage, 100);
    });

    test('wrong explicit requirement ID does not match', () {
      final evidence = Evidence(
        id: 'EVIDENCE_007',
        questionId: 'PHS_LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'PHS_LEGAL_OC',
          label: 'OC approval/reference details',
        ),
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: EvidenceStatus.provided,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 9, 19),
      );

      final result = EvidenceCompleteness.calculate(
        requirements: [
          documentRequirement,
        ],
        evidence: [
          evidence,
        ],
      );

      expect(result.matchedRequirements, 0);
      expect(result.missingRequirements, 1);
      expect(result.coveragePercentage, 0);
    });

    test('value equality works for identical results', () {
      const first = EvidenceCompleteness(
        totalRequirements: 2,
        matchedRequirements: 1,
        missingRequirements: 1,
        coveragePercentage: 50,
      );

      const second = EvidenceCompleteness(
        totalRequirements: 2,
        matchedRequirements: 1,
        missingRequirements: 1,
        coveragePercentage: 50,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different completeness results are not equal', () {
      const complete = EvidenceCompleteness(
        totalRequirements: 2,
        matchedRequirements: 2,
        missingRequirements: 0,
        coveragePercentage: 100,
      );

      const partial = EvidenceCompleteness(
        totalRequirements: 2,
        matchedRequirements: 1,
        missingRequirements: 1,
        coveragePercentage: 50,
      );

      expect(complete, isNot(partial));
    });

    test('toString contains completeness information', () {
      const result = EvidenceCompleteness(
        totalRequirements: 2,
        matchedRequirements: 1,
        missingRequirements: 1,
        coveragePercentage: 50,
      );

      final output = result.toString();

      expect(output, contains('totalRequirements: 2'));
      expect(output, contains('matchedRequirements: 1'));
      expect(output, contains('missingRequirements: 1'));
      expect(output, contains('coveragePercentage: 50.0'));
    });
  });
}