import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_section_header.dart';
import '../models/property_health_report.dart';

class PropertyDetailsCard extends StatelessWidget {
  final PropertyHealthReport report;

  const PropertyDetailsCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: AppCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Property Details",
            subtitle: "Basic information about the assessed property.",
          ),

          _DetailTile(
            icon: Icons.apartment_rounded,
            label: "Project",
            value: report.propertyName,
          ),

          _DetailTile(
            icon: Icons.business_rounded,
            label: "Builder",
            value: report.builderName,
          ),

          _DetailTile(
            icon: Icons.person_rounded,
            label: "Owner",
            value: report.ownerName,
          ),

          _DetailTile(
            icon: Icons.location_on_rounded,
            label: "Address",
            value: report.address,
          ),

          _DetailTile(
            icon: Icons.location_city_rounded,
            label: "City",
            value: report.city,
          ),

          _DetailTile(
            icon: Icons.map_rounded,
            label: "State",
            value: report.state,
          ),

          _DetailTile(
            icon: Icons.pin_drop_rounded,
            label: "Pincode",
            value: report.pincode,
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: AppTextStyles.title,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}