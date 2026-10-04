import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/widgets/assessment/evidence_item_card.dart';

void main() {
  final addedAt = DateTime(2026, 9, 19);

  Evidence buildEvidence({
    EvidenceType type = EvidenceType.document,
    EvidenceStatus status = EvidenceStatus.provided,
  }) {
    return Evidence(
      id: 'EVIDENCE_001',
      questionId: 'LEGAL_OC',
      type: type,
      name: 'Occupancy Certificate',
      status: status,
      source: EvidenceSource.userUpload,
      addedAt: addedAt,
    );
  }

  group('EvidenceItemCard', () {
    testWidgets(
      'displays evidence name and document type',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(),
              ),
            ),
          ),
        );

        expect(
          find.text('Occupancy Certificate'),
          findsOneWidget,
        );

        expect(
          find.text('Document'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays photograph type',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  type: EvidenceType.photograph,
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Photograph'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays video type',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  type: EvidenceType.video,
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Video'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays manual type',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  type: EvidenceType.manual,
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Manual'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays evidence status',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  status: EvidenceStatus.verified,
                ),
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
      'displays rejected evidence status',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  status: EvidenceStatus.rejected,
                ),
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

    testWidgets(
      'shows Update Status action when status callback is provided',
      (tester) async {
        EvidenceStatus? updatedStatus;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(
                  status: EvidenceStatus.provided,
                ),
                onStatusChange: (status) {
                  updatedStatus = status;
                },
              ),
            ),
          ),
        );

        expect(
          find.text('Update Status'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Update Status'),
        );
        await tester.pump();

        expect(
          updatedStatus,
          EvidenceStatus.needsReview,
        );
      },
    );

    testWidgets(
      'shows Delete action when delete callback is provided',
      (tester) async {
        var deleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(),
                onDelete: () {
                  deleteCalled = true;
                },
              ),
            ),
          ),
        );

        expect(
          find.text('Delete'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Delete'),
        );
        await tester.pump();

        expect(
          deleteCalled,
          isTrue,
        );
      },
    );

    testWidgets(
      'does not show lifecycle actions when callbacks are omitted',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EvidenceItemCard(
                evidence: buildEvidence(),
              ),
            ),
          ),
        );

        expect(
          find.text('Update Status'),
          findsNothing,
        );

        expect(
          find.text('Delete'),
          findsNothing,
        );
      },
    );
  });
}