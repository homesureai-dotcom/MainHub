import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/evidence/evidence.dart';
import 'package:homesure_ai/widgets/assessment/evidence_action_sheet.dart';

void main() {
  Future<EvidenceType?> openSheet(
    WidgetTester tester,
  ) async {
    EvidenceType? selectedType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selectedType =
                      await EvidenceActionSheet.show(context);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    return selectedType;
  }

  group('EvidenceActionSheet', () {
    testWidgets(
      'displays all evidence options',
      (tester) async {
        await openSheet(tester);

        expect(
          find.text('Add Evidence'),
          findsOneWidget,
        );

        expect(
          find.text('Document'),
          findsOneWidget,
        );

        expect(
          find.text('Photograph'),
          findsOneWidget,
        );

        expect(
          find.text('Video'),
          findsOneWidget,
        );

        expect(
          find.text('Manual Entry'),
          findsOneWidget,
        );

        expect(
          find.text('Cancel'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'returns document evidence type',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedType =
                          await EvidenceActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Document'));
        await tester.pumpAndSettle();

        expect(
          selectedType,
          EvidenceType.document,
        );
      },
    );

    testWidgets(
      'returns photograph evidence type',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedType =
                          await EvidenceActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Photograph'));
        await tester.pumpAndSettle();

        expect(
          selectedType,
          EvidenceType.photograph,
        );
      },
    );

    testWidgets(
      'returns video evidence type',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedType =
                          await EvidenceActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Video'));
        await tester.pumpAndSettle();

        expect(
          selectedType,
          EvidenceType.video,
        );
      },
    );

    testWidgets(
      'returns manual evidence type',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedType =
                          await EvidenceActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Manual Entry'));
        await tester.pumpAndSettle();

        expect(
          selectedType,
          EvidenceType.manual,
        );
      },
    );

    testWidgets(
      'returns null when cancelled',
      (tester) async {
        EvidenceType? selectedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedType =
                          await EvidenceActionSheet.show(context);
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(
          selectedType,
          isNull,
        );
      },
    );
  });
}