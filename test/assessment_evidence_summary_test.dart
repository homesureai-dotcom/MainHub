import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';

void main() {
  group('AssessmentEvidenceSummary', () {
    const occupancyRequirement = EvidenceRequirement(
      questionId: 'LEGAL_OC',
      label: 'Occupancy Certificate',
      type: EvidenceType.document,
    );

    const saleDeedRequirement = EvidenceRequirement(
      questionId: 'LEGAL_SD',
      label: 'Registered Sale Deed',
      type: EvidenceType.document,
    );

    const coverage = EvidenceCoverage(
      totalRequirements: 2,
      satisfiedRequirements: 1,
      providedRequirements: 0,
      needsReviewRequirements: 0,
      missingRequirements: 1,
      rejectedRequirements: 0,
      coveragePercentage: 50,
    );

    final validationResults = [
      const EvidenceValidationResult(
        requirement: occupancyRequirement,
        status: EvidenceValidationStatus.satisfied,
        message: 'Evidence requirement is satisfied.',
      ),
      const EvidenceValidationResult(
        requirement: saleDeedRequirement,
        status: EvidenceValidationStatus.missing,
        message: 'Required evidence has not been provided.',
      ),
    ];

    final riskSignals = [
      EvidenceRiskSignal.fromValidationResult(
        validationResults[0],
      ),
      EvidenceRiskSignal.fromValidationResult(
        validationResults[1],
      ),
    ];

    final categoryCoverage = [
      EvidenceCategoryCoverage.calculate(
        categoryId: 'LEGAL_OWNERSHIP',
        results: validationResults,
      ),
    ];

    test('exposes overall coverage values', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.totalRequirements, 2);
      expect(summary.satisfiedRequirements, 1);
      expect(summary.providedRequirements, 0);
      expect(summary.needsReviewRequirements, 0);
      expect(summary.missingRequirements, 1);
      expect(summary.rejectedRequirements, 0);
      expect(summary.coveragePercentage, 50);
    });

    test('reports completion state from overall coverage', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.isComplete, isFalse);
      expect(summary.hasEvidenceGaps, isTrue);
    });

    test('reports risk signal counts', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.riskSignalCount, 2);
      expect(summary.activeRiskSignalCount, 1);
      expect(summary.hasEvidenceRisk, isTrue);
    });

    test('exposes validation results through results getter', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.results, validationResults);
      expect(summary.results.length, 2);
    });

    test('exposes risk signals through risks getter', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.risks, riskSignals);
      expect(summary.risks.length, 2);
    });

    test('exposes category coverage through categories getter', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(summary.categories, categoryCoverage);
      expect(summary.categories.length, 1);
      expect(
        summary.categories.single.categoryId,
        'LEGAL_OWNERSHIP',
      );
    });

    test('returns immutable validation results', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(
        () => summary.results.add(
          const EvidenceValidationResult(
            requirement: occupancyRequirement,
            status: EvidenceValidationStatus.provided,
            message: 'Evidence has been provided but is not verified.',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns immutable risk signals', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(
        () => summary.risks.add(
          EvidenceRiskSignal.fromValidationResult(
            validationResults[0],
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('returns immutable category coverage', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(
        () => summary.categories.add(
          EvidenceCategoryCoverage.calculate(
            categoryId: 'DOCUMENTATION',
            results: validationResults,
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('supports value equality', () {
      final first = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      final second = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different summaries are not equal', () {
      final first = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      const differentCoverage = EvidenceCoverage(
        totalRequirements: 2,
        satisfiedRequirements: 2,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 100,
      );

      final second = AssessmentEvidenceSummary(
        overallCoverage: differentCoverage,
        validationResults: const [],
        riskSignals: const [],
        categoryCoverage: const [],
      );

      expect(first, isNot(second));
    });

    test('toString contains key summary information', () {
      final summary = AssessmentEvidenceSummary(
        overallCoverage: coverage,
        validationResults: validationResults,
        riskSignals: riskSignals,
        categoryCoverage: categoryCoverage,
      );

      final output = summary.toString();

      expect(
        output,
        contains('totalRequirements: 2'),
      );
      expect(
        output,
        contains('satisfiedRequirements: 1'),
      );
      expect(
        output,
        contains('missingRequirements: 1'),
      );
      expect(
        output,
        contains('coveragePercentage: 50.0'),
      );
      expect(
        output,
        contains('activeRiskSignalCount: 1'),
      );
    });

    test('supports a fully complete summary', () {
      const completeCoverage = EvidenceCoverage(
        totalRequirements: 2,
        satisfiedRequirements: 2,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 100,
      );

      const completeValidationResults = [
        EvidenceValidationResult(
          requirement: occupancyRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
        EvidenceValidationResult(
          requirement: saleDeedRequirement,
          status: EvidenceValidationStatus.satisfied,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      const completeRiskSignals = [
        EvidenceRiskSignal(
          questionId: 'LEGAL_OC',
          requirementLabel: 'Occupancy Certificate',
          validationStatus: EvidenceValidationStatus.satisfied,
          level: EvidenceRiskLevel.none,
          message: 'Evidence requirement is satisfied.',
        ),
        EvidenceRiskSignal(
          questionId: 'LEGAL_SD',
          requirementLabel: 'Registered Sale Deed',
          validationStatus: EvidenceValidationStatus.satisfied,
          level: EvidenceRiskLevel.none,
          message: 'Evidence requirement is satisfied.',
        ),
      ];

      final summary = AssessmentEvidenceSummary(
        overallCoverage: completeCoverage,
        validationResults: completeValidationResults,
        riskSignals: completeRiskSignals,
        categoryCoverage: const [],
      );

      expect(summary.isComplete, isTrue);
      expect(summary.hasEvidenceGaps, isFalse);
      expect(summary.hasEvidenceRisk, isFalse);
      expect(summary.activeRiskSignalCount, 0);
      expect(summary.coveragePercentage, 100);
    });
  });
}