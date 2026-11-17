import 'package:flutter/material.dart';

import '../../../core/theme/homesure_tokens.dart';

class HeroModule extends StatelessWidget {
  final String propertyName;
  final int phi;
  final int potentialPhi;
  final String status;
  final String assessmentDate;

  const HeroModule({
    super.key,
    required this.propertyName,
    required this.phi,
    required this.potentialPhi,
    required this.status,
    required this.assessmentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HomeSureColors.midnightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeSureColors.borderSlate),
        boxShadow: HomeSureShadows.cardElevated,
      ),
      child: Column(
        children: [
          Text(
            propertyName,
            style: const TextStyle(
              fontSize: 18,
              color: HomeSureColors.slateMuted,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'PROPERTY HEALTH INDEX™',
            style: TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: HomeSureColors.champagneHighlight,
              fontSize: 12.5,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '$phi',
            style: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.w800,
              height: 1,
              color: HomeSureColors.champagneInk,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: HomeSureColors.statusPositiveBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: HomeSureColors.statusPositiveBorder),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: HomeSureColors.statusPositiveText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  title: 'Potential PHI',
                  value: '$potentialPhi',
                  subtitle: '+${potentialPhi - phi} Available',
                ),
              ),

              Expanded(
                child: _InfoColumn(
                  title: 'Last Assessment',
                  value: assessmentDate,
                  subtitle: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InfoColumn({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: HomeSureColors.slateMuted,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: HomeSureColors.champagneInk,
          ),
        ),

        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: HomeSureColors.statusPositiveText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}