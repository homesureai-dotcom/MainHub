import 'package:flutter/material.dart';

import '../../../core/theme/homesure_tokens.dart';
import '../../../theme/app_gradients.dart';
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
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeSureColors.champagneBronze),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_work_rounded,
            size: 54,
            color: HomeSureColors.champagneHighlight,
          ),

          const SizedBox(height: 18),

          const Text(
            'HomeSure AI',
            style: TextStyle(
              color: HomeSureColors.champagneHighlight,
              fontSize: 18,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'PROPERTY HEALTH REPORT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomeSureColors.champagneInk,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            report.propertyName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeSureColors.champagneInk,
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${report.city}, ${report.state}',
            style: const TextStyle(
              color: HomeSureColors.slateMuted,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 22,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: HomeSureColors.midnightCard.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeSureColors.champagneBronze),
            ),
            child: Column(
              children: [
                const Text(
                  'OVERALL PROPERTY HEALTH SCORE',
                  style: TextStyle(
                    color: HomeSureColors.champagneHighlight,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  '$score',
                  style: const TextStyle(
                    color: HomeSureColors.champagneHighlight,
                    fontSize: 68,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  grade.toUpperCase(),
                  style: const TextStyle(
                    color: HomeSureColors.champagneInk,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
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
              color: HomeSureColors.midnightCard.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeSureColors.borderSlate),
            ),
            child: Column(
              children: [
                const Text(
                  'Generated On',
                  style: TextStyle(
                    color: HomeSureColors.champagneHighlight,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  generatedDate,
                  style: const TextStyle(
                    color: HomeSureColors.champagneInk,
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
        color: HomeSureColors.midnightCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeSureColors.borderSlate),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: HomeSureColors.champagneHighlight,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeSureColors.champagneInk,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}