import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  final String apartmentName;

  const GreetingHeader({
    super.key,
    required this.apartmentName,
  });

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    }

    if (hour < 17) {
      return "Good Afternoon";
    }

    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "${getGreeting()} 👋",
          style: AppTextStyles.heading,
        ),

        const SizedBox(height: 6),

        const Text(
          "Welcome back",
          style: AppTextStyles.caption,
        ),

        const SizedBox(height: 18),

        Text(
          apartmentName,
          style: AppTextStyles.display,
        ),
      ],
    );
  }
}