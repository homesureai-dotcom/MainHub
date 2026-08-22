import 'package:flutter/material.dart';

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
      child: Row(
        children: [

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xffEEF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xff2563EB),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  propertyName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  location,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }
}