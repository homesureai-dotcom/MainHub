import 'package:flutter/material.dart';

import '../../models/onboarding_page_model.dart';

class OnboardingPageWidget extends StatelessWidget {

  final OnboardingPageModel page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(30),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Text(
            page.icon,
            style: const TextStyle(
              fontSize: 110,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}