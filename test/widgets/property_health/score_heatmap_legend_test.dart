import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/widgets/property_health/score_heatmap_legend.dart';

void main() {
  group('ScoreHeatmapLegend', () {
    test('maps scores to the canonical health labels', () {
      expect(ScoreHeatmapLegend.scoreLabel(100), 'Excellent');
      expect(ScoreHeatmapLegend.scoreLabel(90), 'Excellent');

      expect(ScoreHeatmapLegend.scoreLabel(89), 'Good');
      expect(ScoreHeatmapLegend.scoreLabel(75), 'Good');

      expect(ScoreHeatmapLegend.scoreLabel(74), 'Needs Attention');
      expect(ScoreHeatmapLegend.scoreLabel(60), 'Needs Attention');

      expect(ScoreHeatmapLegend.scoreLabel(59), 'At Risk');
      expect(ScoreHeatmapLegend.scoreLabel(40), 'At Risk');

      expect(ScoreHeatmapLegend.scoreLabel(39), 'Critical');
      expect(ScoreHeatmapLegend.scoreLabel(0), 'Critical');

      expect(ScoreHeatmapLegend.scoreLabel(null), 'Not Assessed');
    });

    test('maps scores to the canonical score ranges', () {
      expect(ScoreHeatmapLegend.scoreRange(100), '90–100');
      expect(ScoreHeatmapLegend.scoreRange(90), '90–100');

      expect(ScoreHeatmapLegend.scoreRange(89), '75–89');
      expect(ScoreHeatmapLegend.scoreRange(75), '75–89');

      expect(ScoreHeatmapLegend.scoreRange(74), '60–74');
      expect(ScoreHeatmapLegend.scoreRange(60), '60–74');

      expect(ScoreHeatmapLegend.scoreRange(59), '40–59');
      expect(ScoreHeatmapLegend.scoreRange(40), '40–59');

      expect(ScoreHeatmapLegend.scoreRange(39), '0–39');
      expect(ScoreHeatmapLegend.scoreRange(0), '0–39');

      expect(ScoreHeatmapLegend.scoreRange(null), '—');
    });

    test('returns a color for every health band', () {
      expect(ScoreHeatmapLegend.scoreColor(95), Colors.green);
      expect(ScoreHeatmapLegend.scoreColor(80), Colors.teal);
      expect(ScoreHeatmapLegend.scoreColor(65), Colors.amber);
      expect(ScoreHeatmapLegend.scoreColor(50), Colors.orange);
      expect(ScoreHeatmapLegend.scoreColor(20), Colors.red);
      expect(ScoreHeatmapLegend.scoreColor(null), Colors.grey);
    });

    testWidgets('renders the full heatmap legend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScoreHeatmapLegend())),
      );

      expect(find.text('Score Health Map'), findsOneWidget);
      expect(
        find.text(
          'Your Property Health Score is interpreted using these health bands.',
        ),
        findsOneWidget,
      );

      expect(find.text('90–100'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);

      expect(find.text('75–89'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);

      expect(find.text('60–74'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);

      expect(find.text('40–59'), findsOneWidget);
      expect(find.text('At Risk'), findsOneWidget);

      expect(find.text('0–39'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);

      expect(find.text('—'), findsOneWidget);
      expect(find.text('Not Assessed'), findsOneWidget);
    });

    testWidgets('renders the current score when supplied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScoreHeatmapLegend(score: 82))),
      );

      expect(find.text('Current score: 82 · Good'), findsOneWidget);

      expect(find.text('75–89'), findsNWidgets(2));
    });

    testWidgets('renders the compact legend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScoreHeatmapLegend(compact: true)),
        ),
      );

      expect(find.text('90–100'), findsOneWidget);
      expect(find.text('75–89'), findsOneWidget);
      expect(find.text('60–74'), findsOneWidget);
      expect(find.text('40–59'), findsOneWidget);
      expect(find.text('0–39'), findsOneWidget);
      expect(find.text('Not assessed'), findsOneWidget);

      expect(find.text('Score Health Map'), findsNothing);
    });
  });
}
