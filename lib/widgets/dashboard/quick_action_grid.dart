import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import 'quick_action_card.dart';

class QuickActionGrid extends StatelessWidget {
  final VoidCallback? onAiAdvisor;
  final VoidCallback? onDocuments;
  final VoidCallback? onCompliance;
  final VoidCallback? onTimeline;

  const QuickActionGrid({
    super.key,
    this.onAiAdvisor,
    this.onDocuments,
    this.onCompliance,
    this.onTimeline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: HomeSureTypography.sectionTitle,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            QuickActionCard(
              icon: Icons.psychology_alt_rounded,
              color: HomeSureColors.primaryNavy,
              title: 'AI Advisor',
              subtitle: 'Smart property insights',
              onTap: onAiAdvisor ?? () {},
            ),
            QuickActionCard(
              icon: Icons.description_outlined,
              color: HomeSureColors.accentTealDark,
              title: 'Documents',
              subtitle: 'View property records',
              onTap: onDocuments ?? () {},
            ),
            QuickActionCard(
              icon: Icons.verified_user_outlined,
              color: HomeSureColors.statusPositiveText,
              title: 'Compliance',
              subtitle: 'Legal & approvals',
              onTap: onCompliance ?? () {},
            ),
            QuickActionCard(
              icon: Icons.timeline_rounded,
              color: HomeSureColors.statusWarningText,
              title: 'Timeline',
              subtitle: 'Project journey',
              onTap: onTimeline ?? () {},
            ),
          ],
        ),
      ],
    );
  }
}
