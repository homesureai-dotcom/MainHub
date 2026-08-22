import 'package:flutter/material.dart';

import '../app_card.dart';

class AIInsightsCard extends StatelessWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xff2563EB).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xff2563EB),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "HomeSure AI",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "AI Property Intelligence",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            "BUY CONFIDENCE",
            style: TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              "82%",
              style: TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              "★★★★☆",
              style: TextStyle(
                fontSize: 24,
                color: Colors.amber,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              "Strong Legal Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          _info(
            Icons.warning_amber_rounded,
            Colors.orange,
            "Biggest Risk",
            "e-Khata Pending",
          ),

          const SizedBox(height: 24),

          _info(
            Icons.lightbulb_outline,
            Colors.blue,
            "Recommended Action",
            "Apply for e-Khata",
          ),

          const SizedBox(height: 24),

          _info(
            Icons.schedule,
            Colors.green,
            "Estimated Time",
            "20 Minutes",
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text("View Full AI Analysis"),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _info(
      IconData icon,
      Color color,
      String title,
      String value,
      ) {
    return Row(
      children: [

        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: .10),
          child: Icon(icon, color: color),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}