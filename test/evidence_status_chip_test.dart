import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/widgets/assessment/evidence_status_chip.dart';

void main() {
  group('EvidenceStatusChip', () {
    testWidgets(
      'displays Not Provided status',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceStatusChip(
                status: EvidenceStatus.notProvided,
              ),
            ),
          ),
        );

        expect(
          find.text('Not Provided'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Provided status',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceStatusChip(
                status: EvidenceStatus.provided,
              ),
            ),
          ),
        );

        expect(
          find.text('Provided'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Needs Review status',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceStatusChip(
                status: EvidenceStatus.needsReview,
              ),
            ),
          ),
        );

        expect(
          find.text('Needs Review'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Verified status',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceStatusChip(
                status: EvidenceStatus.verified,
              ),
            ),
          ),
        );

        expect(
          find.text('Verified'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Rejected status',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EvidenceStatusChip(
                status: EvidenceStatus.rejected,
              ),
            ),
          ),
        );

        expect(
          find.text('Rejected'),
          findsOneWidget,
        );
      },
    );
  });
}