import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: HomeSureTypography.bodyPrimary,
      cursorColor: HomeSureColors.champagneHighlight,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: HomeSureColors.slatePlaceholder,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: HomeSureColors.champagneHighlight,
          size: 20,
        ),
        filled: true,
        fillColor: HomeSureColors.midnightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HomeSureColors.borderSlate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HomeSureColors.borderSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: HomeSureColors.champagneGold,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
