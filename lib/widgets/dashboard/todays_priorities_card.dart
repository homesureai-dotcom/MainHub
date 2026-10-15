import 'package:flutter/material.dart';

import '../../features/dashboard/models/dashboard_data.dart';
import '../../features/dashboard/models/dashboard_priority.dart';
import '../../models/property_health/recommendation.dart';

class TodaysPrioritiesCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onViewAll;
  final ValueChanged<DashboardPriority>? onPriorityTap;

  const TodaysPrioritiesCard({
    super.key,
    required this.data,
    this.onViewAll,
    this.onPriorityTap,
  });

  static const int _maxVisiblePriorities = 3;

  @override
  Widget build(BuildContext context) {
    final priorities = data.priorities
        .take(_maxVisiblePriorities)
        .toList(growable: false);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.priority_high_rounded,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Today’s Priorities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.hasAssessment
                  ? 'What needs your attention'
                  : 'Complete your assessment to see priorities',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            if (!data.hasAssessment)
              const _EmptyPrioritiesState(
                message:
                    'Your property health assessment has not started yet.',
              )
            else if (data.priorities.isEmpty)
              const _EmptyPrioritiesState(
                message:
                    'No priority actions have been identified yet.',
              )
            else ...[
              for (var index = 0; index < priorities.length; index++) ...[
                _PriorityItem(
                  priority: priorities[index],
                  onTap: onPriorityTap == null
                      ? null
                      : () => onPriorityTap!(priorities[index]),
                ),
                if (index < priorities.length - 1)
                  const SizedBox(height: 14),
              ],
              if (data.priorities.length > _maxVisiblePriorities) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onViewAll,
                    child: const Text('View All Priorities'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  final DashboardPriority priority;
  final VoidCallback? onTap;

  const _PriorityItem({
    required this.priority,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityLabel = _priorityLabel(priority.priority);
    final priorityIcon = _priorityIcon(priority.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                priorityIcon,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      priority.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _PriorityBadge(label: priorityLabel),
                        if (priority.estimatedPHIGain > 0)
                          _PriorityBadge(
                            label: '+${priority.estimatedPHIGain} PHI',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.critical:
        return 'CRITICAL';
      case RecommendationPriority.high:
        return 'HIGH';
      case RecommendationPriority.medium:
        return 'MEDIUM';
      case RecommendationPriority.low:
        return 'LOW';
    }
  }

  IconData _priorityIcon(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.critical:
        return Icons.error_rounded;
      case RecommendationPriority.high:
        return Icons.warning_amber_rounded;
      case RecommendationPriority.medium:
        return Icons.info_outline_rounded;
      case RecommendationPriority.low:
        return Icons.lightbulb_outline_rounded;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;

  const _PriorityBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EmptyPrioritiesState extends StatelessWidget {
  final String message;

  const _EmptyPrioritiesState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade50,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}