import 'package:flutter/material.dart';

import '../../models/property_health/property_risk.dart';

class PropertyRiskCard extends StatelessWidget {
  final PropertyRisk risk;

  const PropertyRiskCard({
    super.key,
    required this.risk,
  });

  Color _severityColor() {
    switch (risk.severity) {
      case RiskSeverity.critical:
        return Colors.red.shade700;
      case RiskSeverity.high:
        return Colors.orange.shade700;
      case RiskSeverity.medium:
        return Colors.amber.shade700;
      case RiskSeverity.low:
        return Colors.blue.shade700;
    }
  }

  String _severityLabel() {
    switch (risk.severity) {
      case RiskSeverity.critical:
        return "Critical Risk";
      case RiskSeverity.high:
        return "High Risk";
      case RiskSeverity.medium:
        return "Medium Risk";
      case RiskSeverity.low:
        return "Low Risk";
    }
  }

  IconData _severityIcon() {
    switch (risk.severity) {
      case RiskSeverity.critical:
        return Icons.dangerous_rounded;
      case RiskSeverity.high:
        return Icons.warning_rounded;
      case RiskSeverity.medium:
        return Icons.error_outline_rounded;
      case RiskSeverity.low:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: severityColor.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _severityIcon(),
                    color: severityColor,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _severityLabel(),
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        risk.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              risk.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.category_outlined,
                    label: risk.category,
                  ),
                ),

                const SizedBox(width: 12),

                _ImpactBadge(
                  phiImpact: risk.phiImpact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  final int phiImpact;

  const _ImpactBadge({
    required this.phiImpact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "PHI -$phiImpact",
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}