import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/engine/models/property_health_result.dart';
import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/features/dashboard/coordinators/dashboard_priority_mapper.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';

void main() {
  const mapper = DashboardPriorityMapper();

  group('DashboardPriorityMapper', () {
    test(
      'returns empty list when health result is null',
      () {
        final priorities = mapper.map(null);

        expect(priorities, isEmpty);
      },
    );

    test(
      'returns empty list when health result has no recommendations',
      () {
        final result = createHealthResult(
          recommendations: const [],
        );

        final priorities = mapper.map(result);

        expect(priorities, isEmpty);
      },
    );

    test(
      'maps recommendation fields into dashboard priority',
      () {
        final recommendation = createRecommendation(
          id: 'recommendation-001',
          title: 'Complete e-Khata',
          description: 'Complete the pending e-Khata process.',
          priority: RecommendationPriority.high,
          estimatedPHIGain: 8,
          requiredDocuments: const [
            'Sale Deed',
            'Khata Certificate',
          ],
        );

        final result = createHealthResult(
          recommendations: [
            recommendation,
          ],
        );

        final priorities = mapper.map(result);

        expect(priorities, hasLength(1));

        final priority = priorities.first;

        expect(priority.id, 'recommendation-001');
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
          const [
            'Sale Deed',
            'Khata Certificate',
          ],
        );
      },
    );

    test(
      'sorts priorities by severity from critical to low',
      () {
        final recommendations = [
          createRecommendation(
            id: 'low',
            title: 'Low Priority',
            priority: RecommendationPriority.low,
            estimatedPHIGain: 20,
          ),
          createRecommendation(
            id: 'critical',
            title: 'Critical Priority',
            priority: RecommendationPriority.critical,
            estimatedPHIGain: 2,
          ),
          createRecommendation(
            id: 'medium',
            title: 'Medium Priority',
            priority: RecommendationPriority.medium,
            estimatedPHIGain: 15,
          ),
          createRecommendation(
            id: 'high',
            title: 'High Priority',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 10,
          ),
        ];

        final result = createHealthResult(
          recommendations: recommendations,
        );

        final priorities = mapper.map(result);

        expect(
          priorities.map((priority) => priority.id).toList(),
          [
            'critical',
            'high',
            'medium',
            'low',
          ],
        );
      },
    );

    test(
      'sorts same-priority recommendations by higher PHI gain first',
      () {
        final recommendations = [
          createRecommendation(
            id: 'high-5',
            title: 'Five PHI',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 5,
          ),
          createRecommendation(
            id: 'high-12',
            title: 'Twelve PHI',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 12,
          ),
          createRecommendation(
            id: 'high-8',
            title: 'Eight PHI',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 8,
          ),
        ];

        final result = createHealthResult(
          recommendations: recommendations,
        );

        final priorities = mapper.map(result);

        expect(
          priorities.map((priority) => priority.id).toList(),
          [
            'high-12',
            'high-8',
            'high-5',
          ],
        );
      },
    );

    test(
      'uses title as deterministic tie breaker when priority and PHI gain match',
      () {
        final recommendations = [
          createRecommendation(
            id: 'b',
            title: 'Complete Water Documentation',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 8,
          ),
          createRecommendation(
            id: 'c',
            title: 'Fix STP Documentation',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 8,
          ),
          createRecommendation(
            id: 'a',
            title: 'Resolve E-Khata',
            priority: RecommendationPriority.high,
            estimatedPHIGain: 8,
          ),
        ];

        final result = createHealthResult(
          recommendations: recommendations,
        );

        final priorities = mapper.map(result);

        expect(
          priorities.map((priority) => priority.title).toList(),
          [
            'Complete Water Documentation',
            'Fix STP Documentation',
            'Resolve E-Khata',
          ],
        );
      },
    );

    test(
      'does not mutate the original recommendation list',
      () {
        final recommendations = [
          createRecommendation(
            id: 'low',
            title: 'Low Priority',
            priority: RecommendationPriority.low,
            estimatedPHIGain: 5,
          ),
          createRecommendation(
            id: 'critical',
            title: 'Critical Priority',
            priority: RecommendationPriority.critical,
            estimatedPHIGain: 10,
          ),
        ];

        final originalOrder =
            recommendations.map((recommendation) => recommendation.id).toList();

        final result = createHealthResult(
          recommendations: recommendations,
        );

        mapper.map(result);

        expect(
          recommendations.map((recommendation) => recommendation.id).toList(),
          originalOrder,
        );
      },
    );

    test(
      'returns an unmodifiable priority list',
      () {
        final result = createHealthResult(
          recommendations: [
            createRecommendation(
              id: 'priority-001',
              title: 'Complete e-Khata',
              priority: RecommendationPriority.high,
              estimatedPHIGain: 8,
            ),
          ],
        );

        final priorities = mapper.map(result);

        expect(
          () => priorities.add(
            const DashboardPriority(
              id: 'priority-002',
              title: 'Another Priority',
              description: 'Another priority.',
              priority: RecommendationPriority.low,
              estimatedPHIGain: 1,
              requiredDocuments: [],
            ),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });
}

PropertyHealthResult createHealthResult({
  List<Recommendation> recommendations = const [],
}) {
  return PropertyHealthResult(
    overallScore: 72,
    categoryScores: const {
      PHSCategory.legalOwnership: 72,
    },
    risks: const [],
    recommendations: recommendations,
    evaluatedQuestionCount: 10,
    totalQuestionCount: 33,
    evaluatedCategoryCount: 1,
    totalCategoryCount: 6,
    evaluatedAt: DateTime(2026, 10, 14),
  );
}

Recommendation createRecommendation({
  required String id,
  required String title,
  String description = 'Test recommendation description.',
  RecommendationPriority priority = RecommendationPriority.medium,
  int estimatedPHIGain = 5,
  List<String> requiredDocuments = const [],
}) {
  return Recommendation(
    id: id,
    title: title,
    description: description,
    priority: priority,
    estimatedPHIGain: estimatedPHIGain,
    requiredDocuments: requiredDocuments,
  );
}