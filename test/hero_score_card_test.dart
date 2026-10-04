import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/widgets/hero_score_card.dart';

void main() {
  Widget buildTestWidget({
    int? score,
    String status = 'Excellent',
    int verifiedCount = 10,
    int pendingCount = 2,
    int issueCount = 1,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HeroScoreCard(
          score: score,
          status: status,
          verifiedCount: verifiedCount,
          pendingCount: pendingCount,
          issueCount: issueCount,
        ),
      ),
    );
  }

  group('HeroScoreCard', () {
    testWidgets(
      'shows real health score when assessment is available',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: 82,
            status: 'Good',
          ),
        );

        expect(
          find.text('PROPERTY HEALTH SCORE'),
          findsOneWidget,
        );
        expect(find.text('82'), findsOneWidget);
        expect(find.text('GOOD'), findsOneWidget);
        expect(
          find.text('View Property Health Report'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows not assessed state when score is unavailable',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: null,
            status: 'Not Assessed',
          ),
        );

        expect(find.text('Not Assessed'), findsOneWidget);
        expect(
          find.text('Complete your assessment'),
          findsOneWidget,
        );
        expect(
          find.text('Start Property Health Assessment'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not display zero as the health score when score is unavailable',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: null,
            status: 'Not Assessed',
          ),
        );

        expect(find.text('0'), findsNothing);
      },
    );

    testWidgets(
      'shows verified, pending and issue counts',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: 82,
            verifiedCount: 14,
            pendingCount: 5,
            issueCount: 2,
          ),
        );

        expect(find.text('14'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        expect(find.text('Verified'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Issues'), findsOneWidget);
      },
    );

    testWidgets(
      'uses assessment status provided by dashboard data',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: 58,
            status: 'Needs Immediate Attention',
          ),
        );

        expect(find.text('58'), findsOneWidget);
        expect(
          find.text('NEEDS IMMEDIATE ATTENTION'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders report button when assessment is available',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            score: 91,
            status: 'Excellent',
          ),
        );

        expect(
          find.text('View Property Health Report'),
          findsOneWidget,
        );

        expect(
          find.text('Start Property Health Assessment'),
          findsNothing,
        );
      },
    );
  });
}