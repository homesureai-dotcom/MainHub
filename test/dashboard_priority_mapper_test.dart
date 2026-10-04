import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/features/dashboard/coordinators/dashboard_priority_mapper.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';
void main() {
  const mapper = DashboardPriorityMapper();

  PropertyHealthResult createResult({
    List<Recommendation> recommendations = const [],
  }) {
    return PropertyHealthResult(
      overallScore: 72.0,
      categoryScores: const {},
      risks: const [],
      recommendations: recommendations,
      evaluatedQuestionCount: 10,
      totalQuestionCount: 33,
      evaluatedCategoryCount: 4,
      totalCategoryCount: 6,
      evaluatedAt: DateTime(2026, 10, 4),
    );
  }

  group('DashboardPriorityMapper', () {
    test('returns empty list when health result is null', () {
      final result = mapper.map(null);

      expect(result, isEmpty);
    });

    test('returns empty list when there are no recommendations', () {
      final result = mapper.map(
        createResult(),
      );

      expect(result, isEmpty);
    });

    test('maps recommendation fields correctly', () {
      const recommendation = Recommendation(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        estimatedPHIGain: 8,
        priority: RecommendationPriority.high,
        requiredDocuments: [
          'Sale Deed',
          'Khata Certificate',
        ],
      );

      final result = mapper.map(
        createResult(
          recommendations: [
            recommendation,
          ],
        ),
      );

      expect(result.length, 1);

      final priority = result.first;

      expect(priority.id, 'rec-001');
      expect(priority.title, 'Complete e-Khata');
      expect(
        priority.description,
        'Complete the pending e-Khata process.',
      );
      expect(
        priority.priority,
        RecommendationPriority.high,
      );
      expect(priority.estimatedPHIGain, 8);
      expect(
        priority.requiredDocuments,
        ['Sale Deed', 'Khata Certificate'],
      );
      expect(priority.category, isNull);
    });

    test('orders critical before high, medium and low', () {
      final result = mapper.map(
        createResult(
          recommendations: [
            const Recommendation(
              id: 'low',
              title: 'Low Action',
              description: 'Low priority action.',
              estimatedPHIGain: 20,
              priority: RecommendationPriority.low,
            ),
            const Recommendation(
              id: 'medium',
              title: 'Medium Action',
              description: 'Medium priority action.',
              estimatedPHIGain: 20,
              priority: RecommendationPriority.medium,
            ),
            const Recommendation(
              id: 'critical',
              title: 'Critical Action',
              description: 'Critical action.',
              estimatedPHIGain: 20,
              priority: RecommendationPriority.critical,
            ),
            const Recommendation(
              id: 'high',
              title: 'High Action',
              description: 'High priority action.',
              estimatedPHIGain: 20,
              priority: RecommendationPriority.high,
            ),
          ],
        ),
      );

      expect(
        result.map((item) => item.id).toList(),
        [
          'critical',
          'high',
          'medium',
          'low',
        ],
      );
    });

    test('orders recommendations with higher PHI gain first within same priority',
        () {
      final result = mapper.map(
        createResult(
          recommendations: [
            const Recommendation(
              id: 'medium-low-gain',
              title: 'Lower Gain',
              description: 'Lower PHI improvement.',
              estimatedPHIGain: 3,
              priority: RecommendationPriority.medium,
            ),
            const Recommendation(
              id: 'medium-high-gain',
              title: 'Higher Gain',
              description: 'Higher PHI improvement.',
              estimatedPHIGain: 12,
              priority: RecommendationPriority.medium,
            ),
            const Recommendation(
              id: 'medium-mid-gain',
              title: 'Middle Gain',
              description: 'Middle PHI improvement.',
              estimatedPHIGain: 7,
              priority: RecommendationPriority.medium,
            ),
          ],
        ),
      );

      expect(
        result.map((item) => item.id).toList(),
        [
          'medium-high-gain',
          'medium-mid-gain',
          'medium-low-gain',
        ],
      );
    });

    test('uses title as deterministic tie-breaker', () {
      final result = mapper.map(
        createResult(
          recommendations: [
            const Recommendation(
              id: 'rec-b',
              title: 'Zebra Action',
              description: 'Action Z.',
              estimatedPHIGain: 5,
              priority: RecommendationPriority.high,
            ),
            const Recommendation(
              id: 'rec-a',
              title: 'Alpha Action',
              description: 'Action A.',
              estimatedPHIGain: 5,
              priority: RecommendationPriority.high,
            ),
          ],
        ),
      );

      expect(
        result.map((item) => item.title).toList(),
        [
          'Alpha Action',
          'Zebra Action',
        ],
      );
    });

    test('preserves all recommendations', () {
      final result = mapper.map(
        createResult(
          recommendations: [
            const Recommendation(
              id: 'rec-1',
              title: 'First',
              description: 'First recommendation.',
              estimatedPHIGain: 4,
              priority: RecommendationPriority.medium,
            ),
            const Recommendation(
              id: 'rec-2',
              title: 'Second',
              description: 'Second recommendation.',
              estimatedPHIGain: 8,
              priority: RecommendationPriority.high,
            ),
            const Recommendation(
              id: 'rec-3',
              title: 'Third',
              description: 'Third recommendation.',
              estimatedPHIGain: 15,
              priority: RecommendationPriority.critical,
            ),
          ],
        ),
      );

      expect(result.length, 3);
      expect(
        result.map((item) => item.id).toSet(),
        {
          'rec-1',
          'rec-2',
          'rec-3',
        },
      );
    });

    test('returns an unmodifiable result list', () {
      final result = mapper.map(
        createResult(
          recommendations: [
            const Recommendation(
              id: 'rec-001',
              title: 'Test',
              description: 'Test recommendation.',
              estimatedPHIGain: 5,
              priority: RecommendationPriority.medium,
            ),
          ],
        ),
      );

      expect(
        () => result.add(
          const DashboardPriority(
            id: 'extra',
            title: 'Extra',
            description: 'Extra priority.',
            priority: RecommendationPriority.low,
            estimatedPHIGain: 1,
            requiredDocuments: [],
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}