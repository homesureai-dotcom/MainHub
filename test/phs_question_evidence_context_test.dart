import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context.dart';

void main() {
  group('PHSQuestionEvidenceContext', () {
    const requirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    final evidence = Evidence(
      id: 'E1',
      questionId: 'LEGAL_OC',
      requirementId: Evidence.requirementKey(
        questionId: 'LEGAL_OC',
        label: 'Occupancy Certificate',
      ),
      type: EvidenceType.document,
      name: 'Occupancy Certificate.pdf',
      status: EvidenceStatus.verified,
      source: EvidenceSource.userUpload,
      addedAt: DateTime(2026, 1, 1),
    );

    final satisfiedValidation = EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.satisfied,
      message: 'Evidence requirement satisfied.',
    );

    final missingValidation = EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.missing,
      message: 'Evidence is missing.',
    );

    final providedValidation = EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.provided,
      message: 'Evidence has been provided.',
    );

    final needsReviewValidation = EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.needsReview,
      message: 'Evidence requires review.',
    );

    final rejectedValidation = EvidenceValidationResult(
      requirement: requirement,
      status: EvidenceValidationStatus.rejected,
      message: 'Evidence was rejected.',
    );

    test('stores the question evidence context', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: const [],
      );

      expect(context.questionId, 'LEGAL_OC');
      expect(context.requirements, [requirement]);
      expect(context.evidence, [evidence]);
      expect(
        context.validationResults,
        [satisfiedValidation],
      );
      expect(context.riskSignals, isEmpty);
    });

    test('calculates total requirements', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: const [],
        riskSignals: const [],
      );

      expect(context.totalRequirements, 1);
    });

    test('counts satisfied requirements', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: const [],
      );

      expect(context.satisfiedRequirements, 1);
    });

    test('counts missing requirements', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: [missingValidation],
        riskSignals: const [],
      );

      expect(context.missingRequirements, 1);
    });

    test('counts provided requirements', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [providedValidation],
        riskSignals: const [],
      );

      expect(context.providedRequirements, 1);
    });

    test('counts requirements needing review', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [needsReviewValidation],
        riskSignals: const [],
      );

      expect(context.needsReviewRequirements, 1);
    });

    test('counts rejected requirements', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [rejectedValidation],
        riskSignals: const [],
      );

      expect(context.rejectedRequirements, 1);
    });

    test('is complete when all requirements are satisfied', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: const [],
      );

      expect(context.isComplete, isTrue);
      expect(context.hasEvidenceGaps, isFalse);
    });

    test('is not complete when a requirement is missing', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: [missingValidation],
        riskSignals: const [],
      );

      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('is not complete when evidence is only provided', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [providedValidation],
        riskSignals: const [],
      );

      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('is not complete when evidence needs review', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [needsReviewValidation],
        riskSignals: const [],
      );

      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('is not complete when evidence is rejected', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [rejectedValidation],
        riskSignals: const [],
      );

      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('empty requirements are not considered complete', () {
      const context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: [],
        evidence: [],
        validationResults: [],
        riskSignals: [],
      );

      expect(context.totalRequirements, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isFalse);
    });

    test('counts active risk signals', () {
      final riskSignal = EvidenceRiskSignal.fromValidationResult(
        missingValidation,
      );

      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: [missingValidation],
        riskSignals: [riskSignal],
      );

      expect(context.activeRiskSignalCount, 1);
      expect(context.hasEvidenceRisk, isTrue);
    });

    test('reports no evidence risk when all signals are clear', () {
      final riskSignal = EvidenceRiskSignal.fromValidationResult(
        satisfiedValidation,
      );

      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: [riskSignal],
      );

      expect(context.activeRiskSignalCount, 0);
      expect(context.hasEvidenceRisk, isFalse);
    });

    test('exposes immutable requirement list', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: const [],
        riskSignals: const [],
      );

      expect(
        () => context.evidenceRequirements.add(requirement),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('exposes immutable evidence list', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: const [],
        riskSignals: const [],
      );

      expect(
        () => context.suppliedEvidence.add(evidence),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('exposes immutable validation list', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: [satisfiedValidation],
        riskSignals: const [],
      );

      expect(
        () => context.validations.add(satisfiedValidation),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('exposes immutable risk list', () {
      final riskSignal = EvidenceRiskSignal.fromValidationResult(
        missingValidation,
      );

      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
        validationResults: [missingValidation],
        riskSignals: [riskSignal],
      );

      expect(
        () => context.risks.add(riskSignal),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('supports value equality', () {
      final riskSignal = EvidenceRiskSignal.fromValidationResult(
        satisfiedValidation,
      );

      final first = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: [riskSignal],
      );

      final second = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: [riskSignal],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('toString includes useful context information', () {
      final context = PHSQuestionEvidenceContext(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [satisfiedValidation],
        riskSignals: const [],
      );

      expect(
        context.toString(),
        contains('LEGAL_OC'),
      );
      expect(
        context.toString(),
        contains('requirements: 1'),
      );
      expect(
        context.toString(),
        contains('evidence: 1'),
      );
    });
  });
}