import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../features/property/models/krera_project_models.dart';

class BuilderCard extends StatelessWidget {
  final BuilderCatalogueEntry builder;
  final VoidCallback onTap;

  const BuilderCard({
    super.key,
    required this.builder,
    required this.onTap,
  });

  String _monogram(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'B';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = builder.projectCount == 1
        ? '1 Project'
        : '${builder.projectCount} Projects';

    final localityText = builder.localities.isNotEmpty
        ? builder.localities.take(3).join(' • ')
        : 'Bengaluru';

    final sampleProjects = builder.projects
        .map((p) => p.projectName)
        .where((name) => name.trim().isNotEmpty)
        .take(2)
        .toList();
    final remainingCount = builder.projects.length - sampleProjects.length;
    final sampleText = sampleProjects.isEmpty
        ? ''
        : remainingCount > 0
            ? '${sampleProjects.join(', ')} +$remainingCount more'
            : sampleProjects.join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeSureRadius.lg),
              border: Border.all(color: HomeSureColors.borderDivider),
              boxShadow: HomeSureShadows.cardSubtle,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HomeSureColors.primaryNavy,
                    borderRadius: BorderRadius.circular(HomeSureRadius.md),
                  ),
                  child: Text(
                    _monogram(builder.builderName),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        builder.builderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeSureTypography.cardTitle,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: HomeSureColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              localityText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HomeSureTypography.caption,
                            ),
                          ),
                        ],
                      ),
                      if (sampleText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sampleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeSureTypography.caption.copyWith(
                            color: HomeSureColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HomeSureStatusBadge(
                  label: countLabel,
                  tone: HomeSureBadgeTone.teal,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: HomeSureColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
