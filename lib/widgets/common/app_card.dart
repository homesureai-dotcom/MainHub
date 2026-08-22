import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppCardType {
  normal,
  elevated,
  outlined,
}

class AppCard extends StatelessWidget {
  final Widget child;

  final EdgeInsetsGeometry? padding;

  final VoidCallback? onTap;

  final AppCardType type;

  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.type = AppCardType.normal,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    BoxBorder? border;
    List<BoxShadow>? shadows;

    switch (type) {
      case AppCardType.normal:
        shadows = AppShadows.small;
        break;

      case AppCardType.elevated:
        shadows = AppShadows.large;
        break;

      case AppCardType.outlined:
        border = Border.all(
          color: Colors.grey.shade300,
        );
        shadows = [];
        break;
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding ??
          const EdgeInsets.all(
            AppSpacing.lg,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(
        AppRadius.xl,
      ),
      onTap: onTap,
      child: card,
    );
  }
}