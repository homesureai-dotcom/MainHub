import 'package:flutter/material.dart';

import '../../features/dashboard/models/dashboard_data.dart';
import '../app_card.dart';

class AIInsightsCard extends StatelessWidget {
  final DashboardData data;

  const AIInsightsCard({
    super.key,
    required this.data,
  });

  String get _scoreLabel {
    final score = data.healthScore;

    if (score == null) {
      return "Not Assessed";
    }

    return "${score.round()}%";
  }

  String get _profileLabel {
    final grade = data.healthGrade;

    if (grade == null) {
      return "Complete your assessment";
    }

    return grade;
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = data.healthScore != null;

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
                  color: const Color(0xff2563EB)
                      .withValues(alpha: .10),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xff2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
            "PROPERTY INTELLIGENCE",
            style: TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _scoreLabel,
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              hasScore ? _starRating(data.healthScore!) : "☆☆☆☆☆",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _profileLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hasScore
                    ? _statusColor(data.healthScore!)
                    : Colors.grey,
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
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                "View Full AI Analysis",
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _starRating(double score) {
    final filledStars =
        (score / 20).round().clamp(0, 5);

    return List.generate(
      5,
      (index) =>
          index < filledStars ? "★" : "☆",
    ).join();
  }

  static Color _statusColor(double score) {
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return Colors.green;
    }

    if (score >= 60) {
      return Colors.orange;
    }

    return Colors.red;
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
          backgroundColor:
              color.withValues(alpha: .10),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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