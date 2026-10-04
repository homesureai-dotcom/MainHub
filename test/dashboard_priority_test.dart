import 'package:flutter_test/flutter_test.dart';

import 'package:homesure_ai/core/phs/phs_categories.dart';
import 'package:homesure_ai/features/dashboard/models/dashboard_priority.dart';
import 'package:homesure_ai/models/property_health/recommendation.dart';

void main() {
  group('DashboardPriority', () {
    test('stores recommendation data correctly', () {
      const priority = DashboardPriority(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 8,
        requiredDocuments: [
          'Sale Deed',
          'Khata Certificate',
        ],
        category: PHSCategory.legalOwnership,
      );

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
      expect(
        priority.category,
        PHSCategory.legalOwnership,
      );
    });

    test('identifies critical priority', () {
      const priority = DashboardPriority(
        id: 'critical-001',
        title: 'Critical Action',
        description: 'Immediate action required.',
        priority: RecommendationPriority.critical,
        estimatedPHIGain: 15,
        requiredDocuments: [],
      );

      expect(priority.isCritical, isTrue);
      expect(priority.isHigh, isFalse);
      expect(priority.isMedium, isFalse);
      expect(priority.isLow, isFalse);
      expect(priority.priorityRank, 0);
    });

    test('identifies high priority', () {
      const priority = DashboardPriority(
        id: 'high-001',
        title: 'High Priority Action',
        description: 'Action required soon.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 10,
        requiredDocuments: [],
      );

      expect(priority.isCritical, isFalse);
      expect(priority.isHigh, isTrue);
      expect(priority.isMedium, isFalse);
      expect(priority.isLow, isFalse);
      expect(priority.priorityRank, 1);
    });

    test('identifies medium priority', () {
      const priority = DashboardPriority(
        id: 'medium-001',
        title: 'Medium Priority Action',
        description: 'Action recommended.',
        priority: RecommendationPriority.medium,
        estimatedPHIGain: 5,
        requiredDocuments: [],
      );

      expect(priority.isCritical, isFalse);
      expect(priority.isHigh, isFalse);
      expect(priority.isMedium, isTrue);
      expect(priority.isLow, isFalse);
      expect(priority.priorityRank, 2);
    });

    test('identifies low priority', () {
      const priority = DashboardPriority(
        id: 'low-001',
        title: 'Low Priority Action',
        description: 'Action can be planned.',
        priority: RecommendationPriority.low,
        estimatedPHIGain: 2,
        requiredDocuments: [],
      );

      expect(priority.isCritical, isFalse);
      expect(priority.isHigh, isFalse);
      expect(priority.isMedium, isFalse);
      expect(priority.isLow, isTrue);
      expect(priority.priorityRank, 3);
    });

    test('supports equality for identical values', () {
      const first = DashboardPriority(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 8,
        requiredDocuments: ['Sale Deed'],
        category: PHSCategory.legalOwnership,
      );

      const second = DashboardPriority(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 8,
        requiredDocuments: ['Sale Deed'],
        category: PHSCategory.legalOwnership,
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('distinguishes different priorities', () {
      const first = DashboardPriority(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.high,
        estimatedPHIGain: 8,
        requiredDocuments: [],
      );

      const second = DashboardPriority(
        id: 'rec-001',
        title: 'Complete e-Khata',
        description: 'Complete the pending e-Khata process.',
        priority: RecommendationPriority.medium,
        estimatedPHIGain: 8,
        requiredDocuments: [],
      );

      expect(first, isNot(equals(second)));
    });

    test('allows recommendation without a category', () {
      const priority = DashboardPriority(
        id: 'rec-002',
        title: 'Review Documents',
        description: 'Review available property documents.',
        priority: RecommendationPriority.medium,
        estimatedPHIGain: 3,
        requiredDocuments: [],
      );

      expect(priority.category, isNull);
      expect(priority.isMedium, isTrue);
    });
  });
}