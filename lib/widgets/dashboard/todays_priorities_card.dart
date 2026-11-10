import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: HomeSureColors.statusWarningBg,
                    borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    size: 19,
                    color: HomeSureColors.statusWarningText,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Today’s Priorities',
                    style: HomeSureTypography.sectionTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.hasAssessment
                  ? 'What needs your attention'
                  : 'Complete your assessment to see priorities',
              style: HomeSureTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            if (!data.hasAssessment)
              const _EmptyPrioritiesState(
                message:
                    'Your property health assessment has not started yet.',
              )
            else if (data.priorities.isEmpty)
              const _EmptyPrioritiesState(
                message: 'No priority actions have been identified yet.',
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
                  const SizedBox(height: 12),
              ],
              if (data.priorities.length > _maxVisiblePriorities) ...[
                const SizedBox(height: 16),
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
    final priorityColor = _priorityColor(priority.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomeSureColors.surfaceElevated,
            borderRadius: BorderRadius.circular(HomeSureRadius.md),
            border: Border.all(
              color: HomeSureColors.borderDivider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                priorityIcon,
                size: 20,
                color: priorityColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority.title,
                      style: HomeSureTypography.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priority.description,
                      style: HomeSureTypography.bodySecondary,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _PriorityBadge(
                          label: priorityLabel,
                          color: priorityColor,
                        ),
                        if (priority.estimatedPHIGain > 0)
                          _PriorityBadge(
                            label: '+${priority.estimatedPHIGain} PHI',
                            color: HomeSureColors.accentTealDark,
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
                    size: 20,
                    color: HomeSureColors.textMuted,
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

  Color _priorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.critical:
        return HomeSureColors.statusCriticalText;
      case RecommendationPriority.high:
        return HomeSureColors.statusWarningText;
      case RecommendationPriority.medium:
        return HomeSureColors.primaryNavy;
      case RecommendationPriority.low:
        return HomeSureColors.accentTealDark;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeSureRadius.pill),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
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
        vertical: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        color: HomeSureColors.surfaceSubtle,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: HomeSureTypography.bodySecondary,
      ),
    );
  }
}
