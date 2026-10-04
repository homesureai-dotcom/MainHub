import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/weighted_phs_calculator.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';

void main() {
  const calculator = WeightedPHScalculator();

  group('WeightedPHScalculator', () {
    test('returns 100 when every category scores 100', () {
      final scores = {
        for (final category in PHSCategory.values) category: 100.0,
      };

      final result = calculator.calculate(scores);

      expect(result, closeTo(100.0, 0.0001));
    });

    test('calculates the expected weighted score', () {
      final scores = {
        PHSCategory.legalOwnership: 80.0,
        PHSCategory.constructionQuality: 90.0,
        PHSCategory.utilitiesInfrastructure: 70.0,
        PHSCategory.safetyCompliance: 90.0,
        PHSCategory.communityMaintenance: 80.0,
        PHSCategory.documentation: 70.0,
      };

      final result = calculator.calculate(scores);

      expect(result, closeTo(81.5, 0.0001));
    });

    test('clamps scores above 100', () {
      final scores = {
        for (final category in PHSCategory.values) category: 150.0,
      };

      final result = calculator.calculate(scores);

      expect(result, closeTo(100.0, 0.0001));
    });

    test('clamps scores below 0', () {
      final scores = {
        for (final category in PHSCategory.values) category: -25.0,
      };

      final result = calculator.calculate(scores);

      expect(result, closeTo(0.0, 0.0001));
    });

    test('missing categories contribute zero', () {
      final scores = {
        PHSCategory.legalOwnership: 60.0,
      };

      final result = calculator.calculate(scores);

      expect(result, closeTo(15.0, 0.0001));
    });

    test('calculates an individual category contribution', () {
      final result = calculator.contribution(
        category: PHSCategory.legalOwnership,
        score: 60.0,
      );

      expect(result, closeTo(15.0, 0.0001));
    });
  });
}