import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/assessment_evidence_summary.dart';
import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/core/evidence/evidence_category_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_coverage.dart';
import 'package:homesure_ai/core/evidence/evidence_requirement.dart';
import 'package:homesure_ai/core/evidence/evidence_risk_signal.dart';
import 'package:homesure_ai/core/evidence/evidence_validation_result.dart';
import 'package:homesure_ai/screens/assessment/evidence_details_screen.dart';

void main() {
  const satisfiedRequirement = EvidenceRequirement(
    questionId: 'LEGAL_OC',
    label: 'Occupancy Certificate',
    type: EvidenceType.document,
  );

  const missingRequirement = EvidenceRequirement(
    questionId: 'FIRE_NOC',
    label: 'Fire NOC',
    type: EvidenceType.document,
  );

  const satisfiedResult = EvidenceValidationResult(
    requirement: satisfiedRequirement,
    status: EvidenceValidationStatus.satisfied,
    message: 'Evidence requirement is satisfied.',
  );

  const missingResult = EvidenceValidationResult(
    requirement: missingRequirement,
    status: EvidenceValidationStatus.missing,
    message: 'Required evidence has not been provided.',
  );

  AssessmentEvidenceSummary buildSummary() {
    final results = [
      satisfiedResult,
      missingResult,
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
      validationResults: results,
      riskSignals: [
        EvidenceRiskSignal.fromValidationResult(
          satisfiedResult,
        ),
        EvidenceRiskSignal.fromValidationResult(
          missingResult,
        ),
      ],
      categoryCoverage: [
        EvidenceCategoryCoverage.calculate(
          categoryId: 'LEGAL_OWNERSHIP',
          results: results,
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return MaterialApp(
      home: EvidenceDetailsScreen(
        summary: buildSummary(),
      ),
    );
  }

  group('EvidenceDetailsScreen', () {
    testWidgets(
      'displays evidence coverage summary',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('Evidence Details'),
          findsOneWidget,
        );
        expect(
          find.text('Evidence Coverage'),
          findsOneWidget,
        );
        expect(
          find.text('50%'),
          findsOneWidget,
        );
        expect(
          find.text(
            '1 of 2 requirements satisfied',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays all evidence requirements by default',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('Occupancy Certificate'),
          findsOneWidget,
        );
        expect(
          find.text('Fire NOC'),
          findsOneWidget,
        );
        expect(
          find.text('Satisfied'),
          findsOneWidget,
        );
        expect(
          find.text('Missing'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'filters to missing requirements',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        final missingFilter =
            find.text('Missing (1)');

        await tester.ensureVisible(
          missingFilter,
        );

        await tester.tap(
          missingFilter,
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Fire NOC'),
          findsOneWidget,
        );
        expect(
          find.text('Occupancy Certificate'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'filters to satisfied requirements',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        final satisfiedFilter =
            find.text('Satisfied (1)');

        await tester.ensureVisible(
          satisfiedFilter,
        );

        await tester.tap(
          satisfiedFilter,
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Occupancy Certificate'),
          findsOneWidget,
        );
        expect(
          find.text('Fire NOC'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'opens requirement details when a requirement is selected',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        final fireNoc = find.text('Fire NOC');

        await tester.ensureVisible(
          fireNoc,
        );

        await tester.tap(
          fireNoc,
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Requirement Details'),
          findsOneWidget,
        );
        expect(
          find.text('Fire NOC'),
          findsOneWidget,
        );
        expect(
          find.text('Question'),
          findsOneWidget,
        );
        expect(
          find.text('FIRE_NOC'),
          findsOneWidget,
        );
        expect(
          find.text('Evidence Type'),
          findsOneWidget,
        );
        expect(
          find.text('Document'),
          findsOneWidget,
        );
        expect(
          find.text('Status'),
          findsOneWidget,
        );
        expect(
          find.text('Evidence Risk'),
          findsOneWidget,
        );
        expect(
          find.text('High risk'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays empty state when filter has no matching requirements',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        final rejectedFilter =
            find.text('Rejected (0)');

        await tester.ensureVisible(
          rejectedFilter,
        );

        await tester.tap(
          rejectedFilter,
        );

        await tester.pumpAndSettle();

        expect(
          find.text('No requirements found'),
          findsOneWidget,
        );
        expect(
          find.text(
            'There are no evidence requirements for this filter.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}