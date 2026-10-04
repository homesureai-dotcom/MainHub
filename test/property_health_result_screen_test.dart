import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/screens/assessment/evidence_details_screen.dart';
import 'package:homesure_ai/screens/assessment/property_health_result_screen.dart';

void main() {
  const requirement = EvidenceRequirement(
    questionId: 'LEGAL_OC',
    label: 'Occupancy Certificate',
    type: EvidenceType.document,
  );

  const completeValidationResult = EvidenceValidationResult(
    requirement: requirement,
    status: EvidenceValidationStatus.satisfied,
    message: 'Evidence requirement is satisfied.',
  );

  const missingValidationResult = EvidenceValidationResult(
    requirement: requirement,
    status: EvidenceValidationStatus.missing,
    message: 'Required evidence has not been provided.',
  );

  AssessmentEvidenceSummary completeSummary() {
    final validationResults = [
      completeValidationResult,
    ];

    final riskSignals = [
      EvidenceRiskSignal.fromValidationResult(
        completeValidationResult,
      ),
    ];

    return AssessmentEvidenceSummary(
      overallCoverage: const EvidenceCoverage(
        totalRequirements: 1,
        satisfiedRequirements: 1,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 0,
        rejectedRequirements: 0,
        coveragePercentage: 100,
      ),
      validationResults: validationResults,
      riskSignals: riskSignals,
      categoryCoverage: [
        EvidenceCategoryCoverage.calculate(
          categoryId: 'LEGAL_OWNERSHIP',
          results: validationResults,
        ),
      ],
    );
  }

  AssessmentEvidenceSummary incompleteSummary() {
    final validationResults = [
      missingValidationResult,
    ];

    final riskSignals = [
      EvidenceRiskSignal.fromValidationResult(
        missingValidationResult,
      ),
    ];

    return AssessmentEvidenceSummary(
      overallCoverage: const EvidenceCoverage(
        totalRequirements: 2,
        satisfiedRequirements: 1,
        providedRequirements: 0,
        needsReviewRequirements: 0,
        missingRequirements: 1,
        rejectedRequirements: 0,
        coveragePercentage: 50,
      ),
      validationResults: validationResults,
      riskSignals: riskSignals,
      categoryCoverage: [
        EvidenceCategoryCoverage.calculate(
          categoryId: 'LEGAL_OWNERSHIP',
          results: validationResults,
        ),
      ],
    );
  }

  Widget buildTestWidget({
    required AssessmentEvidenceSummary summary,
  }) {
    final result = PropertyHealthResult(
      overallScore: 82,
      categoryScores: const {},
      risks: const [],
      recommendations: const [],
      evaluatedQuestionCount: 1,
      totalQuestionCount: 1,
      evaluatedCategoryCount: 1,
      totalCategoryCount: 1,
      evaluatedAt: DateTime(2026, 9, 26),
    );

    return MaterialApp(
      home: PropertyHealthResultScreen(
        result: result,
        evidenceSummary: summary,
      ),
    );
  }

  group('PropertyHealthResultScreen evidence coverage', () {
    testWidgets(
      'displays complete evidence coverage',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            summary: completeSummary(),
          ),
        );

        expect(find.text('Evidence Coverage'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(
          find.text(
            '1 of 1 evidence requirements satisfied',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'All evidence requirements are satisfied.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('View Evidence Details'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays incomplete evidence coverage and missing requirements',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            summary: incompleteSummary(),
          ),
        );

        expect(find.text('Evidence Coverage'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(
          find.text(
            '1 of 2 evidence requirements satisfied',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '1 evidence requirements missing',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'evidence risk',
          ),
          findsOneWidget,
        );
        expect(
          find.text('View Evidence Details'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'navigates to evidence details when selected',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            summary: incompleteSummary(),
          ),
        );

        expect(
          find.byType(EvidenceDetailsScreen),
          findsNothing,
        );

        final viewEvidenceDetailsFinder =
            find.text('View Evidence Details');

        await tester.ensureVisible(
          viewEvidenceDetailsFinder,
        );

        await tester.tap(
          viewEvidenceDetailsFinder,
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(EvidenceDetailsScreen),
          findsOneWidget,
        );
        expect(
          find.text('Evidence Details'),
          findsOneWidget,
        );
        expect(
          find.text('Occupancy Certificate'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not display evidence coverage when summary is absent',
      (tester) async {
        final result = PropertyHealthResult(
          overallScore: 82,
          categoryScores: const {},
          risks: const [],
          recommendations: const [],
          evaluatedQuestionCount: 1,
          totalQuestionCount: 1,
          evaluatedCategoryCount: 1,
          totalCategoryCount: 1,
          evaluatedAt: DateTime(2026, 9, 26),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PropertyHealthResultScreen(
              result: result,
            ),
          ),
        );

        expect(find.text('Evidence Coverage'), findsNothing);
        expect(
          find.text('View Evidence Details'),
          findsNothing,
        );
      },
    );
  });
}