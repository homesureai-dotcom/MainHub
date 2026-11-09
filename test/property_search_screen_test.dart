
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property_submission/services/property_submission_service.dart';
import 'package:homesure_ai/screens/onboarding/property_search_screen.dart';

class FakePropertySubmissionGateway implements PropertySubmissionGateway {
  final List<Map<String, String>> submissions = [];
  bool shouldFail = false;

  @override
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
  }) async {
    if (shouldFail) {
      throw StateError('Test submission failure');
    }

    submissions.add({
      'name': name,
      'builder': builder,
      'locality': locality,
      'city': city,
      'reraNumber': reraNumber,
    });

    return 'test-submission-${submissions.length}';
  }
}

void main() {
  group('PropertySearchScreen', () {
    late FakePropertySubmissionGateway gateway;

    Future<void> pumpSearchScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PropertySearchScreen(submissionGateway: gateway)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the first visible catalogue project', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      expect(find.text('Casagrand Aquene'), findsOneWidget);
    });

    testWidgets('shows catalogue projects as not yet assessed', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      expect(
        find.text('Not yet assessed by HomeSureAI'),
        findsWidgets,
      );
    });

    testWidgets('does not display legacy verification badges or scores', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      expect(find.text('Verified Property'), findsNothing);
      expect(find.text('Property DNA'), findsNothing);
      expect(find.text('HomeSure Score'), findsNothing);
    });

    testWidgets('searches catalogue projects by name', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      await tester.enterText(find.byType(TextField).first, 'Prestige Lakeside');
      await tester.pumpAndSettle();

      expect(find.text('Prestige Lakeside Habitat'), findsOneWidget);
      expect(find.text('Casagrand Aquene'), findsNothing);
    });

    testWidgets('shows an empty state when no project matches', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      await tester.enterText(
        find.byType(TextField).first,
        'Project That Does Not Exist',
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching project found.'), findsOneWidget);
      expect(find.text("My project isn't listed"), findsOneWidget);
    });

    testWidgets('submits an unlisted project without selecting it', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      await tester.tap(find.text("My project isn't listed"));
      await tester.pumpAndSettle();

      expect(find.text('Enter your property'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Green Valley Homes');
      await tester.enterText(fields.at(1), 'Example Builders');
      await tester.enterText(fields.at(2), 'Kengeri');
      await tester.enterText(fields.at(3), 'Bengaluru');
      await tester.enterText(fields.at(4), 'TEST-RERA-123');

      await tester.tap(find.text('Use property'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Property submitted for review. You can start an assessment '
          'after HomeSureAI approves it.',
        ),
        findsOneWidget,
      );

      expect(gateway.submissions, hasLength(1));
      expect(gateway.submissions.single['name'], 'Green Valley Homes');
      expect(gateway.submissions.single['builder'], 'Example Builders');
      expect(gateway.submissions.single['locality'], 'Kengeri');
      expect(gateway.submissions.single['city'], 'Bengaluru');
      expect(gateway.submissions.single['reraNumber'], 'TEST-RERA-123');

      // The unlisted project must not become the selected property.
      expect(find.text('Enter your property'), findsNothing);
      expect(find.text('Green Valley Homes'), findsNothing);
    });

    testWidgets('shows an error when submission fails', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway()..shouldFail = true;
      await pumpSearchScreen(tester);

      await tester.tap(find.text("My project isn't listed"));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Green Valley Homes');
      await tester.enterText(fields.at(2), 'Kengeri');
      await tester.enterText(fields.at(3), 'Bengaluru');

      await tester.tap(find.text('Use property'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not submit property:'), findsOneWidget);
    });

    testWidgets('validates required fields in the manual property form', (
      WidgetTester tester,
    ) async {
      gateway = FakePropertySubmissionGateway();
      await pumpSearchScreen(tester);

      await tester.tap(find.text("My project isn't listed"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use property'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the project name'), findsOneWidget);
      expect(find.text('Enter the locality'), findsOneWidget);
    });
  });
}
