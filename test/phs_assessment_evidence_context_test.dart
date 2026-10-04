import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context.dart';
import 'package:homesure_ai/core/evidence/phs_question_evidence_context.dart';

void main() {
  group('PHSAssessmentEvidenceContext', () {
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

    PHSQuestionEvidenceContext createCompleteContext({
      String questionId = 'LEGAL_OC',
    }) {
      final validation = EvidenceValidationResult(
        requirement: EvidenceRequirement(
          questionId: questionId,
          label: 'Occupancy Certificate',
          type: EvidenceType.document,
        ),
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement satisfied.',
      );

      return PHSQuestionEvidenceContext(
        questionId: questionId,
        requirements: const [requirement],
        evidence: [evidence],
        validationResults: [validation],
        riskSignals: [
          EvidenceRiskSignal.fromValidationResult(validation),
        ],
      );
    }

    PHSQuestionEvidenceContext createIncompleteContext({
      String questionId = 'LEGAL_SD',
    }) {
      final localRequirement = EvidenceRequirement(
        questionId: questionId,
        label: 'Registered Sale Deed',
        type: EvidenceType.document,
      );

      final validation = EvidenceValidationResult(
        requirement: localRequirement,
        status: EvidenceValidationStatus.missing,
        message: 'Evidence is missing.',
      );

      return PHSQuestionEvidenceContext(
        questionId: questionId,
        requirements: [localRequirement],
        evidence: const [],
        validationResults: [validation],
        riskSignals: [
          EvidenceRiskSignal.fromValidationResult(validation),
        ],
      );
    }

    test('stores question contexts', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
        },
      );

      expect(context.questionCount, 1);
      expect(
        context.getForQuestion('LEGAL_OC'),
        isNotNull,
      );
    });

    test('counts complete questions', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createIncompleteContext(),
        },
      );

      expect(context.completeQuestionCount, 1);
    });

    test('counts questions with evidence gaps', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createIncompleteContext(),
        },
      );

      expect(context.questionsWithEvidenceGaps, 1);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('counts questions with evidence risk', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createIncompleteContext(),
        },
      );

      expect(context.questionsWithEvidenceRisk, 1);
      expect(context.hasEvidenceRisk, isTrue);
    });

    test('is complete when every question is complete', () {
      final first = createCompleteContext(
        questionId: 'LEGAL_OC',
      );
      final second = createCompleteContext(
        questionId: 'LEGAL_SD',
      );

      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': first,
          'LEGAL_SD': second,
        },
      );

      expect(context.questionCount, 2);
      expect(context.completeQuestionCount, 2);
      expect(context.isComplete, isTrue);
      expect(context.hasEvidenceGaps, isFalse);
    });

    test('is incomplete when at least one question has evidence gaps', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createIncompleteContext(),
        },
      );

      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isTrue);
    });

    test('empty assessment is not complete', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {},
      );

      expect(context.questionCount, 0);
      expect(context.completeQuestionCount, 0);
      expect(context.isComplete, isFalse);
      expect(context.hasEvidenceGaps, isFalse);
      expect(context.hasEvidenceRisk, isFalse);
    });

    test('returns the context for a known question', () {
      final questionContext = createCompleteContext();

      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': questionContext,
        },
      );

      expect(
        context.getForQuestion('LEGAL_OC'),
        questionContext,
      );
    });

    test('returns null for an unknown question', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
        },
      );

      expect(
        context.getForQuestion('UNKNOWN'),
        isNull,
      );
    });

    test('reports whether a question is present', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
        },
      );

      expect(
        context.containsQuestion('LEGAL_OC'),
        isTrue,
      );

      expect(
        context.containsQuestion('UNKNOWN'),
        isFalse,
      );
    });

    test('exposes an immutable context map', () {
      final questionContext = createCompleteContext();

      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': questionContext,
        },
      );

      expect(
        () => context.contexts['LEGAL_SD'] = questionContext,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('constructor protects the supplied map from later mutation', () {
      final questionContext = createCompleteContext();

      final source = <String, PHSQuestionEvidenceContext>{
        'LEGAL_OC': questionContext,
      };

      final context = PHSAssessmentEvidenceContext(
        questionContexts: source,
      );

      source.clear();

      expect(context.questionCount, 1);
      expect(context.containsQuestion('LEGAL_OC'), isTrue);
    });

    test('supports value equality', () {
      final firstQuestion = createCompleteContext();
      final secondQuestion = createCompleteContext();

      final first = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': firstQuestion,
        },
      );

      final second = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': secondQuestion,
        },
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('distinguishes contexts with different questions', () {
      final first = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(
            questionId: 'LEGAL_OC',
          ),
        },
      );

      final second = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_SD': createIncompleteContext(
            questionId: 'LEGAL_SD',
          ),
        },
      );

      expect(first, isNot(second));
    });

    test('toString contains useful assessment information', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createIncompleteContext(),
        },
      );

      expect(
        context.toString(),
        contains('questionCount: 2'),
      );
      expect(
        context.toString(),
        contains('completeQuestionCount: 1'),
      );
      expect(
        context.toString(),
        contains('questionsWithEvidenceGaps: 1'),
      );
      expect(
        context.toString(),
        contains('questionsWithEvidenceRisk: 1'),
      );
    });

    test('complete assessment has no evidence risk', () {
      final context = PHSAssessmentEvidenceContext(
        questionContexts: {
          'LEGAL_OC': createCompleteContext(),
          'LEGAL_SD': createCompleteContext(
            questionId: 'LEGAL_SD',
          ),
        },
      );

      expect(context.questionsWithEvidenceRisk, 0);
      expect(context.hasEvidenceRisk, isFalse);
    });
  });
}