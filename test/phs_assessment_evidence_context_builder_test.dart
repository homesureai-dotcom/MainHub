import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context_builder.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context.dart';

void main() {
  group('PHSAssessmentEvidenceContextBuilder', () {
    PHSQuestionEvidenceContext createContext({
      required String questionId,
      required EvidenceValidationStatus status,
    }) {
      final requirement = EvidenceRequirement(
        questionId: questionId,
        label: 'Test Evidence',
        type: EvidenceType.document,
      );

      final validation = EvidenceValidationResult(
        requirement: requirement,
        status: status,
        message: 'Test validation result.',
      );

      return PHSQuestionEvidenceContext(
        questionId: questionId,
        requirements: [requirement],
        evidence: const [],
        validationResults: [validation],
        riskSignals: const [],
      );
    }

    test('builds an empty assessment context from no question contexts', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final result = builder.build(const []);

      expect(result, isA<PHSAssessmentEvidenceContext>());
      expect(result.questionCount, 0);
      expect(result.completeQuestionCount, 0);
      expect(result.hasEvidenceGaps, isFalse);
      expect(result.hasEvidenceRisk, isFalse);
      expect(result.isComplete, isFalse);
    });

    test('builds context from a single question context', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final questionContext = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final result = builder.build([questionContext]);

      expect(result.questionCount, 1);
      expect(
        result.getForQuestion('LEGAL_OC'),
        questionContext,
      );
    });

    test('builds context from multiple question contexts', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final first = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final second = createContext(
        questionId: 'LEGAL_SD',
        status: EvidenceValidationStatus.missing,
      );

      final third = createContext(
        questionId: 'LEGAL_KHATA',
        status: EvidenceValidationStatus.provided,
      );

      final result = builder.build([
        first,
        second,
        third,
      ]);

      expect(result.questionCount, 3);
      expect(result.containsQuestion('LEGAL_OC'), isTrue);
      expect(result.containsQuestion('LEGAL_SD'), isTrue);
      expect(result.containsQuestion('LEGAL_KHATA'), isTrue);
    });

    test('uses question IDs as assessment context keys', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final first = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final second = createContext(
        questionId: 'LEGAL_SD',
        status: EvidenceValidationStatus.missing,
      );

      final result = builder.build([
        first,
        second,
      ]);

      expect(result.contexts.keys, [
        'LEGAL_OC',
        'LEGAL_SD',
      ]);
    });

    test('preserves the original question context objects', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final questionContext = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final result = builder.build([questionContext]);

      expect(
        identical(
          result.getForQuestion('LEGAL_OC'),
          questionContext,
        ),
        isTrue,
      );
    });

    test('aggregates complete-question state', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final complete = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final incomplete = createContext(
        questionId: 'LEGAL_SD',
        status: EvidenceValidationStatus.missing,
      );

      final result = builder.build([
        complete,
        incomplete,
      ]);

      expect(result.completeQuestionCount, 1);
      expect(result.isComplete, isFalse);
    });

    test('aggregates evidence-gap state', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final complete = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final incomplete = createContext(
        questionId: 'LEGAL_SD',
        status: EvidenceValidationStatus.missing,
      );

      final result = builder.build([
        complete,
        incomplete,
      ]);

      expect(result.questionsWithEvidenceGaps, 1);
      expect(result.hasEvidenceGaps, isTrue);
    });

    test('does not perform validation itself', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final questionContext = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.needsReview,
      );

      final result = builder.build([questionContext]);

      expect(
        result.getForQuestion('LEGAL_OC')?.needsReviewRequirements,
        1,
      );
    });

    test('does not modify the supplied question context list', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final questionContext = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final source = <PHSQuestionEvidenceContext>[
        questionContext,
      ];

      final result = builder.build(source);

      source.clear();

      expect(result.questionCount, 1);
      expect(result.containsQuestion('LEGAL_OC'), isTrue);
    });

    test('later duplicate question context replaces the earlier entry',
        () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final first = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.missing,
      );

      final second = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final result = builder.build([
        first,
        second,
      ]);

      expect(result.questionCount, 1);
      expect(
        result.getForQuestion('LEGAL_OC'),
        second,
      );
    });

    test('preserves insertion order of unique question IDs', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final contexts = [
        createContext(
          questionId: 'LEGAL_OC',
          status: EvidenceValidationStatus.satisfied,
        ),
        createContext(
          questionId: 'LEGAL_SD',
          status: EvidenceValidationStatus.missing,
        ),
        createContext(
          questionId: 'LEGAL_KHATA',
          status: EvidenceValidationStatus.provided,
        ),
      ];

      final result = builder.build(contexts);

      expect(
        result.contexts.keys.toList(),
        [
          'LEGAL_OC',
          'LEGAL_SD',
          'LEGAL_KHATA',
        ],
      );
    });

    test('does not calculate or modify PHS scoring', () {
      const builder = PHSAssessmentEvidenceContextBuilder();

      final questionContext = createContext(
        questionId: 'LEGAL_OC',
        status: EvidenceValidationStatus.satisfied,
      );

      final result = builder.build([questionContext]);

      expect(result.questionCount, 1);
      expect(result.getForQuestion('LEGAL_OC'), questionContext);
    });
  });
}