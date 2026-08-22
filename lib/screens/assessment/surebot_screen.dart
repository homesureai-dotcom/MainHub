import 'package:flutter/material.dart';

import '../../widgets/assessment/surebot_avatar.dart';
import '../../widgets/common/app_button.dart';
import 'assessment_screen.dart';

class SureBotScreen extends StatelessWidget {
  const SureBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [

              const Spacer(),

              const SureBotAvatar(),

              const SizedBox(height: 36),

              const Text(
                "Hi Vinod 👋",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "I'm SureBot",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "I'll guide you through a quick Property Health Assessment.\n\nThis takes less than 3 minutes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              AppButton(
                text: "Let's Begin",
                icon: Icons.arrow_forward,

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssessmentScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}