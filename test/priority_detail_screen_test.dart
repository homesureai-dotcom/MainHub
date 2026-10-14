import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
import 'package:homesure_ai/screens/dashboard/priority_detail_screen.dart';

void main() {
  group('PriorityDetailScreen', () {
    testWidgets(
      'shows priority details',
      (tester) async {
        const priority = DashboardPriority(
          id: 'priority-001',
          title: 'Complete e-Khata',
          description: 'Complete the pending e-Khata process.',
          priority: RecommendationPriority.high,
          estimatedPHIGain: 8,
          requiredDocuments: [
            'Sale Deed',
            'Khata Certificate',
          ],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: PriorityDetailScreen(
              priority: priority,
            ),
          ),
        );

        expect(
          find.text('Priority Details'),
          findsOneWidget,
        );

        expect(
          find.text('Complete e-Khata'),
          findsOneWidget,
        );

        expect(
          find.text('HIGH'),
          findsOneWidget,
        );

        expect(
          find.text('Complete the pending e-Khata process.'),
          findsOneWidget,
        );

        expect(
          find.text('Potential PHI impact'),
          findsOneWidget,
        );

        expect(
          find.text('+8'),
          findsOneWidget,
        );

        expect(
          find.text('PHI'),
          findsOneWidget,
        );

        expect(
          find.text('Required documents'),
          findsOneWidget,
        );

        expect(
          find.text('Sale Deed'),
          findsOneWidget,
        );

        expect(
          find.text('Khata Certificate'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows category when category is available',
      (tester) async {
        const priority = DashboardPriority(
          id: 'priority-002',
          title: 'Resolve ownership issue',
          description: 'Resolve the outstanding ownership issue.',
          priority: RecommendationPriority.critical,
          estimatedPHIGain: 12,
          requiredDocuments: [
            'Sale Deed',
          ],
          category: PHSCategory.legalOwnership,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: PriorityDetailScreen(
              priority: priority,
            ),
          ),
        );

        expect(
          find.text('Property Health category'),
          findsOneWidget,
        );

        expect(
          find.text(PHSCategory.legalOwnership.displayName),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not show category section when category is unavailable',
      (tester) async {
        const priority = DashboardPriority(
          id: 'priority-003',
          title: 'Review documentation',
          description: 'Review the available documentation.',
          priority: RecommendationPriority.medium,
          estimatedPHIGain: 4,
          requiredDocuments: [],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: PriorityDetailScreen(
              priority: priority,
            ),
          ),
        );

        expect(
          find.text('Property Health category'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does not show required documents section when none are required',
      (tester) async {
        const priority = DashboardPriority(
          id: 'priority-004',
          title: 'Review property status',
          description: 'Review your current property status.',
          priority: RecommendationPriority.low,
          estimatedPHIGain: 2,
          requiredDocuments: [],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: PriorityDetailScreen(
              priority: priority,
            ),
          ),
        );

        expect(
          find.text('Required documents'),
          findsNothing,
        );
      },
    );
  });
}