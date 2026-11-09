
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/features/property_submission/services/property_submission_service.dart';
import 'package:homesure_ai/screens/onboarding/my_property_requests_screen.dart';
import 'package:homesure_ai/screens/assessment/surebot_screen.dart';

class FakeStatusGateway implements PropertySubmissionStatusGateway {
  FakeStatusGateway(this.stream);

  final Stream<List<PropertySubmissionRecord>> stream;

  @override
  Stream<List<PropertySubmissionRecord>> watchMySubmissions() => stream;
}


class FakeApprovalGateway implements PropertySubmissionApprovalGateway {
  FakeApprovalGateway(this.approved);

  final bool approved;
  int checkCount = 0;

  @override
  Future<bool> isSubmissionApproved(String submissionId) async {
    checkCount++;
    return approved;
  }
}

class ThrowingApprovalGateway implements PropertySubmissionApprovalGateway {
  @override
  Future<bool> isSubmissionApproved(String submissionId) async {
    throw StateError('Simulated approval check failure');
  }
}

PropertySubmissionRecord makeRecord({
  String name = 'Green Valley Homes',
  String status = 'pending_review',
}) {
  return PropertySubmissionRecord(
    id: 'test-1',
    name: name,
    builder: 'Example Builders',
    locality: 'Kengeri',
    city: 'Bengaluru',
    status: status,
    createdAt: DateTime(2026, 10, 25),
  );
}

void main() {
  group('MyPropertyRequestsScreen', () {
    testWidgets('shows pending review status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPropertyRequestsScreen(
            statusGateway: FakeStatusGateway(
              Stream.value([makeRecord()]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Green Valley Homes'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(
        find.textContaining('Assessment is not available yet.'),
        findsOneWidget,
      );
      expect(find.text('Start Assessment'), findsNothing);
    });

    testWidgets('shows approved status and legal disclaimer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPropertyRequestsScreen(
            statusGateway: FakeStatusGateway(
              Stream.value([
                makeRecord(status: 'approved'),
              ]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Approved for use in HomeSureAI'),
        findsOneWidget,
      );
      expect(
        find.textContaining('not a legal or regulatory certification'),
        findsOneWidget,
      );
      expect(find.text('Start Assessment'), findsOneWidget);
    });

    testWidgets('shows rejected status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPropertyRequestsScreen(
            statusGateway: FakeStatusGateway(
              Stream.value([
                makeRecord(status: 'rejected'),
              ]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Not approved'), findsOneWidget);
      expect(
        find.textContaining('Please contact HomeSureAI'),
        findsOneWidget,
      );
      expect(find.text('Start Assessment'), findsNothing);
    });

    testWidgets(
      'shows additional verification status without allowing assessment',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MyPropertyRequestsScreen(
              statusGateway: FakeStatusGateway(
                Stream.value([
                  makeRecord(status: 'additional_verification'),
                ]),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Additional verification required'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'We need more information to verify this property.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Assessment is not available yet.'),
          findsOneWidget,
        );
        expect(find.text('Start Assessment'), findsNothing);
      },
    );


    testWidgets(
      'rechecks approval and blocks navigation if approval was revoked',
      (tester) async {
        final approvalGateway = FakeApprovalGateway(false);

        await tester.pumpWidget(
          MaterialApp(
            home: MyPropertyRequestsScreen(
              statusGateway: FakeStatusGateway(
                Stream.value([makeRecord(status: 'approved')]),
              ),
              approvalGateway: approvalGateway,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Start Assessment'), findsOneWidget);

        await tester.tap(find.text('Start Assessment'));
        await tester.pumpAndSettle();

        expect(approvalGateway.checkCount, 1);
        expect(
          find.text(
            'This property is no longer approved for assessment.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SureBotScreen), findsNothing);
      },
    );

    testWidgets(
      'shows an error and blocks navigation if approval check fails',
      (tester) async {
        final approvalGateway = ThrowingApprovalGateway();

        await tester.pumpWidget(
          MaterialApp(
            home: MyPropertyRequestsScreen(
              statusGateway: FakeStatusGateway(
                Stream.value([makeRecord(status: 'approved')]),
              ),
              approvalGateway: approvalGateway,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Start Assessment'), findsOneWidget);

        await tester.tap(find.text('Start Assessment'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'We could not verify this property’s approval. Please try again.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SureBotScreen), findsNothing);
      },
    );

    testWidgets('shows empty state when there are no requests',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPropertyRequestsScreen(
            statusGateway: FakeStatusGateway(
              Stream.value([]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No property requests yet'), findsOneWidget);
    });

    testWidgets('shows a friendly error when stream fails',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyPropertyRequestsScreen(
            statusGateway: FakeStatusGateway(
              Stream<List<PropertySubmissionRecord>>.error(
                StateError('Test read failure'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unable to load your property requests.'),
        findsOneWidget,
      );
    });
  });
}
