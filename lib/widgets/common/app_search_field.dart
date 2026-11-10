import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: HomeSureTypography.bodyPrimary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: HomeSureColors.primaryNavy,
          size: 20,
        ),
        filled: true,
        fillColor: HomeSureColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(color: HomeSureColors.borderDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HomeSureRadius.md),
          borderSide: const BorderSide(
            color: HomeSureColors.primaryNavy,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
