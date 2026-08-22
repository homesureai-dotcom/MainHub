import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({
    super.key,
    required this.userName,
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
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 10),

        Text(
          userName,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}