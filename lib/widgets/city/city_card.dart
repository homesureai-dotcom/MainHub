import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [

            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEEF4FF),
              child: Icon(
                Icons.location_city,
                color: Color(0xFF2563EB),
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
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    city.state,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2563EB),
              ),
          ],
        ),
      ),
    );
  }
}