import 'package:flutter/material.dart';

import '../../../core/theme/homesure_tokens.dart';
import '../../../theme/app_gradients.dart';
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppGradients.hero,
        border: Border.all(color: HomeSureColors.champagneBronze),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Title
          Row(
            children: const [
              Icon(
                Icons.verified_user,
                color: HomeSureColors.champagneHighlight,
              ),

              SizedBox(width: 8),

              Text(
                'PROPERTY HEALTH REPORT',
                style: TextStyle(
                  color: HomeSureColors.champagneHighlight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// Property Name
          Text(
            report.propertyName,
            style: const TextStyle(
              color: HomeSureColors.champagneInk,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            report.address,
            style: const TextStyle(
              color: HomeSureColors.slateMuted,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 26),

          /// Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                assessment.overallScore.round().toString(),
                style: const TextStyle(
                  color: HomeSureColors.champagneHighlight,
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
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
              color: HomeSureColors.midnightCard.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeSureColors.champagneBronze),
            ),

            child: Row(
              children: [

                Expanded(
                  child: _InfoTile(
                    label: 'Owner',
                    value: report.ownerName,
                  ),
                ),

                Expanded(
                  child: _InfoTile(
                    label: 'Builder',
                    value: report.builderName,
                  ),
                ),

                Expanded(
                  child: _InfoTile(
                    label: 'Assessment',
                    value:
                        '${report.assessmentDate.day}/${report.assessmentDate.month}/${report.assessmentDate.year}',
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
            color: HomeSureColors.champagneHighlight,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: HomeSureColors.champagneInk,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}