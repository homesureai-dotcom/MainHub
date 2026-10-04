import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/widgets/dashboard/quick_action_grid.dart';

Widget buildTestWidget({
  VoidCallback? onAiAdvisor,
  VoidCallback? onDocuments,
  VoidCallback? onCompliance,
  VoidCallback? onTimeline,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: QuickActionGrid(
          onAiAdvisor: onAiAdvisor,
          onDocuments: onDocuments,
          onCompliance: onCompliance,
          onTimeline: onTimeline,
        ),
      ),
    ),
  );
}

void main() {
  group('QuickActionGrid', () {
    testWidgets(
      'renders all quick action cards',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('AI Advisor'), findsOneWidget);
        expect(find.text('Documents'), findsOneWidget);
        expect(find.text('Compliance'), findsOneWidget);
        expect(find.text('Timeline'), findsOneWidget);
      },
    );

    testWidgets(
      'invokes AI Advisor callback',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onAiAdvisor: () {
              tapped = true;
            },
          ),
        );

        await tester.ensureVisible(
          find.text('AI Advisor'),
        );

        await tester.tap(
          find.text('AI Advisor'),
        );

        await tester.pump();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'invokes Documents callback',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onDocuments: () {
              tapped = true;
            },
          ),
        );

        await tester.ensureVisible(
          find.text('Documents'),
        );

        await tester.tap(
          find.text('Documents'),
        );

        await tester.pump();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'invokes Compliance callback',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onCompliance: () {
              tapped = true;
            },
          ),
        );

        await tester.ensureVisible(
          find.text('Compliance'),
        );

        await tester.tap(
          find.text('Compliance'),
        );

        await tester.pump();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'invokes Timeline callback',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onTimeline: () {
              tapped = true;
            },
          ),
        );

        await tester.ensureVisible(
          find.text('Timeline'),
        );

        await tester.tap(
          find.text('Timeline'),
        );

        await tester.pump();

        expect(tapped, isTrue);
      },
    );
  });
}