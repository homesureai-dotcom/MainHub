import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence_capture_service.dart';
import 'package:homesure_ai/core/evidence/evidence_content.dart';
import 'package:homesure_ai/screens/assessment/assessment_screen.dart';
import 'package:homesure_ai/state/assessment_state.dart';
import 'package:homesure_ai/widgets/assessment/add_evidence_button.dart';

class _FakeEvidenceCaptureService implements EvidenceCaptureService {
  final EvidenceContent? result;

  _FakeEvidenceCaptureService({required this.result});

  @override
  Future<EvidenceContent?> capture(EvidenceCaptureRequest request) async {
    return result;
  }
}

void main() {
  Future<void> resetAssessmentState() async {
    AssessmentState.instance.clearAssessment();
  }

  Future<void> openEvidenceSheet(
    WidgetTester tester, {
    EvidenceCaptureService? captureService,
  }) async {
    await resetAssessmentState();

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentScreen(evidenceCaptureService: captureService),
      ),
    );

    await tester.pump();

    final addEvidenceButton = find.byType(AddEvidenceButton);

    await tester.ensureVisible(addEvidenceButton);
    await tester.pumpAndSettle();

    await tester.tap(addEvidenceButton);
    await tester.pumpAndSettle();
  }

  Future<void> selectEvidenceType(WidgetTester tester, String label) async {
    final option = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == label &&
          widget.style?.fontSize == 15 &&
          widget.style?.fontWeight == FontWeight.w700,
    );

    expect(option, findsOneWidget);

    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  Future<void> createDocumentEvidence(
    WidgetTester tester, {
    EvidenceCaptureService? captureService,
  }) async {
    await openEvidenceSheet(tester, captureService: captureService);

    await selectEvidenceType(tester, 'Document');
  }

  Future<void> createPhotographEvidence(
    WidgetTester tester, {
    EvidenceCaptureService? captureService,
  }) async {
    await openEvidenceSheet(tester, captureService: captureService);

    await selectEvidenceType(tester, 'Photograph');
  }

  Future<void> tapVisibleButton(WidgetTester tester, Finder finder) async {
    expect(finder, findsOneWidget);

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    await tester.tap(finder);
  }

  group('AssessmentScreen evidence entry point', () {
    testWidgets('displays Add Evidence button', (tester) async {
      await resetAssessmentState();

      await tester.pumpWidget(const MaterialApp(home: AssessmentScreen()));

      await tester.pump();

      expect(find.byType(AddEvidenceButton), findsOneWidget);

      expect(find.text('Add Evidence'), findsOneWidget);
    });

    testWidgets('opens evidence action sheet', (tester) async {
      await openEvidenceSheet(tester);

      expect(
        find.text('Choose how you want to provide supporting evidence.'),
        findsOneWidget,
      );

      expect(find.text('Document'), findsWidgets);

      expect(find.text('Photograph'), findsOneWidget);

      expect(find.text('Video'), findsOneWidget);

      expect(find.text('Manual Entry'), findsOneWidget);
    });

    testWidgets('captures and persists selected document evidence', (
      tester,
    ) async {
      final captureService = _FakeEvidenceCaptureService(
        result: EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: '/documents/occupancy_certificate.pdf',
          label: 'occupancy_certificate.pdf',
        ),
      );

      await createDocumentEvidence(tester, captureService: captureService);

      expect(
        find.text('Document evidence added successfully.'),
        findsOneWidget,
      );

      expect(find.text('Evidence provided'), findsOneWidget);

      expect(find.text('Document evidence'), findsOneWidget);

      expect(find.text('Not Provided'), findsNothing);
    });

    testWidgets('captures and persists selected photograph evidence', (
      tester,
    ) async {
      final captureService = _FakeEvidenceCaptureService(
        result: EvidenceContent(
          kind: EvidenceContentKind.image,
          locator: '/photos/fire_system.jpg',
          label: 'fire_system.jpg',
        ),
      );

      await createPhotographEvidence(tester, captureService: captureService);

      expect(
        find.text('Photograph evidence added successfully.'),
        findsOneWidget,
      );

      expect(find.text('Evidence provided'), findsOneWidget);

      expect(find.text('Photograph evidence'), findsOneWidget);

      expect(find.text('Not Provided'), findsNothing);
    });

    testWidgets('does not create evidence when document capture is cancelled', (
      tester,
    ) async {
      final captureService = _FakeEvidenceCaptureService(result: null);

      await createDocumentEvidence(tester, captureService: captureService);

      expect(find.text('Evidence provided'), findsNothing);

      expect(find.text('Document evidence'), findsNothing);

      expect(
        find.text(
          'Document evidence entry added. Capture can be completed here.',
        ),
        findsNothing,
      );
    });

    testWidgets(
      'updates captured evidence status and refreshes the question card',
      (tester) async {
        final captureService = _FakeEvidenceCaptureService(
          result: EvidenceContent(
            kind: EvidenceContentKind.file,
            locator: '/documents/occupancy_certificate.pdf',
            label: 'occupancy_certificate.pdf',
          ),
        );

        await createDocumentEvidence(tester, captureService: captureService);

        expect(find.text('Provided'), findsOneWidget);

        final updateStatusButton = find.text('Update Status');

        await tapVisibleButton(tester, updateStatusButton);

        await tester.pumpAndSettle();

        expect(find.text('Needs Review'), findsOneWidget);

        expect(find.text('Provided'), findsNothing);
      },
    );

    testWidgets('deletes captured evidence and refreshes the question card', (
      tester,
    ) async {
      final captureService = _FakeEvidenceCaptureService(
        result: EvidenceContent(
          kind: EvidenceContentKind.file,
          locator: '/documents/occupancy_certificate.pdf',
          label: 'occupancy_certificate.pdf',
        ),
      );

      await createDocumentEvidence(tester, captureService: captureService);

      expect(find.text('Document evidence'), findsOneWidget);

      final deleteButton = find.text('Delete');

      await tapVisibleButton(tester, deleteButton);

      await tester.pumpAndSettle();

      expect(find.text('Evidence provided'), findsNothing);

      expect(find.text('Document evidence'), findsNothing);

      expect(find.text('Delete'), findsNothing);
    });
  });
}
