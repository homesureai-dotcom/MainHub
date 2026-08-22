import 'package:flutter/material.dart';

import '../models/property_health_report.dart';

class ReportHeader extends StatelessWidget {
  final PropertyHealthReport report;

  const ReportHeader({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final assessment = report.assessment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Title
          Row(
            children: const [
              Icon(
                Icons.verified_user,
                color: Colors.white,
              ),

              SizedBox(width: 8),

              Text(
                "PROPERTY HEALTH REPORT",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          /// Property Name
          Text(
            report.propertyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            report.address,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 30),

          /// Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                assessment.overallScore.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: .9,
                ),
              ),

              const SizedBox(width: 16),

              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  assessment.grade,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),

            child: Row(
              children: [

                Expanded(
                  child: _InfoTile(
                    label: "Owner",
                    value: report.ownerName,
                  ),
                ),

                Expanded(
                  child: _InfoTile(
                    label: "Builder",
                    value: report.builderName,
                  ),
                ),

                Expanded(
                  child: _InfoTile(
                    label: "Assessment",
                    value:
                        "${report.assessmentDate.day}/${report.assessmentDate.month}/${report.assessmentDate.year}",
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
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}