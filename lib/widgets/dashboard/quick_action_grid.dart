import 'package:flutter/material.dart';

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
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 0.85,
          children: [
            QuickActionCard(
              icon: Icons.psychology_alt_rounded,
              color: Colors.deepPurple,
              title: 'AI Advisor',
              subtitle: 'Smart property insights',
              onTap: onAiAdvisor ?? () {},
            ),
            QuickActionCard(
              icon: Icons.description_outlined,
              color: Colors.blue,
              title: 'Documents',
              subtitle: 'View property records',
              onTap: onDocuments ?? () {},
            ),
            QuickActionCard(
              icon: Icons.verified_user_outlined,
              color: Colors.green,
              title: 'Compliance',
              subtitle: 'Legal & approvals',
              onTap: onCompliance ?? () {},
            ),
            QuickActionCard(
              icon: Icons.timeline_rounded,
              color: Colors.orange,
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