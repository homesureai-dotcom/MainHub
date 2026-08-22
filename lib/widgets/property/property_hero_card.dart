import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../theme/app_gradients.dart';

class PropertyHeroCard extends StatelessWidget {
  final Property property;

  const PropertyHeroCard({
    super.key,
    required this.property,
  });

  Color get scoreColor {
    if (property.overallScore >= 85) {
      return Colors.greenAccent;
    }

    if (property.overallScore >= 70) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  String get scoreLabel {
    if (property.overallScore >= 85) {
      return "Excellent";
    }

    if (property.overallScore >= 70) {
      return "Good";
    }

    return "Needs Attention";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      property.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${property.builder} • ${property.city}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              if (property.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Icon(
                        Icons.verified,
                        size: 18,
                        color: Colors.white,
                      ),

                      SizedBox(width: 6),

                      Text(
                        "Verified",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 36),

          const Text(
            "HomeSure Score",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                "${property.overallScore}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),

              const SizedBox(width: 16),

              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  scoreLabel,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Divider(
            color: Colors.white24,
          ),

          const SizedBox(height: 18),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _HeroStat(
                title: "Status",
                value: "Active",
              ),

              _HeroStat(
                title: "Updated",
                value: "Today",
              ),

              _HeroStat(
                title: "Health",
                value: "Good",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String title;
  final String value;

  const _HeroStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}