import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';
import '../../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  HomeSureBadgeTone _statusTone(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized.contains('APPROVED') || normalized.contains('ACTIVE')) {
      return HomeSureBadgeTone.positive;
    }
    if (normalized.contains('REVOKED') ||
        normalized.contains('EXPIRED') ||
        normalized.contains('REJECTED')) {
      return HomeSureBadgeTone.critical;
    }
    return HomeSureBadgeTone.warning;
  }

  @override
  Widget build(BuildContext context) {
    final statusText = property.regulatoryStatus.trim().isNotEmpty
        ? property.regulatoryStatus.trim()
        : 'K-RERA Registered';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(HomeSureRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeSureRadius.lg),
              border: Border.all(color: HomeSureColors.borderDivider),
              boxShadow: HomeSureShadows.cardSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: HomeSureColors.primaryNavyTint,
                        borderRadius: BorderRadius.circular(HomeSureRadius.md),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        size: 22,
                        color: HomeSureColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: HomeSureTypography.cardTitle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            property.builder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeSureTypography.bodySecondary.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HomeSureStatusBadge(
                      label: statusText,
                      tone: _statusTone(statusText),
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (property.locality.isNotEmpty)
                      _MetaChip(
                        icon: Icons.location_on_outlined,
                        label: property.locality,
                      ),
                    if (property.projectType.isNotEmpty)
                      _MetaChip(
                        icon: Icons.layers_outlined,
                        label: property.projectType,
                      ),
                  ],
                ),
                if (property.reraNumber.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: HomeSureColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                      border: Border.all(color: HomeSureColors.borderDivider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: HomeSureColors.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'RERA: ${property.reraNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HomeSureColors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: HomeSureStatusBadge(
                        label: 'Not yet assessed by HomeSureAI',
                        tone: HomeSureBadgeTone.warning,
                        icon: Icons.pending_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Inspect Dossier',
                          style: HomeSureTypography.caption.copyWith(
                            color: HomeSureColors.primaryNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: HomeSureColors.primaryNavy,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(HomeSureRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: HomeSureColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeSureTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
