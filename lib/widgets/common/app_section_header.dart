import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3,
                ),
                if (subtitle != null) ...[
                  const SizedBox(
                    height: AppSpacing.xs,
                  ),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          if (trailing != null) ...[
            trailing!,
          ],
        ],
      ),
    );
  }
}