import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../app_card.dart';

class RecentAlertsCard extends StatelessWidget {
  const RecentAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HomeSureColors.primaryNavyTint,
                  borderRadius: BorderRadius.circular(HomeSureRadius.sm),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: HomeSureColors.primaryNavy,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recent Alerts',
                style: HomeSureTypography.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAlert(
            color: HomeSureColors.statusWarningText,
            icon: Icons.warning_amber_rounded,
            title: 'e-Khata Pending',
            subtitle: 'Applications are under BBMP review.',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildAlert(
            color: HomeSureColors.statusCriticalText,
            icon: Icons.error_outline_rounded,
            title: 'STP Issue',
            subtitle: 'Operational issue reported by residents.',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildAlert(
            color: HomeSureColors.statusPositiveText,
            icon: Icons.verified_rounded,
            title: 'Fire NOC Verified',
            subtitle: 'Fire Department approval received.',
          ),
        ],
      ),
    );
  }

  Widget _buildAlert({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(HomeSureRadius.sm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: HomeSureTypography.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: HomeSureTypography.bodySecondary,
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: HomeSureColors.textMuted,
          size: 20,
        ),
      ],
    );
  }
}
