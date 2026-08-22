import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/property/property_hero_card.dart';
import '../assessment/surebot_screen.dart';


class PropertyDetailsScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  Widget buildScoreTile(
    String title,
    int score,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: .12),
            child: Text(
              "$score",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ),

          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              PropertyHeroCard(
                property: property,
              ),

              const SizedBox(height: 32),

              const Text(
                "Property DNA",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Understand what contributes to your HomeSure Score.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 24),

              buildScoreTile(
                "Legal Compliance",
                property.legalScore,
                Colors.green,
              ),

              buildScoreTile(
                "Utilities",
                property.utilityScore,
                Colors.orange,
              ),

              buildScoreTile(
                "Safety",
                property.safetyScore,
                Colors.blue,
              ),

              buildScoreTile(
                "Builder Reliability",
                property.builderScore,
                Colors.purple,
              ),

              const SizedBox(height: 28),

              AppButton(
                text: "Start Assessment",
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                 Navigator.push(
                  context,
                   MaterialPageRoute(
                   builder: (_) => const SureBotScreen(),
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