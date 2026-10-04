import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_context.dart';
import 'package:homesure_ai/core/evidence/phs_assessment_evidence_integration.dart';
import 'package:homesure_ai/core/engine/models/property_health_result.dart';

void main() {
  late PropertyHealthResult healthResult;
  late PHSAssessmentEvidenceContext evidenceContext;

  setUp(() {
    healthResult = PropertyHealthResult(
      overallScore: 82.0,
      categoryScores: const {},
      risks: const [],
      recommendations: const [],
      evaluatedQuestionCount: 33,
      totalQuestionCount: 33,
      evaluatedCategoryCount: 6,
      totalCategoryCount: 6,
      evaluatedAt: DateTime(2026, 1, 1),
    );

    evidenceContext = PHSAssessmentEvidenceContext(
      questionContexts: {},
    );
  });

  test(
    'stores the PHS health result and evidence context',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(integration.healthResult, healthResult);
      expect(integration.evidenceContext, evidenceContext);
    },
  );

  test(
    'exposes evidence gap state from the evidence context',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.hasEvidenceGaps,
        evidenceContext.hasEvidenceGaps,
      );
    },
  );

  test(
    'exposes evidence risk state from the evidence context',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.hasEvidenceRisk,
        evidenceContext.hasEvidenceRisk,
      );
    },
  );

  test(
    'exposes evidence completeness from the evidence context',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.isEvidenceComplete,
        evidenceContext.isComplete,
      );
    },
  );

  test(
    'exposes assessment question count',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.questionCount,
        evidenceContext.questionCount,
      );
    },
  );

  test(
    'exposes complete question count',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.completeQuestionCount,
        evidenceContext.completeQuestionCount,
      );
    },
  );

  test(
    'exposes questions with evidence gaps',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.questionsWithEvidenceGaps,
        evidenceContext.questionsWithEvidenceGaps,
      );
    },
  );

  test(
    'exposes questions with evidence risk',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(
        integration.questionsWithEvidenceRisk,
        evidenceContext.questionsWithEvidenceRisk,
      );
    },
  );

  test(
    'copyWith can replace the health result',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final replacement = PropertyHealthResult(
        overallScore: 65.0,
        categoryScores: const {},
        risks: const [],
        recommendations: const [],
        evaluatedQuestionCount: 30,
        totalQuestionCount: 33,
        evaluatedCategoryCount: 5,
        totalCategoryCount: 6,
        evaluatedAt: DateTime(2026, 1, 2),
      );

      final copied = integration.copyWith(
        healthResult: replacement,
      );

      expect(copied.healthResult, replacement);
      expect(copied.evidenceContext, evidenceContext);
    },
  );

  test(
    'copyWith can replace the evidence context',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final replacement = PHSAssessmentEvidenceContext(
        questionContexts: {},
      );

      final copied = integration.copyWith(
        evidenceContext: replacement,
      );

      expect(copied.healthResult, healthResult);
      expect(copied.evidenceContext, replacement);
    },
  );

  test(
    'copyWith without changes preserves the integration',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final copied = integration.copyWith();

      expect(copied, integration);
      expect(copied.hashCode, integration.hashCode);
    },
  );

  test(
    'equality compares health result and evidence context',
    () {
      final first = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final second = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      expect(first, second);
    },
  );

  test(
    'different health result instances make integrations unequal',
    () {
      final first = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final second = PHSAssessmentEvidenceIntegration(
        healthResult: PropertyHealthResult(
          overallScore: 60.0,
          categoryScores: const {},
          risks: const [],
          recommendations: const [],
          evaluatedQuestionCount: 25,
          totalQuestionCount: 33,
          evaluatedCategoryCount: 4,
          totalCategoryCount: 6,
          evaluatedAt: DateTime(2026, 1, 3),
        ),
        evidenceContext: evidenceContext,
      );

      expect(first, isNot(second));
    },
  );

  test(
    'toString identifies the integration and evidence summary',
    () {
      final integration = PHSAssessmentEvidenceIntegration(
        healthResult: healthResult,
        evidenceContext: evidenceContext,
      );

      final value = integration.toString();

      expect(
        value,
        contains('PHSAssessmentEvidenceIntegration'),
      );
      expect(value, contains('questionCount: 0'));
      expect(value, contains('completeQuestionCount: 0'));
      expect(
        value,
        contains('questionsWithEvidenceGaps: 0'),
      );
      expect(
        value,
        contains('questionsWithEvidenceRisk: 0'),
      );
    },
  );
}