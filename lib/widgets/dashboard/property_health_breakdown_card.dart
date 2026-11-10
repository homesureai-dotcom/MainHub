import 'package:flutter/material.dart';

import '../../core/engine/models/property_health_result.dart';
import '../../core/phs/phs_categories.dart';
import '../../core/theme/homesure_tokens.dart';
import '../property_health/score_heatmap_legend.dart';

class PropertyHealthBreakdownCard extends StatelessWidget {
  const PropertyHealthBreakdownCard({
    super.key,
    required this.result,
    this.onCategoryTap,
  });

  final PropertyHealthResult result;
  final ValueChanged<PHSCategory>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Property Health Breakdown',
                        style: HomeSureTypography.sectionTitle,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Health across your six property pillars',
                        style: HomeSureTypography.bodySecondary,
                      ),
                    ],
                  ),
                ),
                if (result.hasFinalScore)
                  Text(
                    '${result.overallScore.round()}/100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ScoreHeatmapLegend.scoreColor(
                        result.overallScore,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...PHSCategory.values.map(
              (category) => _buildCategoryRow(
                context,
                category,
                result.categoryScores[category],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    PHSCategory category,
    double? score,
  ) {
    final isAssessed = score != null;
    final status = ScoreHeatmapLegend.scoreLabel(score);
    final statusColor = ScoreHeatmapLegend.scoreColor(score);
    final range = ScoreHeatmapLegend.scoreRange(score);

    return InkWell(
      onTap: onCategoryTap == null ? null : () => onCategoryTap!(category),
      borderRadius: BorderRadius.circular(HomeSureRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeSureColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(HomeSureRadius.sm),
              ),
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.displayName,
                          style: HomeSureTypography.bodyMedium,
                        ),
                      ),
                      Text(
                        isAssessed ? '${score.round()}' : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAssessed ? '$status • $range' : 'Not Assessed',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${category.weight.round()}% weight',
                        style: HomeSureTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isAssessed ? score / 100 : 0,
                      minHeight: 5,
                      backgroundColor: HomeSureColors.surfaceSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
            ),
            if (onCategoryTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: HomeSureColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
