import 'package:flutter/material.dart';

import '../../features/property/models/krera_project_models.dart';
import 'homesure_tokens.dart';

enum HomeSureBadgeTone {
  navy,
  teal,
  positive,
  warning,
  critical,
  neutral,
}

class HomeSureStatusBadge extends StatelessWidget {
  final String label;
  final HomeSureBadgeTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const HomeSureStatusBadge({
    super.key,
    required this.label,
    this.tone = HomeSureBadgeTone.neutral,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, Color border) = switch (tone) {
      HomeSureBadgeTone.navy => (
        HomeSureColors.primaryNavy,
        HomeSureColors.primaryNavyTint,
        HomeSureColors.borderStrong,
      ),
      HomeSureBadgeTone.teal => (
        HomeSureColors.accentTealDark,
        HomeSureColors.accentTealTint,
        HomeSureColors.accentTealBorder,
      ),
      HomeSureBadgeTone.positive => (
        HomeSureColors.statusPositiveText,
        HomeSureColors.statusPositiveBg,
        HomeSureColors.statusPositiveBorder,
      ),
      HomeSureBadgeTone.warning => (
        HomeSureColors.statusWarningText,
        HomeSureColors.statusWarningBg,
        HomeSureColors.statusWarningBorder,
      ),
      HomeSureBadgeTone.critical => (
        HomeSureColors.statusCriticalText,
        HomeSureColors.statusCriticalBg,
        HomeSureColors.statusCriticalBorder,
      ),
      HomeSureBadgeTone.neutral => (
        HomeSureColors.statusNeutralText,
        HomeSureColors.statusNeutralBg,
        HomeSureColors.statusNeutralBorder,
      ),
    };

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HomeSureRadius.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeSureTypography.badge.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSureObservationBadge extends StatelessWidget {
  final ObservationState state;
  final bool showIcon;

  const HomeSureObservationBadge({
    super.key,
    required this.state,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final visual = ObservationStateVisual.of(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(HomeSureRadius.pill),
        border: Border.all(color: visual.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(visual.icon, size: 12.5, color: visual.textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              visual.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeSureTypography.badge.copyWith(
                color: visual.textColor,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSureSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const HomeSureSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: HomeSureTypography.sectionTitle),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: HomeSureTypography.bodySecondary),
        ],
      ],
    );
  }
}

class HomeSureMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final IconData? icon;
  final Color? accentColor;

  const HomeSureMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.sublabel,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accentColor ?? HomeSureColors.primaryNavy;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(HomeSureRadius.md),
        border: Border.all(color: HomeSureColors.borderDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeSureTypography.caption.copyWith(
                    color: HomeSureColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tint,
              height: 1.15,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 3),
            Text(
              sublabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeSureTypography.caption.copyWith(
                fontSize: 10.5,
                color: HomeSureColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
