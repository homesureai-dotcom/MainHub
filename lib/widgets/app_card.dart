import 'package:flutter/material.dart';

import '../core/theme/homesure_tokens.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: HomeSureColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: HomeSureColors.borderDivider),
        boxShadow: HomeSureShadows.cardSubtle,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(HomeSureSpacing.md),
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
