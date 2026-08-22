import 'package:flutter/material.dart';

import '../models/property_health_report.dart';

class ReportCoverCard extends StatelessWidget {
  final PropertyHealthReport report;

  const ReportCoverCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final score = report.assessment.overallScore.round();

    final grade = report.assessment.grade;

    final generatedDate =
        "${report.assessmentDate.day}/${report.assessmentDate.month}/${report.assessmentDate.year}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_work_rounded,
            size: 56,
            color: Colors.white,
          ),

          const SizedBox(height: 20),

          const Text(
            "HomeSure AI",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "PROPERTY HEALTH REPORT",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            report.propertyName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${report.city}, ${report.state}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 22,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  "OVERALL PROPERTY HEALTH SCORE",
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "$score",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  grade.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  title: "Owner",
                  value: report.ownerName,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _InfoTile(
                  title: "Builder",
                  value: report.builderName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  "Generated On",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  generatedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}