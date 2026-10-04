import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/widgets/assessment/add_evidence_button.dart';

void main() {
  group('AddEvidenceButton', () {
    testWidgets(
      'displays Add Evidence label',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddEvidenceButton(),
            ),
          ),
        );

        expect(
          find.text('Add Evidence'),
          findsOneWidget,
        );

        expect(
          find.byIcon(Icons.add_a_photo_outlined),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'invokes callback when pressed',
      (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AddEvidenceButton(
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(
          find.text('Add Evidence'),
        );

        expect(
          pressed,
          isTrue,
        );
      },
    );

    testWidgets(
      'supports disabled state when callback is not provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddEvidenceButton(),
            ),
          ),
        );

        final button = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );

        expect(
          button.onPressed,
          isNull,
        );
      },
    );
  });
}