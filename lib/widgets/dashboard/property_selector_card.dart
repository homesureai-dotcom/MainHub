import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../app_card.dart';

class PropertySelectorCard extends StatelessWidget {
  final String propertyName;
  final String location;
  final VoidCallback onTap;

  const PropertySelectorCard({
    super.key,
    required this.propertyName,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HomeSureColors.primaryNavyTint,
              borderRadius: BorderRadius.circular(HomeSureRadius.md),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: HomeSureColors.primaryNavy,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE PROJECT DOSSIER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: HomeSureColors.accentTealDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  propertyName,
                  style: HomeSureTypography.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: HomeSureTypography.bodySecondary,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: HomeSureColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(HomeSureRadius.sm),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: HomeSureColors.primaryNavy,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
