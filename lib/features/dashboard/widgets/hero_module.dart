import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            propertyName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "PROPERTY HEALTH INDEX™",
            style: TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "$phi",
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Divider(),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  title: "Potential PHI",
                  value: "$potentialPhi",
                  subtitle: "+${potentialPhi - phi} Available",
                ),
              ),

              Expanded(
                child: _InfoColumn(
                  title: "Last Assessment",
                  value: assessmentDate,
                  subtitle: "",
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
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}