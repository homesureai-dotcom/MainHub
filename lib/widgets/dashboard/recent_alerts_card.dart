import 'package:flutter/material.dart';

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

              const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xff2563EB),
              ),

              const SizedBox(width: 10),

              Text(
                "Recent Alerts",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildAlert(
            color: Colors.orange,
            icon: Icons.warning_amber_rounded,
            title: "e-Khata Pending",
            subtitle: "Applications are under BBMP review.",
          ),

          const Divider(height: 32),

          _buildAlert(
            color: Colors.red,
            icon: Icons.error_outline_rounded,
            title: "STP Issue",
            subtitle: "Operational issue reported by residents.",
          ),

          const Divider(height: 32),

          _buildAlert(
            color: Colors.green,
            icon: Icons.verified_rounded,
            title: "Fire NOC Verified",
            subtitle: "Fire Department approval received.",
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }
}