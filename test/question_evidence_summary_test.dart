import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/question_evidence_summary.dart';

void main() {
  group('QuestionEvidenceSummary', () {
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

    final addedAt = DateTime(2026, 1, 1);

    Evidence createEvidence({
      required String id,
      required String label,
      EvidenceStatus status = EvidenceStatus.verified,
    }) {
      return Evidence(
        id: id,
        questionId: 'LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: label,
        ),
        type: EvidenceType.document,
        name: label,
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: addedAt,
      );
    }

    test('exposes question ID and requirement count', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      expect(summary.questionId, 'LEGAL_OC');
      expect(summary.totalRequirements, 2);
    });

    test('counts satisfied requirements', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.missing,
          message: 'Required evidence has not been provided.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.satisfiedRequirements, 1);
      expect(summary.missingRequirements, 1);
    });

    test('counts provided requirements', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.provided,
          message: 'Evidence has been provided but is not verified.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.providedRequirements, 1);
      expect(summary.satisfiedRequirements, 1);
    });

    test('counts requirements needing review', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.needsReview,
          message: 'Evidence requires review.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.needsReviewRequirements, 1);
      expect(summary.satisfiedRequirements, 1);
    });

    test('counts rejected requirements', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.rejected,
          message: 'Evidence was rejected.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.rejectedRequirements, 1);
      expect(summary.satisfiedRequirements, 1);
    });

    test('reports complete state when all requirements are satisfied', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
    });

    test('reports evidence gaps when requirements are unresolved', () {
      const results = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
        EvidenceValidationResult(
          requirement: ocReferenceRequirement,
          status: EvidenceValidationStatus.missing,
          message: 'Required evidence has not been provided.',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: const [],
        validationResults: results,
        riskSignals: const [],
      );

      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
    });

    test('reports risk signal counts', () {
      const satisfiedSignal = EvidenceRiskSignal(
        questionId: 'LEGAL_OC',
        requirementLabel: 'Occupancy Certificate',
        validationStatus: EvidenceValidationStatus.satisfied,
        level: EvidenceRiskLevel.none,
        message: 'Evidence requirement is satisfied.',
      );

      const missingSignal = EvidenceRiskSignal(
        questionId: 'LEGAL_OC',
        requirementLabel: 'OC approval/reference details',
        validationStatus: EvidenceValidationStatus.missing,
        level: EvidenceRiskLevel.high,
        message: 'Required evidence has not been provided.',
      );

      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [
          satisfiedSignal,
          missingSignal,
        ],
      );

      expect(summary.riskSignalCount, 2);
      expect(summary.activeRiskSignalCount, 1);
      expect(summary.hasEvidenceRisk, isTrue);
    });

    test('exposes supplied evidence count', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
        createEvidence(
          id: 'E2',
          label: 'OC approval/reference details',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: evidence,
        validationResults: const [],
        riskSignals: const [],
      );

      expect(summary.suppliedEvidence.length, 2);
    });

    test('returns immutable requirements', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      expect(
        () => summary.evidenceRequirements.add(
          ocReferenceRequirement,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns immutable supplied evidence', () {
      final evidence = [
        createEvidence(
          id: 'E1',
          label: 'Occupancy Certificate',
        ),
      ];

      final summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
        ],
        evidence: evidence,
        validationResults: const [],
        riskSignals: const [],
      );

      expect(
        () => summary.suppliedEvidence.add(
          createEvidence(
            id: 'E2',
            label: 'OC approval/reference details',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns immutable validation results', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
        evidence: [],
        validationResults: [
          EvidenceValidationResult(
            requirement: occupancyRequirement,
            status: EvidenceValidationStatus.missing,
            message: 'Required evidence has not been provided.',
          ),
        ],
        riskSignals: [],
      );

      expect(
        () => summary.validations.add(
          const EvidenceValidationResult(
            requirement: occupancyRequirement,
            status: EvidenceValidationStatus.satisfied,
            message: 'Evidence requirement is satisfied.',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns immutable risk signals', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [
          EvidenceRiskSignal(
            questionId: 'LEGAL_OC',
            requirementLabel: 'Occupancy Certificate',
            validationStatus: EvidenceValidationStatus.missing,
            level: EvidenceRiskLevel.high,
            message: 'Required evidence has not been provided.',
          ),
        ],
      );

      expect(
        () => summary.risks.add(
          const EvidenceRiskSignal(
            questionId: 'LEGAL_OC',
            requirementLabel: 'Occupancy Certificate',
            validationStatus: EvidenceValidationStatus.satisfied,
            level: EvidenceRiskLevel.none,
            message: 'Evidence requirement is satisfied.',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('supports value equality', () {
      const validationResults = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      const riskSignals = [
        EvidenceRiskSignal(
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          validationStatus: EvidenceValidationStatus.satisfied,
          level: EvidenceRiskLevel.none,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final evidence = [
        Evidence(
          id: 'E1',
          questionId: 'LEGAL_OC',
          requirementId: Evidence.requirementKey(
            questionId: 'LEGAL_OC',
            label: 'Occupancy Certificate',
          ),
          type: EvidenceType.document,
          name: 'Occupancy Certificate',
          status: EvidenceStatus.verified,
          source: EvidenceSource.userUpload,
          addedAt: addedAt,
        ),
      ];

      final first = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
        ],
        evidence: evidence,
        validationResults: validationResults,
        riskSignals: riskSignals,
      );

      final second = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: const [
          occupancyRequirement,
        ],
        evidence: evidence,
        validationResults: validationResults,
        riskSignals: riskSignals,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different question summaries are not equal', () {
      const first = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      const differentRequirement = EvidenceRequirement(
        questionId: 'LEGAL_SD',
        label: 'Registered Sale Deed',
        type: EvidenceType.document,
      );

      const second = QuestionEvidenceSummary(
        questionId: 'LEGAL_SD',
        requirements: [
          differentRequirement,
        ],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      expect(first, isNot(second));
    });

    test('toString contains key question summary information', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [
          occupancyRequirement,
          ocReferenceRequirement,
        ],
        evidence: [],
        validationResults: [
          EvidenceValidationResult(
            requirement: occupancyRequirement,
            status: EvidenceValidationStatus.missing,
            message: 'Required evidence has not been provided.',
          ),
        ],
        riskSignals: [
          EvidenceRiskSignal(
            questionId: 'LEGAL_OC',
            requirementLabel: 'Occupancy Certificate',
            validationStatus: EvidenceValidationStatus.missing,
            level: EvidenceRiskLevel.high,
            message: 'Required evidence has not been provided.',
          ),
        ],
      );

      final output = summary.toString();

      expect(output, contains('LEGAL_OC'));
      expect(output, contains('totalRequirements: 2'));
      expect(output, contains('evidenceCount: 0'));
      expect(output, contains('riskSignalCount: 1'));
      expect(output, contains('activeRiskSignalCount: 1'));
    });

    test('handles a question with no requirements', () {
      const summary = QuestionEvidenceSummary(
        questionId: 'LEGAL_OC',
        requirements: [],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      expect(summary.totalRequirements, 0);
      expect(summary.satisfiedRequirements, 0);
      expect(summary.missingRequirements, 0);
      expect(summary.providedRequirements, 0);
      expect(summary.needsReviewRequirements, 0);
      expect(summary.rejectedRequirements, 0);
      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.hasEvidenceRisk, isFalse);
    });
  });
}