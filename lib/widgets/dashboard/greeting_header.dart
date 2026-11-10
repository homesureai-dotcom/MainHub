import 'package:flutter/material.dart';

import '../../core/theme/homesure_components.dart';
import '../../core/theme/homesure_tokens.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({
    super.key,
    required this.userName,
  });

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${getGreeting()} 👋',
                style: HomeSureTypography.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeSureColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: HomeSureTypography.screenTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const HomeSureStatusBadge(
          label: 'Bengaluru K-RERA',
          tone: HomeSureBadgeTone.teal,
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}
