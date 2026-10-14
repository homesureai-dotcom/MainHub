import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/screens/dashboard/priority_detail_screen.dart';

void main() {
  group('PriorityDetailScreen PHI explanation', () {
    DashboardPriority createPriority({
      int estimatedPHIGain = 25,
    }) {
      return DashboardPriority(
        id: 'OBTAIN_SD',
        title: 'Obtain Registered Sale Deed',
        description:
            'Obtain and verify the registered Sale Deed for the property.',
        priority: RecommendationPriority.critical,
        estimatedPHIGain: estimatedPHIGain,
        requiredDocuments: const [
          'Registered Sale Deed',
        ],
      );
    }

    Future<void> pumpScreen(
      WidgetTester tester, {
      required DashboardPriority priority,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PriorityDetailScreen(
            priority: priority,
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows PHI impact and estimated gain',
      (tester) async {
        await pumpScreen(
          tester,
          priority: createPriority(),
        );

        expect(
          find.text('Potential PHI impact'),
          findsOneWidget,
        );

        expect(
          find.text('+25'),
          findsOneWidget,
        );

        expect(
          find.text('PHI'),
          findsOneWidget,
        );

        expect(
          find.text('Potential improvement'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'explains that the PHI gain comes from completing the recommended action',
      (tester) async {
        await pumpScreen(
          tester,
          priority: createPriority(),
        );

        expect(
          find.text(
            'Completing this action may improve your '
            'Property Health Index by up to 25 points '
            'based on the current assessment recommendation.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses the actual estimated PHI gain',
      (tester) async {
        await pumpScreen(
          tester,
          priority: createPriority(
            estimatedPHIGain: 12,
          ),
        );

        expect(
          find.text('+12'),
          findsOneWidget,
        );

        expect(
          find.text('PHI'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Completing this action may improve your '
            'Property Health Index by up to 12 points '
            'based on the current assessment recommendation.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not show a PHI gain explanation when estimated gain is zero',
      (tester) async {
        await pumpScreen(
          tester,
          priority: createPriority(
            estimatedPHIGain: 0,
          ),
        );

        expect(
          find.text('Potential PHI impact'),
          findsNothing,
        );

        expect(
          find.text('Potential improvement'),
          findsNothing,
        );
      },
    );
  });
}