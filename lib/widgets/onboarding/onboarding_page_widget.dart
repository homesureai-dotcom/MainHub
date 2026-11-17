import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
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

          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeSureColors.midnightCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: HomeSureColors.champagneBronze,
                width: 1.5,
              ),
              boxShadow: HomeSureShadows.cardElevated,
            ),
            child: Text(
              page.icon,
              style: const TextStyle(
                fontSize: 64,
              ),
            ),
          ),

          const SizedBox(height: 36),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: HomeSureColors.champagneInk,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.5,
              color: HomeSureColors.slateMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}