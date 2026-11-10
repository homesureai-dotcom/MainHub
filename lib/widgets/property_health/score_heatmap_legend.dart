import 'package:flutter/material.dart';

/// Shared visual language for Property Health Scores.
///
/// This widget does not calculate scores. It only maps an existing score
/// to the canonical HomeSure AI health bands.
class ScoreHeatmapLegend extends StatelessWidget {
  final bool compact;
  final double? score;

  const ScoreHeatmapLegend({super.key, this.compact = false, this.score});

  static const double excellentMin = 90;
  static const double goodMin = 75;
  static const double needsAttentionMin = 60;
  static const double atRiskMin = 40;

  static String scoreLabel(double? score) {
    if (score == null) {
      return 'Not Assessed';
    }

    if (score >= excellentMin) {
      return 'Excellent';
    }

    if (score >= goodMin) {
      return 'Good';
    }

    if (score >= needsAttentionMin) {
      return 'Needs Attention';
    }

    if (score >= atRiskMin) {
      return 'At Risk';
    }

    return 'Critical';
  }

  static Color scoreColor(double? score) {
    if (score == null) {
      return Colors.grey;
    }

    if (score >= excellentMin) {
      return Colors.green;
    }

    if (score >= goodMin) {
      return Colors.teal;
    }

    if (score >= needsAttentionMin) {
      return Colors.amber;
    }

    if (score >= atRiskMin) {
      return Colors.orange;
    }

    return Colors.red;
  }

  static String scoreRange(double? score) {
    if (score == null) {
      return '—';
    }

    if (score >= excellentMin) {
      return '90–100';
    }

    if (score >= goodMin) {
      return '75–89';
    }

    if (score >= needsAttentionMin) {
      return '60–74';
    }

    if (score >= atRiskMin) {
      return '40–59';
    }

    return '0–39';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactLegend(context);
    }

    return _buildFullLegend(context);
  }

  Widget _buildCompactLegend(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          context,
          color: Colors.green,
          label: '90–100',
          compact: true,
        ),
        _buildLegendItem(
          context,
          color: Colors.teal,
          label: '75–89',
          compact: true,
        ),
        _buildLegendItem(
          context,
          color: Colors.amber,
          label: '60–74',
          compact: true,
        ),
        _buildLegendItem(
          context,
          color: Colors.orange,
          label: '40–59',
          compact: true,
        ),
        _buildLegendItem(
          context,
          color: Colors.red,
          label: '0–39',
          compact: true,
        ),
        _buildLegendItem(
          context,
          color: Colors.grey,
          label: 'Not assessed',
          compact: true,
        ),
      ],
    );
  }

  Widget _buildFullLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Health Map',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Property Health Score is interpreted using these health bands.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreRow(
            context,
            range: '90–100',
            label: 'Excellent',
            color: Colors.green,
          ),
          _buildScoreRow(
            context,
            range: '75–89',
            label: 'Good',
            color: Colors.teal,
          ),
          _buildScoreRow(
            context,
            range: '60–74',
            label: 'Needs Attention',
            color: Colors.amber,
          ),
          _buildScoreRow(
            context,
            range: '40–59',
            label: 'At Risk',
            color: Colors.orange,
          ),
          _buildScoreRow(
            context,
            range: '0–39',
            label: 'Critical',
            color: Colors.red,
          ),
          _buildScoreRow(
            context,
            range: '—',
            label: 'Not Assessed',
            color: Colors.grey,
          ),
          if (score != null) ...[
            const SizedBox(height: 12),
            _buildCurrentScore(context),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreRow(
    BuildContext context, {
    required String range,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              range,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required bool compact,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCurrentScore(BuildContext context) {
    final theme = Theme.of(context);
    final label = scoreLabel(score);
    final color = scoreColor(score);
    final range = scoreRange(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Current score: ${score!.round()} · $label',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            range,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
