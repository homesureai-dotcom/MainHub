import 'package:flutter/material.dart';

import '../../core/theme/homesure_tokens.dart';

class AddEvidenceButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddEvidenceButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.add_a_photo_outlined,
          size: 20,
        ),
        label: const Text(
          'Add Evidence',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: HomeSureColors.midnightInteractive,
          foregroundColor: HomeSureColors.champagneHighlight,
          side: const BorderSide(
            color: HomeSureColors.champagneBronze,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}