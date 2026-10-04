import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement_matcher.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validator.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context_builder.dart';

void main() {
  group('PHSQuestionEvidenceContextBuilder', () {
    late PHSQuestionEvidenceContextBuilder builder;

    setUp(() {
      builder = PHSQuestionEvidenceContextBuilder(
        validator: EvidenceValidator(
          matcher: EvidenceRequirementMatcher(),
        ),
      );
    });

    const requirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    Evidence createEvidence({
      required EvidenceStatus status,
    }) {
      return Evidence(
        id: 'E1',
        questionId: 'LEGAL_OC',
        requirementId: Evidence.requirementKey(
          questionId: 'LEGAL_OC',
          label: 'Occupancy Certificate',
        ),
        type: EvidenceType.document,
        name: 'Occupancy Certificate.pdf',
        status: status,
        source: EvidenceSource.userUpload,
        addedAt: DateTime(2026, 1, 1),
      );
    }

    test('builds context for satisfied evidence', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(context, isA<PHSQuestionEvidenceContext>());
      expect(context.questionId, 'LEGAL_OC');
      expect(context.totalRequirements, 1);
      expect(context.satisfiedRequirements, 1);
      expect(context.isComplete, isTrue);
      expect(context.hasEvidenceGaps, isFalse);
    });

    test('builds missing evidence context when no evidence is supplied', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
      );

      expect(context.totalRequirements, 1);
      expect(context.missingRequirements, 1);
      expect(context.satisfiedRequirements, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('builds provided evidence context', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.provided,
          ),
        ],
      );

      expect(context.providedRequirements, 1);
      expect(context.satisfiedRequirements, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('builds needs-review evidence context', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.needsReview,
          ),
        ],
      );

      expect(context.needsReviewRequirements, 1);
      expect(context.satisfiedRequirements, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('builds rejected evidence context', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.rejected,
          ),
        ],
      );

      expect(context.rejectedRequirements, 1);
      expect(context.satisfiedRequirements, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('generates risk signals from validation results', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: const [],
      );

      expect(context.riskSignals, hasLength(1));
      expect(context.activeRiskSignalCount, 1);
      expect(context.hasEvidenceRisk, isTrue);
      expect(
        context.riskSignals.first,
        isA<EvidenceRiskSignal>(),
      );
    });

    test('generates no active risk for satisfied evidence', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(context.riskSignals, hasLength(1));
      expect(context.activeRiskSignalCount, 0);
      expect(context.hasEvidenceRisk, isFalse);
    });

    test('preserves supplied requirements and evidence', () {
      final evidence = createEvidence(
        status: EvidenceStatus.verified,
      );

      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [evidence],
      );

      expect(context.requirements, [requirement]);
      expect(context.evidence, [evidence]);
    });

    test('builds an empty context when there are no requirements', () {
      const contextRequirements = <EvidenceRequirement>[];
      const contextEvidence = <Evidence>[];

      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: contextRequirements,
        evidence: contextEvidence,
      );

      expect(context.totalRequirements, 0);
      expect(context.validationResults, isEmpty);
      expect(context.riskSignals, isEmpty);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isFalse);
      expect(context.hasEvidenceRisk, isFalse);
    });

    test('does not modify PHS scoring through evidence context creation', () {
      final context = builder.build(
        questionId: 'LEGAL_OC',
        requirements: const [requirement],
        evidence: [
          createEvidence(
            status: EvidenceStatus.verified,
          ),
        ],
      );

      expect(context.questionId, 'LEGAL_OC');
      expect(context.isComplete, isTrue);

      // The builder produces evidence context only. No PHS score,
      // weight, or assessment score is calculated or modified here.
      expect(context.validationResults, hasLength(1));
    });

    test('uses the supplied question ID as the context identity', () {
      final context = builder.build(
        questionId: 'CUSTOM_QUESTION',
        requirements: const [],
        evidence: const [],
      );

      expect(context.questionId, 'CUSTOM_QUESTION');
    });
  });
}