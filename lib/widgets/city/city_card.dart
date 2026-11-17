import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';
import '../../models/city.dart';

class CityCard extends StatelessWidget {
  final City city;
  final bool selected;
  final VoidCallback onTap;

  const CityCard({
    super.key,
    required this.city,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(HomeSureRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? HomeSureColors.midnightSelected
              : HomeSureColors.midnightCard,
          borderRadius: BorderRadius.circular(HomeSureRadius.lg),
          border: Border.all(
            color: selected
                ? HomeSureColors.champagneGold
                : HomeSureColors.borderSlate,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [

            CircleAvatar(
              radius: 24,
              backgroundColor: selected
                  ? HomeSureColors.midnightSand
                  : HomeSureColors.midnightInteractive,
              child: const Icon(
                Icons.location_city,
                color: HomeSureColors.champagneHighlight,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    city.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: HomeSureColors.champagneInk,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    city.state,
                    style: const TextStyle(
                      color: HomeSureColors.slateMuted,
                    ),
                  ),
                ],
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: HomeSureColors.champagneGold,
              ),
          ],
        ),
      ),
    );
  }
}